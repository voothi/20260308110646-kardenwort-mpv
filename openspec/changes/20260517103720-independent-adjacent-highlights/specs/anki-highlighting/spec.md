## ADDED Requirements

### Requirement: Non-Colliding Adjacent Identical Highlights
The highlight rendering engine SHALL treat each row from the TSV database as a distinct visual highlight entity based on a unique identity key (`__entry_key`), ensuring that multiple identical or highly similar phrase fragments stored in adjacent or nearby records do not collide or de-duplicate. Even when two highlights have the same term, context, or overlapping temporal range, they MUST be rendered independently.

#### Scenario: Rendering identical adjacent highlights independently
- **WHEN** the TSV contains two distinct rows with identical terms, overlapping/adjacent timeframes, and similar context
- **THEN** both highlights SHALL be successfully evaluated, visual highlighting SHALL be rendered for both instances in the viewport, and their internal caches (such as split-match valid indices) MUST remain isolated using their unique entry keys.
