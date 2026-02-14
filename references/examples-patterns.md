# Arcium Example Patterns

## Table of Contents
- [Feature Matrix](#feature-matrix)
- [Reusable Patterns by Example](#reusable-patterns-by-example)
- [Anti-Patterns by Example Class](#anti-patterns-by-example-class)

## Feature Matrix

Legend:
- `State model`: stateless, stateful, permissioned
- `Randomness`: `ArcisRNG` or deterministic
- `Re-encryption`: whether ownership transfer (`Shared -> Shared`) is present
- `Packed data`: `Pack<T>` or manual packing (base-64 style, etc.)
- `Offchain source`: whether `CircuitSource::OffChain` is used in comp-def init
- `Output shape`: simple (`field_0`) vs nested (`OutputStruct0` tuple-like)

| Example | Local path | State model | Randomness usage | Re-encryption usage | Packed data usage | Permission constraints | Offchain circuit source | Multi-comp-def count | Callback output shape complexity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Coinflip | `examples/coinflip` | Stateless | Yes (`ArcisRNG::bool`) | No | No | Minimal | No | 1 | Simple (`FlipOutput { field_0 }`) |
| Voting | `examples/voting` | Stateful | No | No | No | Authority-gated reveal (`has_one` + require) | No | 3 (`init_vote_stats`, `vote`, `reveal_result`) | Simple |
| Share Medical Records | `examples/share_medical_records` | Stateless request + state storage | No | Yes (`receiver.from_arcis(input)`) | No | Minimal | No | 1 | Simple |
| Sealed Bid Auction | `examples/sealed_bid_auction` | Stateful | No | No | No | Strong (`has_one`, status gates) | No | 4 | Mixed simple + nested (`DetermineWinner*OutputStruct0`) |
| RPS Against Player | `examples/rock_paper_scissors/against-player` | Stateful game session | No | No | No | Player/state progression checks | No | 3 (`init_game`, `player_move`, `compare_moves`) | Simple |
| RPS Against House | `examples/rock_paper_scissors/against-house` | Stateless/game-light | Yes (`ArcisRNG::bool`) | No | No | Minimal | No | 1 | Simple |
| Blackjack | `examples/blackjack` | Stateful multi-step | Yes (`ArcisRNG::shuffle`) | Yes (player/dealer views) | Manual packing (`Deck`, `Hand` packed into `u128`) | Strong game-state constraints | No | 6 | Mixed simple + nested across callbacks |
| Ed25519 | `examples/ed25519` | Stateless per call | No | No | Yes (`Pack<VerifyingKey>`) | Minimal | No | 2 (`sign_message`, `verify_signature`) | Mixed simple + nested |
| Encrypted DNA Matching | `examples/encrypted_dna_matching` | Permissioned + stateful jobs | No | No (outputs encrypted to receiver) | No | Strong (`constraint = ... @ ErrorCode`) | Yes (`CircuitSource::OffChain`) | 1 | Simple with explicit ciphertext cardinality checks |

## Reusable Patterns by Example

### Coinflip

What to reuse:
- Minimal single-computation skeleton (`comp_def_offset`, init-comp-def, queue, callback).
- MPC randomness pattern for fair outcomes.
- Simple callback parsing and event emission.

### Voting

What to reuse:
- Encrypted state accumulation in a single account with `.account(...)` offsets.
- Authority-only reveal path.
- Multi-comp-def organization for lifecycle phases.

### Share Medical Records

What to reuse:
- Clean re-encryption ownership transfer (`Shared -> Shared`) via receiver key.
- Compact encrypted struct handoff without revealing plaintext.

### Sealed Bid Auction

What to reuse:
- Status-gated state machine (`Open -> Closed -> Resolved`).
- Nested callback output parsing for tuple-like winner results.
- Explicit offset constants with comments for encrypted state region.

### RPS Against Player

What to reuse:
- Multi-stage game flow with sequential computations.
- Final reveal-only result model while preserving hidden moves.

### RPS Against House

What to reuse:
- Lightweight randomness-driven adversary model.
- Single-output callback flow for quick prototyping.

### Blackjack

What to reuse:
- Multi-computation orchestration at scale.
- Manual packing strategy for large encrypted state (`Deck`, `Hand`) to reduce footprint.
- Complex callback parsing with multiple encrypted outputs and state transitions.

### Ed25519

What to reuse:
- Cryptographic primitive integration (`Pack<...>` for key material).
- Split sign/verify computations with separate comp-defs.

### Encrypted DNA Matching

What to reuse:
- Permission PDA model with explicit constraints.
- Offchain circuit source + `circuit_hash!` init flow.
- Idempotent comp-def initialization helper in tests.
- Ciphertext count validation before storing callback outputs.

## Anti-Patterns by Example Class

### Stateless computations

Avoid:
- Overdesigning with unnecessary state accounts.
- Returning raw secret intermediate values when a boolean/result code is enough.

### Stateful encrypted computations

Avoid:
- Hard-coded offsets without layout comments or formulas.
- Reordering account fields without recomputing `.account(...)` offsets.
- Writing callback outputs before `verify_output`.

### Permissioned computations

Avoid:
- Deferring authorization checks until after queueing.
- Using `UncheckedAccount` where strict Anchor constraints can be expressed.

### Packed data computations

Avoid:
- Mixing encoding schemes across circuit/program/client.
- Silent precision/bit-width changes in packed structs.

### Offchain circuit computations

Avoid:
- Hash/source mismatch (`circuit_hash!(...)` not matching actual instruction artifact).
- Unversioned mutable URLs for production comp-def initialization.

## Source Reference

- Local source of truth: `examples/*` in this repository.
- Upstream examples mirror: [arcium-hq/examples](https://github.com/arcium-hq/examples)
