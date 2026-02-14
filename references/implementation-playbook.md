# Arcium Implementation Playbook

## Table of Contents
- [Execution Model](#execution-model)
- [Task Classifier](#task-classifier)
- [End-to-End New Computation Flow](#end-to-end-new-computation-flow)
- [Multi-Instruction Program Flow](#multi-instruction-program-flow)
- [Idempotent Computation-Definition Initialization](#idempotent-computation-definition-initialization)
- [ArgBuilder Contracts](#argbuilder-contracts)
- [Callback Contracts](#callback-contracts)
- [Offset and Layout Contracts](#offset-and-layout-contracts)
- [Offchain Circuit Flow](#offchain-circuit-flow)
- [Validation Contract](#validation-contract)

## Execution Model

Arcium program work is split across three layers:

1. `encrypted-ixs/src/lib.rs`
- Defines `#[instruction]` circuits and ownership model (`Shared` vs `Mxe`).

2. `programs/<program>/src/lib.rs`
- Defines `comp_def_offset(...)`, `init_comp_def`, queue instruction contexts, callback contexts, and callback handlers.

3. Client/tests (`tests/*.ts`, optional frontend)
- Encrypts input payloads.
- Derives Arcium PDAs with the same cluster offset as deployment.
- Waits for finalization.
- Verifies/decrypts outputs.

## Task Classifier

Choose a lane before coding:

1. Stateless
- One queue instruction and one callback.
- Typical for `coinflip` and `rock_paper_scissors/against-house`.

2. Stateful encrypted account updates
- Queue reads account ciphertexts with `.account(...)`.
- Callback stores new ciphertexts + nonce.
- Typical for `voting`, `sealed_bid_auction`, `blackjack`.

3. Permissioned flow
- Queue instruction includes ownership/permission constraints.
- Typical for `encrypted_dna_matching`.

4. Offchain circuit source
- `init_comp_def` uses `CircuitSource::OffChain` with `circuit_hash!`.
- Typical for `encrypted_dna_matching`.

5. Migration/debugging
- Resolve API/signature mismatches, LUT wiring, cluster offset mismatches.

## End-to-End New Computation Flow

### 1) Add Arcis instruction

In `encrypted-ixs/src/lib.rs`:

```rust
#[instruction]
pub fn <IX_NAME>(<inputs>) -> <outputs> {
    // use to_arcis() for encrypted input decoding
    // use owner.from_arcis(...) or reveal() for outputs
}
```

Rules:
- Keep the instruction name stable; this drives generated callback types and `comp_def_offset`.
- Do not reorder encrypted fields without updating all client/program encryption order.

### 2) Add offset constants in program

```rust
const COMP_DEF_OFFSET_<IX_NAME_UPPER>: u32 = comp_def_offset("<IX_NAME>");
```

Rules:
- String must exactly match Arcis `#[instruction]` name.
- One constant per encrypted instruction.

### 3) Add `init_*_comp_def`

```rust
pub fn init_<IX_NAME>_comp_def(ctx: Context<Init<Ix>CompDef>) -> Result<()> {
    init_comp_def(ctx.accounts, None, None)?;
    Ok(())
}
```

Rules:
- Required even for single-instruction programs.
- Call once per environment (idempotent helper in tests/client).

### 4) Add queue instruction

Queue instruction must:
- enforce business constraints before queueing,
- build arguments in exact ownership order,
- set signer PDA bump before `queue_computation`,
- pass callback instruction with explicit writable callback accounts.

```rust
ctx.accounts.sign_pda_account.bump = ctx.bumps.sign_pda_account;

let args = ArgBuilder::new()
    // ordered inputs
    .build();

queue_computation(
    ctx.accounts,
    computation_offset,
    args,
    vec![<Ix>Callback::callback_ix(
        computation_offset,
        &ctx.accounts.mxe_account,
        &[
            CallbackAccount {
                pubkey: ctx.accounts.<STATE_OR_JOB>.key(),
                is_writable: true,
            }
        ],
    )?],
    1,
    0,
)?;
```

### 5) Add callback instruction

```rust
#[arcium_callback(encrypted_ix = "<IX_NAME>")]
pub fn <ix_name>_callback(
    ctx: Context<<Ix>Callback>,
    output: SignedComputationOutputs<<IxName>Output>,
) -> Result<()> {
    let decoded = match output.verify_output(
        &ctx.accounts.cluster_account,
        &ctx.accounts.computation_account,
    ) {
        Ok(v) => v,
        Err(_) => return Err(ErrorCode::AbortedComputation.into()),
    };

    // parse, validate cardinality, persist, emit
    Ok(())
}
```

Rules:
- Never read output before `verify_output`.
- For encrypted structs, persist both `ciphertexts` and `nonce`.

### 6) Add account contexts

Add these patterns:
- `#[queue_computation_accounts("<ix_name>", <payer_or_authority>)]`
- `#[callback_accounts("<ix_name>")]`
- `#[init_computation_definition_accounts("<ix_name>", payer)]`

Modern `init_computation_definition_accounts` includes LUT accounts:
- `address_lookup_table` with `derive_mxe_lut_pda!(mxe_account.lut_offset_slot)`
- `lut_program` with `LUT_PROGRAM_ID`

### 7) Add tests/client flow

Required steps:
1. Resolve Arcium environment and cluster offset.
2. Initialize comp-def idempotently.
3. Fetch MXE public key (with retry if needed).
4. Encrypt inputs with `x25519` + `RescueCipher`.
5. Queue instruction.
6. `awaitComputationFinalization(...)`.
7. Validate callback event/state and decrypt outputs if applicable.

## Multi-Instruction Program Flow

For programs with many encrypted instructions (`blackjack`, `sealed_bid_auction`, `voting`, `ed25519`):

1. Keep a one-to-one map:
- encrypted ix name,
- `COMP_DEF_OFFSET_*`,
- queue instruction accounts,
- callback accounts,
- callback parser,
- init-comp-def instruction.

2. Treat each instruction as independently deployable.
- A new instruction must not silently rely on another instruction's comp-def.

3. Use explicit state transitions before queueing.
- Example classes:
  - `AuctionStatus` (`Open -> Closed -> Resolved`)
  - `GameState` in blackjack
  - authority-only reveal in voting

4. Reuse compact callback accounts.
- Pass only required writable accounts to `CallbackAccount`.

## Idempotent Computation-Definition Initialization

Use this in tests/frontend helpers:

1. Derive comp-def PDA from:
- program id,
- `getCompDefAccOffset("<ix_name>")`.

2. Fetch account info.
- If account exists: return `already_initialized`.
- Else call `init_*_comp_def`.

This pattern appears in `encrypted_dna_matching/tests/encrypted_dna_matching.ts` and avoids re-init failures in repeated runs.

## ArgBuilder Contracts

### Shared encrypted input (`Enc<Shared, T>`)

Order:
1. `.x25519_pubkey(<client_pubkey>)`
2. `.plaintext_u128(<nonce>)`
3. encrypted fields in exact circuit argument order

### MXE encrypted input (`Enc<Mxe, T>`)

Order:
1. `.plaintext_u128(<mxe_nonce>)`
2. encrypted fields in exact circuit argument order

### Account-backed encrypted state

Use:
- `.account(<account_pubkey>, <offset>, <len>)`

Contract:
- `<offset>` includes discriminator and all preceding fields.
- `<len>` matches exact ciphertext byte span.
- Keep inline offset comments in code.

## Callback Contracts

### Simple output

```rust
Ok(<IxOutput> { field_0 }) => field_0
```

### Nested output struct

```rust
Ok(<IxOutput> {
    field_0: <IxOutputStruct0> {
        field_0: a,
        field_1: b,
        field_2: c,
    },
}) => (a, b, c)
```

Hard requirements:
- `verify_output` first.
- Validate cardinality for expected ciphertext counts (`len() == N` or `>= N`).
- Persist validated data only.

## Offset and Layout Contracts

Use deterministic formula:

```text
offset = 8 (Anchor discriminator) + size(preceding fields)
```

Common account usage:
- `voting`: `8 + 1`, `len = 32 * 2`
- `sealed_bid_auction`: `8 + 1 + 32 + 1 + 1 + 8 + 8 + 1 + 16`, `len = 32 * 5`
- `encrypted_dna_matching`: `8 + 32 + 16 + 32`, `len = 32 * GENOME_MARKER_COUNT`
- `blackjack`: multiple fixed slices for deck/hand segments

## Offchain Circuit Flow

Use offchain circuits when circuit artifacts are large or deployment constraints favor remote source.

Program init pattern:

```rust
init_comp_def(
    ctx.accounts,
    Some(CircuitSource::OffChain(OffChainCircuitSource {
        source: <CIRCUIT_URL>.to_string(),
        hash: circuit_hash!("<IX_NAME>"),
    })),
    None,
)?;
```

Rules:
- Hash macro string must match the encrypted instruction name.
- Circuit URL must be stable and versioned.
- Keep fallback and retry logic in tests/client for network-dependent setup.

## Validation Contract

Minimum validation sequence:

```bash
arcium build
cargo check --all
arcium test
python3 /Users/grisahudozestvennyj/.codex/skills/.system/skill-creator/scripts/quick_validate.py /Users/grisahudozestvennyj/Documents/projects/arcium/dna/skills/arcium-program-development
rg -n "[\p{Cyrillic}]" /Users/grisahudozestvennyj/Documents/projects/arcium/dna/skills/arcium-program-development || true
```

Acceptance checks:
- Name mapping is exact (`#[instruction]` == `comp_def_offset` == callback macro `encrypted_ix`).
- ArgBuilder order matches ownership model.
- Offset constants match account layout.
- Callback output is verified and shape-checked before use.
- Finalization path is deterministic in tests (`awaitComputationFinalization`).
