---
name: arcium-program-development
description: Build, refactor, and debug Arcium MXE program code across Arcis circuits (`encrypted-ixs`) and Anchor programs (`programs/*`). Use when implementing confidential instructions, wiring `init_comp_def`/`queue_computation`/callbacks, deriving Arcium PDAs and callback accounts, handling encrypted I/O and offsets, testing with `@arcium-hq/client`, deploying MXEs, or migrating Arcium versions.
---

# Arcium Program Development

Implement Arcium computations end-to-end with a stable pattern: Arcis circuit -> computation definition -> queue instruction -> verified callback -> client/test flow.

## Workflow

1. Classify the requested change first.
- `new computation`: add new encrypted instruction and full invocation path.
- `existing computation`: patch circuit logic, account layout, callback handling, or client encryption flow.
- `migration`: upgrade dependencies and API usage before behavior changes.
- `debugging`: isolate failing stage (encryption, queue, callback verify, or finalization wait).

2. Read the minimum context needed.
- Open `encrypted-ixs/src/lib.rs` for circuit signatures and return types.
- Open `programs/*/src/lib.rs` for `COMP_DEF_OFFSET_*`, queue and callback logic.
- Open tests/frontend call sites to verify encryption, PDA derivation, and finalization waiting.
- If upgrading versions, read migration notes before editing API calls.

3. Keep the Arcium contract aligned across files.
- Circuit name in `#[instruction]` must match `comp_def_offset("...")`.
- Callback macro must match instruction name: `#[arcium_callback(encrypted_ix = "...")]`.
- Callback output type must match generated type: `SignedComputationOutputs<YourIxOutput>`.
- Queue and callback accounts must use consistent comp-def and cluster derivation.

4. Build arguments deterministically with `ArgBuilder`.
- For `Enc<Shared, T>` input: pass `x25519_pubkey`, `plaintext_u128(nonce)`, then ciphertext fields.
- For `Enc<Mxe, T>` input: pass nonce and ciphertext (no client pubkey).
- For encrypted state in accounts, pass exact byte windows via `.account(pubkey, offset, len)`.

5. Verify callback outputs defensively.
- Always call `verify_output(&cluster_account, &computation_account)`.
- Handle `Err(_)` with program error (aborted computation).
- Persist ciphertext/nonce to state only after successful verification.

6. Confirm client/test flow is complete.
- Encrypt inputs with x25519 + `RescueCipher`.
- Queue instruction with correct PDAs and comp-def account.
- Wait with `awaitComputationFinalization(...)`, not only tx confirmation.
- Validate emitted callback data and decryption path.

7. Run verification commands after edits.
```bash
arcium build
cargo check --all
arcium test
```

## Guardrails

- Respect current output size limit: callback output should fit in one Solana transaction (~1232 bytes).
- In Arcis, do not rely on dynamic control-flow semantics from regular Rust (`while`, `break`, `continue`, dynamic containers).
- Keep account offset math explicit and documented near `.account(...)` calls.
- Prefer `callback_ix(...)` helper over manual callback instruction assembly.
- For large circuits, prefer offchain circuit source with `CircuitSource::OffChain` + `circuit_hash!`.

## Task Routing

- Implementing or patching computation flow:
Read `references/implementation-playbook.md`.
- Choosing architecture by known examples:
Read `references/examples-patterns.md`.
- Migration/deployment/version constraints:
Read `references/docs-and-migrations.md`.

## Delivery Standard

- Return concrete code edits, not only high-level advice.
- Preserve existing account seeds and PDA conventions unless explicitly migrating.
- If a required value is missing (cluster offset, comp-def name, owner model), make a safe assumption and state it.
- End with exact commands used for validation and known remaining risks.
