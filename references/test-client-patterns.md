# Test and Client Patterns

## Table of Contents
- [Canonical End-to-End Test Flow](#canonical-end-to-end-test-flow)
- [MXE Public Key Retry Pattern](#mxe-public-key-retry-pattern)
- [Comp-Def Idempotent Initialization](#comp-def-idempotent-initialization)
- [LUT Lookup Pattern](#lut-lookup-pattern)
- [Encryption/Decryption Roundtrip Contract](#encryptiondecryption-roundtrip-contract)
- [Callback Event Awaiting Pattern](#callback-event-awaiting-pattern)
- [Finalization Wait Contract](#finalization-wait-contract)
- [Minimal Regression Assertions](#minimal-regression-assertions)

## Canonical End-to-End Test Flow

1. Setup provider and program.
2. Resolve Arcium environment (`getArciumEnv`) and cluster account.
3. Initialize all required comp-defs idempotently.
4. Fetch MXE public key with retry.
5. Encrypt inputs with `x25519` + `RescueCipher`.
6. Queue program instruction with PDA addresses derived from same cluster offset.
7. Await callback event and finalization.
8. Decrypt outputs (if receiver-targeted encrypted outputs).
9. Assert functional result and state transition.

## MXE Public Key Retry Pattern

Use retry logic because MXE account availability can be eventually consistent in test environments.

Pattern:
1. call `getMXEPublicKey(...)`,
2. retry on transient failures with bounded attempts/backoff,
3. fail fast with actionable error after max retries.

Required logs:
- attempt count,
- last error,
- program id / cluster context.

## Comp-Def Idempotent Initialization

Pattern used in `encrypted_dna_matching` tests:

1. derive comp-def PDA from `getCompDefAccOffset("<ix_name>")`.
2. call `getAccountInfo`.
3. if exists: return sentinel (`already_initialized`).
4. else call `init_<ix>_comp_def`.

Benefit:
- test reruns do not fail on already-created comp-defs.

## LUT Lookup Pattern

For modern comp-def init contexts:
1. fetch MXE account (`arciumProgram.account.mxeAccount.fetch`).
2. derive LUT address with `getLookupTableAddress(programId, mxeAcc.lutOffsetSlot)`.
3. pass `addressLookupTable` in comp-def init accounts.

Do not hardcode LUT addresses.

## Encryption/Decryption Roundtrip Contract

Input encryption contract:
1. generate sender x25519 secret/public pair,
2. derive shared secret with MXE public key,
3. encrypt plaintext vector with `RescueCipher` and random 16-byte nonce,
4. serialize nonce into BN using `deserializeLE`.

Output decryption contract:
1. derive shared secret with receiver secret key and MXE public key,
2. decrypt callback ciphertexts using output nonce,
3. assert expected semantics (not only byte equality).

Nonce discipline:
- never reuse nonce with same key pair for distinct plaintext payloads.

## Callback Event Awaiting Pattern

Pattern:
1. register listener before queue tx,
2. hold `Promise` for target event,
3. queue tx,
4. await event,
5. remove listener.

Reason:
- avoids missing early callback events and nondeterministic test behavior.

## Finalization Wait Contract

Always wait for chain-level finalization after queueing:

```ts
await awaitComputationFinalization(provider, computationOffset, program.programId, "confirmed")
```

Rules:
1. Use exact same `computationOffset` passed into queue instruction.
2. Use the same program id and commitment level across queue/wait.
3. Log queue and finalize signatures for diagnostics.

## Minimal Regression Assertions

At minimum, assert:
1. callback handler updated expected state fields.
2. callback status transition happened (if state machine exists).
3. decrypted result matches expected deterministic computation.
4. permission rules were enforced (negative test path recommended).
