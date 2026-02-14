import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { PublicKey } from "@solana/web3.js";
import { randomBytes } from "crypto";
import {
  awaitComputationFinalization,
  deserializeLE,
  getArciumAccountBaseSeed,
  getArciumEnv,
  getArciumProgram,
  getArciumProgramId,
  getClusterAccAddress,
  getCompDefAccOffset,
  getComputationAccAddress,
  getExecutingPoolAccAddress,
  getLookupTableAddress,
  getMempoolAccAddress,
  getMXEAccAddress,
  getMXEPublicKey,
  RescueCipher,
  x25519,
} from "@arcium-hq/client";
import { <PROGRAM_IDL_TYPE> } from "../target/types/<PROGRAM_FILE_STEM>";

describe("<PROGRAM_SUITE_NAME>", () => {
  anchor.setProvider(anchor.AnchorProvider.env());
  const provider = anchor.getProvider() as anchor.AnchorProvider;
  const program = anchor.workspace.<PROGRAM_WORKSPACE_NAME> as Program<<PROGRAM_IDL_TYPE>>;

  it("queues <IX_NAME> and validates callback result", async () => {
    const payer = (provider.wallet as anchor.Wallet).payer;

    const arciumEnv = getArciumEnv();
    const clusterAccount = getClusterAccAddress(arciumEnv.arciumClusterOffset);

    await initCompDefIfNeeded(program, payer);

    const mxePublicKey = await getMXEPublicKeyWithRetry(provider, program.programId);

    // Build encrypted payload
    const senderSecret = x25519.utils.randomSecretKey();
    const senderPublic = x25519.getPublicKey(senderSecret);
    const sharedSecret = x25519.getSharedSecret(senderSecret, mxePublicKey);
    const cipher = new RescueCipher(sharedSecret);
    const nonce = randomBytes(16);

    const plaintext = [BigInt(<PLAINTEXT_EXAMPLE>)];
    const encrypted = cipher.encrypt(plaintext, nonce);

    const computationOffset = new anchor.BN(randomBytes(8), "le");

    const queueSig = await program.methods
      .<QUEUE_METHOD_NAME>(
        computationOffset,
        Array.from(senderPublic),
        new anchor.BN(deserializeLE(nonce).toString()),
        Array.from(encrypted[0]),
        new anchor.BN(<STATE_NONCE_EXAMPLE>)
      )
      .accountsPartial({
        payer: payer.publicKey,
        mxeAccount: getMXEAccAddress(program.programId),
        mempoolAccount: getMempoolAccAddress(arciumEnv.arciumClusterOffset),
        executingPool: getExecutingPoolAccAddress(arciumEnv.arciumClusterOffset),
        computationAccount: getComputationAccAddress(
          arciumEnv.arciumClusterOffset,
          computationOffset
        ),
        clusterAccount,
      })
      .signers([payer])
      .rpc({ commitment: "confirmed", preflightCommitment: "confirmed" });

    const finalizeSig = await awaitComputationFinalization(
      provider,
      computationOffset,
      program.programId,
      "confirmed"
    );

    console.log("queue:", queueSig);
    console.log("finalize:", finalizeSig);

    // TODO: fetch updated account/event and assert decrypted or expected output semantics.
  });
});

async function initCompDefIfNeeded(
  program: Program<<PROGRAM_IDL_TYPE>>,
  payer: anchor.web3.Keypair
): Promise<void> {
  const baseSeed = getArciumAccountBaseSeed("ComputationDefinitionAccount");
  const offset = getCompDefAccOffset("<IX_NAME>");

  const compDefPda = PublicKey.findProgramAddressSync(
    [baseSeed, program.programId.toBuffer(), offset],
    getArciumProgramId()
  )[0];

  const existing = await program.provider.connection.getAccountInfo(compDefPda);
  if (existing) {
    return;
  }

  const arciumProgram = getArciumProgram(program.provider as anchor.AnchorProvider);
  const mxeAccount = getMXEAccAddress(program.programId);
  const mxe = await arciumProgram.account.mxeAccount.fetch(mxeAccount);
  const lutAddress = getLookupTableAddress(program.programId, mxe.lutOffsetSlot);

  await program.methods
    .<INIT_COMP_DEF_METHOD_NAME>()
    .accounts({
      payer: payer.publicKey,
      compDefAccount: compDefPda,
      mxeAccount,
      addressLookupTable: lutAddress,
    })
    .signers([payer])
    .rpc({ commitment: "confirmed", preflightCommitment: "confirmed" });
}

async function getMXEPublicKeyWithRetry(
  provider: anchor.AnchorProvider,
  programId: PublicKey,
  retries = 10,
  delayMs = 1500
): Promise<Uint8Array> {
  let lastErr: unknown;
  for (let attempt = 1; attempt <= retries; attempt += 1) {
    try {
      return await getMXEPublicKey(provider, programId);
    } catch (err) {
      lastErr = err;
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
  }

  throw new Error(`unable to fetch MXE public key after retries: ${String(lastErr)}`);
}
