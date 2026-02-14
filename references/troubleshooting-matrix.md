# Troubleshooting Matrix

## Table of Contents
- [How to Triage](#how-to-triage)
- [Symptom Matrix](#symptom-matrix)
- [Fast Inspection Commands](#fast-inspection-commands)

## How to Triage

Map failures to one of four stages first:
1. Encryption
2. Queueing and account/PDA wiring
3. Callback verification/parsing
4. Finalization waiting

Then apply the matrix below.

## Symptom Matrix

| Symptom | Probable root cause | Exact inspection point | Fix |
| --- | --- | --- | --- |
| Decrypted output is nonsense or mismatched | Wrong shared secret pairing or nonce serialization bug | Client encryption/decryption helper (`x25519` pair usage, `deserializeLE` conversion, nonce source) | Ensure encryption uses sender secret + MXE pubkey; decryption uses receiver secret + MXE pubkey; use unique 16-byte nonce and consistent LE conversion |
| Queue tx fails with account constraint error | Wrong PDA derivation or cluster offset mismatch | Queue `.accountsPartial(...)` and environment offset (`getArciumEnv().arciumClusterOffset`) | Use single cluster offset across deploy/tests; re-derive all Arcium PDAs with same offset/program id |
| Queue tx fails due to missing comp-def | Comp-def not initialized or wrong comp-def offset string | `comp_def_offset("...")` constant, `init_*_comp_def`, client `getCompDefAccOffset("...")` | Ensure instruction name string is exact and comp-def init ran successfully (idempotent helper recommended) |
| Queue tx confirmed but callback returns `AbortedComputation` | Callback verifying wrong computation/cluster pair or instruction mismatch | Callback macro `#[arcium_callback(encrypted_ix = "...")]`, callback output generic type, `verify_output` call context accounts | Align encrypted instruction name, comp-def account, callback output type; verify accounts are from same computation |
| Callback parse panic / index error | Wrong output shape assumption or missing ciphertext count checks | Callback parser (`field_0` vs `OutputStruct0`), ciphertext indexing | Update parser to generated shape and add `len()` guard before indexing |
| Callback account mutation fails | Missing writable callback account in `callback_ix` account list | Queue instruction callback account vector (`CallbackAccount { is_writable: true }`) | Add required writable callback account(s) explicitly and keep minimal set |
| Permissioned flow rejects valid caller unexpectedly | Wrong constraint seed/value relation | Account constraint expressions (`has_one`, `constraint = ... @ ErrorCode`) | Recompute seeds/owner fields; add explicit logs for owner/matcher keys |
| Finalization wait times out | Wrong computation offset passed to waiter or callback never emitted | `awaitComputationFinalization(...)` args and queue offset generation | Pass the same `computation_offset` object to queue and wait; verify queue tx succeeded and callback is wired |
| Comp-def init fails on modern versions | LUT accounts omitted in init context | `#[init_computation_definition_accounts(...)]` account struct | Include `address_lookup_table` + `lut_program` (`LUT_PROGRAM_ID`) |
| Offchain comp-def init fails | URL/hash mismatch or unreachable artifact | `CircuitSource::OffChain` config and `circuit_hash!("...")` literal | Ensure URL serves the correct artifact and hash string matches instruction name exactly |

## Fast Inspection Commands

```bash
# Find all comp-def offsets and callback macro names
rg -n "comp_def_offset\(|arcium_callback\(encrypted_ix" examples -S

# Find account offset constants/comments
rg -n "\.account\(|OFFSET|offset" examples -S

# Find output verify and parse patterns
rg -n "verify_output\(|OutputStruct0|field_0" examples -S

# Find finalization waits in tests/frontend
rg -n "awaitComputationFinalization" examples -S
```
