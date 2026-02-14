# Permission and State-Machine Patterns

## Table of Contents
- [Authorization Layers](#authorization-layers)
- [Anchor Constraint Patterns](#anchor-constraint-patterns)
- [State-Machine Gating Patterns](#state-machine-gating-patterns)
- [Permission PDA Pattern](#permission-pda-pattern)
- [Callback-Side State Updates](#callback-side-state-updates)
- [Audit Checklist](#audit-checklist)

## Authorization Layers

Use both layers:

1. Account constraints
- Enforce static ownership/seed/relationship properties in account validation.

2. Runtime `require!` checks
- Enforce dynamic conditions (status transitions, thresholds, caller intent).

Do not rely on only one layer for permission-sensitive flows.

## Anchor Constraint Patterns

### `has_one` ownership binding

```rust
#[account(mut, has_one = authority @ ErrorCode::Unauthorized)]
pub auction: Account<'info, Auction>,
```

Use when account embeds an authority pubkey field.

### Value constraints with explicit error

```rust
#[account(
    constraint = requester_genome.owner == payer.key() @ ErrorCode::InvalidGenomeOwner,
)]
pub requester_genome: Account<'info, GenomeVault>,
```

Use when the relationship is not modeled by `has_one` or needs multiple comparisons.

### Permission flag checks

```rust
#[account(
    constraint = match_permission.allowed @ ErrorCode::PermissionDenied,
)]
pub match_permission: Account<'info, MatchPermission>,
```

Use for explicit allow/deny records.

## State-Machine Gating Patterns

Model statuses as enums and gate every transition.

### Example transition model

- `Open -> Closed -> Resolved` (sealed bid auction)
- `Initial -> PlayerTurn -> DealerTurn -> Resolved` (blackjack-style flow)

Queue instruction checks should enforce prerequisites:

```rust
require!(auction.status == AuctionStatus::Closed, ErrorCode::AuctionNotClosed);
require!(auction.auction_type == AuctionType::Vickrey, ErrorCode::WrongAuctionType);
```

Guidelines:
1. Validate status before building `ArgBuilder`.
2. Validate caller permissions before queueing.
3. Update status in callback only after successful output verification.

## Permission PDA Pattern

Permission record account (`owner`, `matcher`, `allowed`) pattern:

1. Create/update permission PDA in dedicated instruction.
2. In queue instruction, load permission account with deterministic seeds.
3. Enforce `allowed == true` via constraint.

Use this for cross-user authorization (like requester/target-owner DNA matching).

## Callback-Side State Updates

Only callback should mark computation-complete state when callback output is verified.

Recommended callback sequence:
1. verify output,
2. validate output shape/cardinality,
3. update status + result fields,
4. emit event.

Never set `Completed` (or equivalent) before verify+parse.

## Audit Checklist

For every permissioned or stateful instruction:
1. Does account validation constrain owners and permission records?
2. Does runtime logic enforce current status and legal transition?
3. Is queueing blocked on invalid state/permissions?
4. Does callback verify output before mutating status/result fields?
5. Are callback writable accounts minimal and explicit?
