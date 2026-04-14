## MODIFIED Requirements

### Requirement: Split-Term Multi-Word Highlighting
The visual highlighting system SHALL support non-contiguous subset matching for multi-word terms imported from the TSV database (e.g., terms that contain spaces). If the constituent words of a registered multi-word term are detected scattered but fully present within a specific localized context boundary (such as the same subtitle element/line), those words SHALL be highlighted with a distinctive "split select color" to signify their association. The system MUST evaluate local inclusion by projecting the term's timestamp against the FULL span of the subtitle (`start_time` to `end_time`) rather than a single point to prevent failures on long or multi-line subtitles. The contextual validation (`Options.anki_context_strict`) MUST use strict, word-bounded analysis to prevent substring false positives, and sequence matching MUST abort safely if expected words are entirely missing.

#### Scenario: Contiguous highlighting takes precedence
- **WHEN** a multi-word TSV term exists that can be matched as a single exact, contiguous string within the text
- **AND** the word sequence exactly corresponds without interruptions or missing words
- **THEN** it SHALL be rendered in the standard saved orange highlight.

#### Scenario: Successful application of the split highlight
- **WHEN** a multi-word TSV term (like "mache auf") exists in the TSV
- **AND** both "mache" and "auf" appear separated within the same subtitle text block
- **THEN** both individual words SHALL be styled using the `split_select_color` (which defaults to a purple color if unset).

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
- **THEN** the system SHALL securely scan a sufficient window of surrounding subtitle chunks (e.g. `[-15, +15]`) to capture scattered components.
- **AND** the system SHALL automatically augment the fuzzy temporal validity constraint to span exactly that outer limit natively, to ensure that words located at the far extremities of the phrase correctly inherit the temporal validity initially recorded for the first word.
