## MODIFIED Requirements

### Requirement: Strict Context Neighbor Verification
When strict context matching is enabled, matches MUST be anchored by their recorded indices or neighbors.

- **Index Grounding**: If a record contains a `SentenceSourceIndex`, the engine SHALL verify that the word's current logical position exactly matches the recorded index.
- **Phrase Grounding (Traceback)**: For multi-word phrases, the engine SHALL trace back from the current word's offset to the phrase start and verify that the origin matches the $(time, index)$ anchor.
- **Neighbor Fallback**: If no index is present (legacy records), the engine SHALL look past up to **4 consecutive symbols/separators** to find the nearest word and verify it against the recorded context.

#### Scenario: Index Matching vs. Bleed
- **GIVEN** a database record has `SentenceSourceIndex: 6` for the word `die`.
- **AND** the current segment has a `die` at index 3 and a `die` at index 6.
- **THEN** the engine SHALL only highlight the `die` at index 6.

#### Scenario: Multi-Subtitle Phrase Grounding
- **GIVEN** a phrase "Alpha Beta" starts in Subtitle 1 and continues in Subtitle 2.
- **AND** the record is anchored to `Subtitle 1, Index 5`.
- **WHEN** evaluating "Beta" in Subtitle 2.
- **THEN** the engine SHALL trace back to find "Alpha" in Subtitle 1.
- **AND** it SHALL verify that "Alpha" is at `Subtitle 1, Index 5`.
- **AND** if grounded, it SHALL highlight "Beta" in Subtitle 2.

#### Scenario: Symbol-Agnostic Neighbor Detection
- **WHEN** searching for neighbors to verify context (for legacy records missing an index).
- **THEN** the engine SHALL look past up to **4 consecutive symbols/separators** to find the nearest word.

### Requirement: Highlight Rendering Scope (Global vs. Local)
The rendering engine SHALL support two distinct modes of evaluation.

#### Scenario: Mode Availability
- **WHEN** the engine evaluates a record
- **THEN** it SHALL support Local Highlighting (anchored by timestamp) and Global Highlighting (context-verified).

- **Local Highlighting (Global OFF)**: Highlights SHALL be strictly anchored to the original $(time, index)$ context. If a record has an anchor index, matches in any other location SHALL be rejected.
- **Global Highlighting (Global ON)**: Highlights are applied across the entire timeline, provided they pass strict neighborhood verification. Anchored matches take priority if multiple candidates exist in the same subtitle.
