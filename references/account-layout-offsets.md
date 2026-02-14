# Account Layout and Offset Guide

## Table of Contents
- [Offset Formula](#offset-formula)
- [Anchor Size Rules](#anchor-size-rules)
- [Worked Example: Voting](#worked-example-voting)
- [Worked Example: Sealed Bid Auction](#worked-example-sealed-bid-auction)
- [Worked Example: Encrypted DNA Matching](#worked-example-encrypted-dna-matching)
- [Offset Debugging Workflow](#offset-debugging-workflow)
- [Inline Comment Contract](#inline-comment-contract)

## Offset Formula

When queueing encrypted account-backed state via:

```rust
.account(account_pubkey, offset, length)
```

use:

```text
offset = 8 (Anchor discriminator) + size_of(all preceding account fields)
length = ciphertext_field_count * 32 (unless custom packed span)
```

Never hardcode offset without documenting the exact field math.

## Anchor Size Rules

Common fixed-size field costs:
- `u8` / `bool`: 1
- `u16`: 2
- `u32`: 4
- `u64` / `i64`: 8
- `u128`: 16
- `Pubkey`: 32
- fixed array `[u8; 32]`: 32
- nested fixed arrays: multiply dimensions
- Anchor discriminator: 8 bytes at account start

Enum caveat:
- For `#[derive(AnchorSerialize, AnchorDeserialize)]` enums used in accounts, practical examples here use 1-byte discriminant. If enum representation changes, recompute layout and revalidate offsets.

## Worked Example: Voting

Source account fields (`Poll`-like layout used by queueing logic):
- `bump: u8` (1)
- encrypted vote state starts immediately after `bump`

Offset used in program:

```rust
// Offset calculation: 8 bytes (discriminator) + 1 byte (bump)
8 + 1
```

Length used:

```rust
32 * 2 // yes/no ciphertext counters
```

Result:
- `offset = 9`
- `length = 64`

## Worked Example: Sealed Bid Auction

Account fields before encrypted state (`Auction`):
- discriminator: 8
- `bump: u8` -> +1
- `authority: Pubkey` -> +32
- `auction_type: enum` -> +1
- `status: enum` -> +1
- `min_bid: u64` -> +8
- `end_time: i64` -> +8
- `bid_count: u8` -> +1
- `state_nonce: u128` -> +16

Total offset:

```text
8 + 1 + 32 + 1 + 1 + 8 + 8 + 1 + 16 = 76
```

Encrypted state shape:
- `encrypted_state: [[u8; 32]; 5]`

Length:

```text
5 * 32 = 160
```

Program constants:

```rust
const ENCRYPTED_STATE_OFFSET: u32 = 76;
const ENCRYPTED_STATE_SIZE: u32 = 32 * 5;
```

## Worked Example: Encrypted DNA Matching

`GenomeVault` queue reads marker ciphertext region after metadata:
- discriminator: 8
- `owner: Pubkey` -> +32
- `nonce: u128` -> +16
- `encryption_pubkey: [u8; 32]` -> +32

Offset:

```text
8 + 32 + 16 + 32 = 88
```

Marker payload size:
- `GENOME_MARKER_COUNT = 32`
- each marker ciphertext is `[u8; 32]`

Length:

```text
32 * 32 = 1024
```

Program constants:

```rust
const GENOME_CIPHERTEXT_OFFSET: u32 = 8 + 32 + 16 + 32;
const GENOME_CIPHERTEXT_BYTES: u32 = (GENOME_MARKER_COUNT * 32) as u32;
```

## Offset Debugging Workflow

1. Expand the full account struct in order.
2. Write each field size explicitly.
3. Sum discriminator + preceding fields.
4. Compare to `.account(..., offset, len)` in program.
5. Confirm callback output writes back exactly the same region semantics.
6. Validate in tests by roundtrip queue/callback and decrypt expected values.

If mismatch appears:
- inspect recent account field reorder/additions,
- inspect enum representation assumptions,
- inspect packed structs migrated across versions.

## Inline Comment Contract

Every `.account(...)` call for encrypted state must include comments like:

```rust
.account(
    ctx.accounts.state.key(),
    8 + 1 + 32, // 8 discr + 1 bump + 32 owner
    32 * 4,     // 4 ciphertext words
)
```

This is mandatory for maintainability and migration safety.
