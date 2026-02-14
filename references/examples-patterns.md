# Arcium Example Patterns

Use this map to choose an implementation pattern quickly.

## Pattern Map

| Example | Primary pattern | Local path |
| --- | --- | --- |
| Coinflip | Stateless encrypted input + MPC RNG + revealed bool result | `examples/coinflip` |
| Voting | Persistent encrypted state in account + offset-based `.account(...)` reads + authority-gated reveal | `examples/voting` |
| Share medical records | Re-encryption (`Shared -> Shared`) for selective sharing | `examples/share_medical_records` |
| Sealed bid auction | Encrypted bid aggregation + multiple callbacks for pricing modes | `examples/sealed_bid_auction` |
| Rock paper scissors | Asynchronous hidden moves with encrypted game state | `examples/rock_paper_scissors/against-player` |
| Rock paper scissors vs house | Encrypted move + MPC randomness for house move | `examples/rock_paper_scissors/against-house` |
| Blackjack | Large encrypted game state, packed card representation, multi-step callbacks | `examples/blackjack` |
| Ed25519 | MPC signing and confidential verification key handling | `examples/ed25519` |
| Encrypted DNA matching | Permissioned matching, offchain circuit source, encrypted callback payload | `examples/encrypted_dna_matching` |

## Reusable Idioms from Examples

- `init_comp_def` once per encrypted instruction.
- `queue_computation` in every invocation path.
- `verify_output` in every callback.
- `COMP_DEF_OFFSET_*` derived from exact encrypted instruction names.
- `init_computation_definition_accounts` include LUT accounts in modern versions.

## Advanced Patterns Worth Reusing

- Offchain circuits for large bytecode: `CircuitSource::OffChain` + `circuit_hash!`.
- Byte-accurate encrypted state reads via `.account(pubkey, offset, len)`.
- Compact encrypted payload design to satisfy callback transaction limits.
- Event-driven result handling plus optional client-side decrypt path.

## Upstream Source

- Official examples repo: [arcium-hq/examples](https://github.com/arcium-hq/examples)
