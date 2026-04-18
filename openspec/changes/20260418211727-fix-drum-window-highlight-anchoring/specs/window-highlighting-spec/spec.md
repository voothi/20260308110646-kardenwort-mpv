## MODIFIED Requirements

### Requirement: Strict Context Neighbor Verification
When strict context matching is enabled, matches MUST be anchored by their recorded indices or neighbors.

- **Index Grounding**: If a record contains a `SentenceSourceIndex`, the engine SHALL verify that the word's current logical position exactly matches the recorded index.
- **Neighbor Fallback**: If no index is present (legacy records), the engine SHALL look past up to **4 consecutive symbols/separators** to find the nearest word and verify it against the recorded context.

#### Scenario: Index Matching vs. Bleed
- **GIVEN** a database record has `SentenceSourceIndex: 6` for the word `die`.
- **AND** the current segment has a `die` at index 3 and a `die` at index 6.
- **THEN** the engine SHALL only highlight the `die` at index 6.

#### Scenario: Symbol-Agnostic Neighbor Detection
- **WHEN** searching for neighbors to verify context (for legacy records missing an index).
- **THEN** the engine SHALL look past up to **4 consecutive symbols/separators** to find the nearest word.
