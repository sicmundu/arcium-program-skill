# Anti-Patterns

## Table of Contents
- [Naming and Comp-Def Alignment](#naming-and-comp-def-alignment)
- [Callback Verification and Parsing](#callback-verification-and-parsing)
- [Offsets and Account Layout](#offsets-and-account-layout)
- [Arcis Secret-Flow Model Violations](#arcis-secret-flow-model-violations)
- [Nonce and Encryption Discipline](#nonce-and-encryption-discipline)
- [Deployment and Migration Safety](#deployment-and-migration-safety)

## Naming and Comp-Def Alignment

Forbidden:
1. Mismatched instruction naming across:
- Arcis `#[instruction] <name>`
- `comp_def_offset("<name>")`
- `#[arcium_callback(encrypted_ix = "<name>")]`

2. Copy/paste comp-def constants reused for a different instruction.

3. Queueing with a comp-def offset derived from old instruction names.

Consequence:
- callback verification failures, wrong comp-def PDA usage, or runtime aborts.

## Callback Verification and Parsing

Forbidden:
1. Using callback output without `verify_output(...)`.
2. Assuming output shape is always flat `field_0` when generator produced nested `OutputStruct0`.
3. Indexing ciphertext arrays without cardinality checks.
4. Persisting callback output before verification.

Consequence:
- security and correctness failures; runtime panics.

## Offsets and Account Layout

Forbidden:
1. Undocumented offset constants for `.account(...)` reads.
2. Reordering account fields without recomputing offsets.
3. Reusing offset constants from unrelated account types.

Consequence:
- ciphertext reads from wrong byte ranges and corrupted state updates.

## Arcis Secret-Flow Model Violations

Forbidden:
1. Secret-dependent control flow assumptions that Arcis model does not support.
2. Designing circuits around unsupported dynamic containers (`Vec`, `String`, `HashMap`) or unbounded loops.
3. Revealing intermediate secrets unnecessarily when only aggregate/public result is required.

Consequence:
- compilation failures, invalid privacy model, or excessive leakage.

## Nonce and Encryption Discipline

Forbidden:
1. Missing nonce discipline in client encrypt/decrypt paths.
2. Reusing nonce + key pair combinations across independent payloads.
3. Mixing endian conversions inconsistently (`deserializeLE` mismatch).
4. Using wrong key pairing (not MXE counterparty) for shared secret derivation.

Consequence:
- decryption failure or cryptographic weakening.

## Deployment and Migration Safety

Forbidden:
1. Running client/tests on different cluster offsets than deployed program assumptions.
2. Skipping LUT accounts in modern comp-def init contexts.
3. Ignoring migration guides during dependency bumps.
4. Treating offchain circuit URLs as mutable unversioned artifacts.

Consequence:
- environment-specific failures, missing account errors, non-reproducible deployments.
