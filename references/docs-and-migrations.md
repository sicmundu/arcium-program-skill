# Arcium Docs and Migration Notes

## Table of Contents
- [Primary Documentation](#primary-documentation)
- [Version Migration Matrix (v0.1.x -> v0.8.x)](#version-migration-matrix-v01x---v08x)
- [When to Pick Offchain Circuit Source](#when-to-pick-offchain-circuit-source)
- [Deployment Reliability Checklist](#deployment-reliability-checklist)

## Primary Documentation

Core docs:
- Intro: [https://docs.arcium.com/developers](https://docs.arcium.com/developers)
- Hello world: [https://docs.arcium.com/developers/hello-world](https://docs.arcium.com/developers/hello-world)
- Computation lifecycle: [https://docs.arcium.com/developers/computation-lifecycle](https://docs.arcium.com/developers/computation-lifecycle)
- Deployment: [https://docs.arcium.com/developers/deployment](https://docs.arcium.com/developers/deployment)
- Limitations: [https://docs.arcium.com/developers/limitations](https://docs.arcium.com/developers/limitations)
- Program overview: [https://docs.arcium.com/developers/program](https://docs.arcium.com/developers/program)
- Comp-def accounts: [https://docs.arcium.com/developers/program/computation-def-accs](https://docs.arcium.com/developers/program/computation-def-accs)
- Callback accounts: [https://docs.arcium.com/developers/program/callback-accs](https://docs.arcium.com/developers/program/callback-accs)
- Callback type generation: [https://docs.arcium.com/developers/program/callback-type-generation](https://docs.arcium.com/developers/program/callback-type-generation)
- JS client overview: [https://docs.arcium.com/developers/js-client-library](https://docs.arcium.com/developers/js-client-library)
- JS input encryption: [https://docs.arcium.com/developers/js-client-library/encryption](https://docs.arcium.com/developers/js-client-library/encryption)
- JS callback/finalization tracking: [https://docs.arcium.com/developers/js-client-library/callback](https://docs.arcium.com/developers/js-client-library/callback)
- Arcis overview: [https://docs.arcium.com/developers/arcis](https://docs.arcium.com/developers/arcis)
- Arcis best practices: [https://docs.arcium.com/developers/arcis/best-practices](https://docs.arcium.com/developers/arcis/best-practices)
- Arcis quick reference: [https://docs.arcium.com/developers/arcis/quick-reference](https://docs.arcium.com/developers/arcis/quick-reference)
- Migration index: [https://docs.arcium.com/developers/migration](https://docs.arcium.com/developers/migration)
- LLM index: [https://docs.arcium.com/llms.txt](https://docs.arcium.com/llms.txt)

## Version Migration Matrix (v0.1.x -> v0.8.x)

Use each official migration page as the source of truth. The matrix below highlights practical breaking surfaces to check in code reviews.

| From -> To | Official guide | Breaking surface to inspect first |
| --- | --- | --- |
| v0.1.x -> v0.2.0 | [guide](https://docs.arcium.com/developers/migration/migration-v0.1-to-v0.2) | Arcis syntax and ownership typing changes; generated type naming assumptions; client serialization assumptions |
| v0.2.x -> v0.3.0 | [guide](https://docs.arcium.com/developers/migration/migration-v0.2-to-v0.3) | Program macro updates, account context macro expectations, callback glue updates |
| v0.3.x -> v0.4.0 | [guide](https://docs.arcium.com/developers/migration/migration-v0.3-to-v0.4) | Encryption API updates, nonce/key handling in TS clients, output parsing expectations |
| v0.4.x -> v0.5.1 | [guide](https://docs.arcium.com/developers/migration/migration-v0.4-to-v0.5) | Queue/callback account interface tightening, account derivation helper changes |
| v0.5.x -> v0.6.3 | [guide](https://docs.arcium.com/developers/migration/migration-v0.5-to-v0.6) | `@arcium-hq/client` helper changes, dependency alignment between Rust and TS |
| v0.6.3 -> v0.7.0 | [guide](https://docs.arcium.com/developers/migration/migration-v0.6.3-to-v0.7.0) | Add LUT accounts to comp-def init contexts (`address_lookup_table`, `lut_program`), remove deprecated queue `callback_url`, refresh crate/npm versions |
| v0.7.0 -> v0.8.0 | [guide](https://docs.arcium.com/developers/migration/migration-v0.7.0-to-v0.8.0) | Dependency/tooling updates (`arcup`, crates, JS client), verify test flow compatibility; validate offchain-circuit workflows with `arcium test --skip-local-circuit` when needed |

### Breaking Surface Checklist Per Upgrade Step

For every migration step:
1. Rebuild encrypted instructions (`arcium build`) and regenerate callback output types.
2. Verify all `comp_def_offset("...")` strings still match instruction names.
3. Revalidate `init_computation_definition_accounts` account sets (especially LUT accounts on modern versions).
4. Revalidate `queue_computation(...)` signature and argument order.
5. Revalidate client helper usage (`getCompDefAccOffset`, PDA helpers, finalization helpers).
6. Rerun full e2e test suite with fresh comp-def initialization.

## When to Pick Offchain Circuit Source

Prefer `CircuitSource::OffChain` when one or more conditions are true:
1. Circuit artifacts are large or change often during active development.
2. You need independent artifact hosting/versioning workflows.
3. You want reproducible pinning by URL + hash.
4. Local test setup should skip local circuit execution (`--skip-local-circuit`).

Prefer default/local source when:
1. The circuit is small and stable.
2. You want fewer external runtime dependencies.
3. You prioritize local deterministic tests without network access.

Offchain non-negotiables:
- Hash must use `circuit_hash!("<instruction_name>")` with exact instruction name.
- URL must be stable and versioned.
- Rollout should include a fallback/retry policy in test and deployment scripts.

## Deployment Reliability Checklist

### Build and artifact checks
1. Run `arcium build` and `cargo check --all`.
2. Run e2e tests for queue -> callback -> finalization.
3. Confirm callback output parsers still match generated output structs.

### Cluster and PDA consistency checks
1. Pick one cluster offset for the deployment target.
2. Ensure the same offset is used by:
- deployment scripts,
- test/client `getArciumEnv()` values,
- all PDA helper calls (`getComputationAccAddress`, `getCompDefAccAddress`, `getClusterAccAddress`, `getLookupTableAddress`).
3. Confirm on-chain derived addresses match client-derived addresses before queueing.

### Comp-def initialization reliability
1. Initialize every encrypted instruction comp-def once (idempotent helpers recommended).
2. For v0.7+ style contexts, include LUT accounts in init calls.
3. Fail deployment if any required comp-def account is missing.

### Runtime reliability checks
1. Validate MXE key fetch path with retry.
2. Validate queue transaction confirmation and capture signatures.
3. Always wait for finalization (`awaitComputationFinalization`) before asserting callback state.
4. Emit actionable logs: computation offset, comp-def offset, queue tx, finalization tx.
