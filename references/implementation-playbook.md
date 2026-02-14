# Arcium Implementation Playbook

## Core File Map

- Arcis circuits: `encrypted-ixs/src/lib.rs`
- Solana program: `programs/<program_name>/src/lib.rs`
- Program tests (TypeScript): `tests/*.ts`
- Optional frontend/client: `frontend/**` or app-specific client code

## Golden Flow for a New Computation

1. Add Arcis instruction in `encrypted-ixs/src/lib.rs`.
- Define input/output structs with supported Arcis types.
- Mark entrypoint with `#[instruction]`.
- Use `.to_arcis()` for encrypted inputs, `.from_arcis()` or `.reveal()` for outputs.

2. Add computation offset constant in program:
```rust
const COMP_DEF_OFFSET_MY_IX: u32 = comp_def_offset("my_ix");
```

3. Add comp-def initialization instruction:
```rust
pub fn init_my_ix_comp_def(ctx: Context<InitMyIxCompDef>) -> Result<()> {
    init_comp_def(ctx.accounts, None, None)?;
    Ok(())
}
```

4. Queue computation in program instruction.
- Build ordered args via `ArgBuilder`.
- Set `sign_pda_account.bump`.
- Call `queue_computation(...)` and pass callback instruction via `MyIxCallback::callback_ix(...)`.

5. Verify and consume callback output.
- Use `SignedComputationOutputs<MyIxOutput>`.
- Call `verify_output(...)`.
- Persist ciphertext/nonce or emit event.

## ArgBuilder Mapping

| Circuit Input | Program-side ArgBuilder pattern |
| --- | --- |
| `Enc<Shared, T>` | `x25519_pubkey(pubkey)` + `plaintext_u128(nonce)` + encrypted fields |
| `Enc<Mxe, T>` | `plaintext_u128(nonce)` + encrypted fields |
| state in account | `.account(account_pubkey, byte_offset, byte_len)` |
| plaintext scalar | `.plaintext_u8/u16/u32/u64/u128/bool(...)` |

## Offset Checklist for `.account(...)`

1. Start from Anchor account discriminator offset (`8` bytes).
2. Add fixed-size fields before encrypted payload.
3. Keep exact ciphertext sizes (`[u8; 32]` per encrypted scalar field element).
4. Comment how offset and length were derived.

## Callback Pattern

```rust
#[arcium_callback(encrypted_ix = "my_ix")]
pub fn my_ix_callback(
    ctx: Context<MyIxCallback>,
    output: SignedComputationOutputs<MyIxOutput>,
) -> Result<()> {
    let o = match output.verify_output(
        &ctx.accounts.cluster_account,
        &ctx.accounts.computation_account,
    ) {
        Ok(MyIxOutput { field_0 }) => field_0,
        Err(_) => return Err(ErrorCode::AbortedComputation.into()),
    };

    // persist o.ciphertexts / o.nonce or emit event
    Ok(())
}
```

## Test Pattern

1. Fetch MXE public key.
2. Create ephemeral x25519 keypair.
3. Derive shared secret and encrypt with `RescueCipher`.
4. Queue program instruction with PDAs from `@arcium-hq/client`.
5. Call `awaitComputationFinalization(...)`.
6. Validate callback event/state and decrypt outputs if needed.

## Validation Commands

```bash
arcium build
cargo check --all
arcium test
```
