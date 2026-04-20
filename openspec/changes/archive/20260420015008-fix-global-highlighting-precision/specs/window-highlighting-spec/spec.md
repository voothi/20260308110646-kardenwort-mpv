## ADDED Requirements

### Requirement: Global Neighborhood Robustness
The neighborhood verification for Global Mode matches MUST be punctuation-agnostic and robust to subtitle segmentation differences.

#### Scenario: Word-Based Context Verification
- **WHEN** evaluating a match in Global Mode.
- **THEN** the engine SHALL verify the context by checking if at least one meaningful word (non-symbol) from neighbor segments exists within the recorded Anki category/context. 
- **AND** this check SHALL ignore differences in punctuation, case, and formatting tags to ensure high recall for saved vocabulary.

### Requirement: Global Temporal Un-grounding
Multi-word split phrases (containing ellipses) SHALL NOT be restricted by the original record's absolute timestamp in Global Mode.

#### Scenario: Global Context Discovery
- **WHEN** Global Highlighting is enabled.
- **THEN** the engine SHALL anchor the search for phrase components relative to the currently rendered subtitle segment (`sub_idx`).
- **AND** it SHALL enforce the `anki_split_gap_limit` (temporal gap between words) locally within the current timeline, ignoring the distance from the original card creation time.
