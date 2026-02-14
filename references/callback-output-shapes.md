# Callback Output Shapes

## Table of Contents
- [Core Verification Contract](#core-verification-contract)
- [Shape 1: Simple `field_0`](#shape-1-simple-field_0)
- [Shape 2: Nested `OutputStruct0`](#shape-2-nested-outputstruct0)
- [Shape 3: Multi-Encrypted Payload Contracts](#shape-3-multi-encrypted-payload-contracts)
- [Ciphertext Cardinality Checks](#ciphertext-cardinality-checks)
- [Common Parsing Failures](#common-parsing-failures)

## Core Verification Contract

Always verify before parsing:

```rust
let decoded = match output.verify_output(
    &ctx.accounts.cluster_account,
    &ctx.accounts.computation_account,
) {
    Ok(v) => v,
    Err(_) => return Err(ErrorCode::AbortedComputation.into()),
};
```

Never use `output` fields before verification.

## Shape 1: Simple `field_0`

Typical for single return value or single encrypted object.

Pattern:

```rust
let value = match output.verify_output(...) {
    Ok(MyIxOutput { field_0 }) => field_0,
    Err(_) => return Err(ErrorCode::AbortedComputation.into()),
};
```

Examples:
- `coinflip`: boolean-like reveal output
- `voting`: encrypted state object in `field_0`
- `share_medical_records`: encrypted payload transfer
- `encrypted_dna_matching`: encrypted result object in `field_0`

## Shape 2: Nested `OutputStruct0`

Generated when Arcis instruction returns tuple-like or multi-field structured values.

Pattern:

```rust
let (a, b, c) = match output.verify_output(...) {
    Ok(MyIxOutput {
        field_0: MyIxOutputStruct0 {
            field_0: a,
            field_1: b,
            field_2: c,
        },
    }) => (a, b, c),
    Err(_) => return Err(ErrorCode::AbortedComputation.into()),
};
```

Examples:
- `sealed_bid_auction` winner callbacks
- `blackjack` callbacks returning complex multi-part outputs
- `ed25519` signing callback with structured signature parts

## Shape 3: Multi-Encrypted Payload Contracts

For encrypted return objects, validate expected semantics:
- `nonce` is present and persisted.
- `ciphertexts` count is expected.
- optional `encryption_key` consistency checks if output target key matters.

Pattern:

```rust
let o = ...; // verified output
if o.ciphertexts.len() < 2 {
    return Err(ErrorCode::InvalidCiphertextCount.into());
}

state.output_nonce = o.nonce;
state.value_a = o.ciphertexts[0];
state.value_b = o.ciphertexts[1];
```

Example:
- `encrypted_dna_matching` checks at least 2 ciphertexts before writing result fields.

## Ciphertext Cardinality Checks

Use explicit guards whenever callback logic indexes ciphertext arrays.

Rules:
1. If exact shape is required, enforce `== N`.
2. If minimum shape is acceptable, enforce `>= N`.
3. Prefer explicit custom errors (`InvalidCiphertextCount`) over panics.

Recommended helper pattern:

```rust
fn expect_ciphertexts_len_at_least<T>(slice: &[T], min: usize) -> Result<()> {
    require!(slice.len() >= min, ErrorCode::InvalidCiphertextCount);
    Ok(())
}
```

## Common Parsing Failures

1. Wrong generated output type
- Symptom: compile mismatch on callback output generic.
- Fix: ensure instruction name did not change; rebuild generated code.

2. Wrong nested structure assumption
- Symptom: pattern match compile errors on `field_0/field_1`.
- Fix: inspect generated callback types and update parser shape.

3. Indexing ciphertexts without guard
- Symptom: runtime panic or custom callback error path.
- Fix: add cardinality checks before indexing.

4. Consuming unverified output
- Symptom: logic accepts forged/unexpected data.
- Fix: enforce `verify_output` first in all callbacks.
