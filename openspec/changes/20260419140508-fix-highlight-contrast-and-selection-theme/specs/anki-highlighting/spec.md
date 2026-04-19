## MODIFIED Requirements

### Requirement: Split-Term Multi-Word Highlighting
The visual highlighting system SHALL support non-contiguous subset matching for multi-word terms imported from the TSV database (e.g., terms that contain spaces). If the constituent words of a registered multi-word term are detected scattered but fully present within a specific localized context boundary, those words SHALL be highlighted with a distinctive "split select color" to signify their association. The system MUST evaluate local inclusion by projecting the term's timestamp against the FULL span of the subtitle (`start_time` to `end_time`) rather than a single point to prevent failures on long or multi-line subtitles. The contextual validation (`Options.anki_context_strict`) MUST use strict, word-bounded analysis to prevent substring false positives, and sequence matching MUST abort safely if expected words are entirely missing. Additionally, the system SHALL calculate the nesting depth of split-terms independently from contiguous terms. When a word overlaps with both contiguous and split terms simultaneously, it SHALL be rendered using a distinct "mixed" color palette (`anki_mix_depth_1/2/3`) representing the intersection. **The visual intent of split-matching SHALL be linked to the "Cool Path" (Vivid Violet selection transitions to Purple match).**

#### Scenario: Contiguous highlighting takes precedence when pure
- **WHEN** a multi-word TSV term exists that can be matched as a single exact, contiguous string within the text
- **AND** it does not overlap with any split terms
- **THEN** it SHALL be rendered in the standard saved orange highlight based on its contiguous nesting depth.

#### Scenario: Pure split highlighting
- **WHEN** a multi-word TSV term exists in the TSV as non-contiguous
- **AND** the words do not overlap with any orange contiguous terms
- **THEN** the words SHALL be styled using the `anki_split_depth_X` color palette based on split nesting depth.

#### Scenario: Mixed intersection highlighting
- **WHEN** a word is a member of BOTH an orange contiguous saved term AND a purple split saved term
- **THEN** the system SHALL recognize the intersection
- **AND** it SHALL apply a mixed-color format (`anki_mix_depth_X`) determined by the combined depth of the intersection, ensuring the dual-membership is visually distinct.

#### Scenario: Incomplete presence disables split highlight
- **WHEN** a multi-word TSV term exists in the TSV (e.g., "mache auf")
- **AND** only one of the constituent words ("mache") is present in the subtitle line while the others are absent
- **THEN** no split highlight SHALL be applied to that single word.

#### Scenario: Missing relative word invalidates sequence match
- **WHEN** a multi-word TSV term is partially contiguous, but the expected consecutive word is absent from the subtitle block or gap range
- **THEN** the system SHALL immediately invalidate the contiguous sequence matching logic and fall-back to split matching.

#### Scenario: Proper split subset identification
- **WHEN** a multi-word TSV term is processed for split matching (e.g. "ist die Anwohner")
- **AND** intermediate generic words (e.g. "die") occur multiple times within the same context
- **THEN** the system SHALL calculate the shortest sequential span of the term's elements matching their original order, restricting the highlight strictly to those valid subsets and preventing false coloration on earlier or unrelated instances of those words (e.g. "die Geräte").

#### Scenario: Split phrase synchronization across wide clusters
- **WHEN** a split multi-word term bridges an extremely long span of dialogue over many subtitle events (e.g. "Beruf ... da")
- **THEN** the system SHALL securely scan a configurable window of surrounding subtitle chunks (default `+/- 35 lines`) to capture scattered components.
- **AND** the system SHALL automatically augment the temporal validity constraint up to a configurable limit (default `60.0s`) to ensure scattered components are correctly unified.
