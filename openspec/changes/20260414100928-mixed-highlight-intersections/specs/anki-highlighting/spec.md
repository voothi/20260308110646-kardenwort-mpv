## MODIFIED Requirements

### Requirement: Split-Term Multi-Word Highlighting
The visual highlighting system SHALL support non-contiguous subset matching for multi-word terms imported from the TSV database (e.g., terms that contain spaces). If the constituent words of a registered multi-word term are detected scattered but fully present within a specific localized context boundary (such as the same subtitle element/line), those words SHALL be highlighted with a distinctive "split select color" to signify their association. The system MUST evaluate local inclusion by projecting the term's timestamp against the FULL span of the subtitle (`start_time` to `end_time`) rather than a single point to prevent failures on long or multi-line subtitles. The contextual validation (`Options.anki_context_strict`) MUST use strict, word-bounded analysis to prevent substring false positives, and sequence matching MUST abort safely if expected words are entirely missing. Additionally, the system SHALL calculate the nesting depth of split-terms independently from contiguous terms. When a word overlaps with both contiguous and split terms simultaneously, it SHALL be rendered using a distinct "mixed" color palette (`anki_mix_depth_1/2/3`) representing the intersection.

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
