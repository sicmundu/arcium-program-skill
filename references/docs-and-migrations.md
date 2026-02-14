# Arcium Docs and Migration Notes

## Primary Documentation

- Intro and architecture: [Computation Lifecycle](https://docs.arcium.com/developers/computation-lifecycle)
- First project: [Hello World](https://docs.arcium.com/developers/hello-world)
- Program invocation: [Program Overview](https://docs.arcium.com/developers/program)
- Comp-def initialization: [Computation Definition Accounts](https://docs.arcium.com/developers/program/computation-def-accs)
- Callback account design: [Callback Accounts](https://docs.arcium.com/developers/program/callback-accs)
- Output type generation: [Callback Type Generation](https://docs.arcium.com/developers/program/callback-type-generation)
- Client encryption: [Encrypting Inputs](https://docs.arcium.com/developers/js-client-library/encryption)
- Callback waiting: [Tracking Callbacks](https://docs.arcium.com/developers/js-client-library/callback)
- Arcis constraints: [Thinking in MPC](https://docs.arcium.com/developers/arcis/mental-model)
- Arcis quick syntax: [Quick Reference](https://docs.arcium.com/developers/arcis/quick-reference)
- Limits: [Current Limitations](https://docs.arcium.com/developers/limitations)
- Deployment: [Deployment](https://docs.arcium.com/developers/deployment)
- Full docs index for LLMs: [llms.txt](https://docs.arcium.com/llms.txt)

## High-Impact Constraints

- Callback output payload must fit a single transaction (~1232 bytes).
- Arcis has fixed-circuit constraints: no `while`, no dynamic containers (`Vec`, `String`, `HashMap`), no secret-dependent early exits.
- Secret-index array access is `O(n)`; avoid when possible.

## Migration Snapshot

### v0.6.3 -> v0.7.0

- Add LUT support in comp-def init accounts:
  - `address_lookup_table: UncheckedAccount<'info>` with `derive_mxe_lut_pda!(mxe_account.lut_offset_slot)`
  - `lut_program: UncheckedAccount<'info>` with `LUT_PROGRAM_ID`
- Remove `callback_url` parameter from `queue_computation(...)`.
- Update Rust and TypeScript dependency versions.

### v0.7.0 -> v0.8.0

- Primarily dependency/tooling updates (`arcup`, crates, `@arcium-hq/client`).
- No major API break reported in official guide.
- New testing option: `arcium test --skip-local-circuit` for offchain-circuit-heavy projects.

## Deployment Checklist

1. `arcium build` and local tests pass.
2. Choose correct cluster offset (e.g., `456` for modern devnet examples).
3. Use reliable RPC (Helius/QuickNode recommended in docs).
4. Initialize computation definitions post-deploy.
5. Ensure client/test PDA derivation uses the same cluster offset as deployment.
