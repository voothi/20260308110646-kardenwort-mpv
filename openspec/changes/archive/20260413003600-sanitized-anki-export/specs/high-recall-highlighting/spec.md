## MODIFIED Requirements

### Requirement: Adaptive Punctuation Rendering
The engine SHALL surgically isolate word bodies from their surrounding punctuation marks during rendering, based on match context.
- **Single-Word Mode**: If a highlight corresponds to a single vocabulary word, punctuation marks SHALL remain uncolored (base subtitle color) to provide a clean study interface.
- **Phrase Continuity Mode**: If a highlight corresponds to a multi-word phrase or paragraph, internal punctuation marks SHALL be colored to maintain visual flow and prevent "holes" in the highlight blocks.
- **Multi-Match Priority**: If a word is covered by both a single-word card and a phrase highlight, **Phrase Continuity Mode** SHALL take precedence.

#### Scenario: Word overlapped by a phrase
- **WHEN** the term "ehrlich," exists in Anki as a single-word card (Depth 1)
- **AND** the term "Mal ehrlich," exists in Anki as a multi-word phrase (Depth 1)
- **THEN** both terms SHALL be aggregated, and the comma after "ehrlich" SHALL be colored green (Phrase Continuity Mode).

### Requirement: Clean Boundary Capture
The capture engine SHALL automatically strip leading and trailing punctuation/whitespace from any text copied to the clipboard or exported to Anki tags.
- This ensures that word-boundaries do not pollute the flashcard database, maintaining high dictionary matching rates.
- Internal punctuation (within phrases) SHALL be preserved.

#### Scenario: Exporting a word with trailing punctuation
- **WHEN** the user middle-clicks on the subtitle word "Umbruch."
- **THEN** the term "Umbruch" SHALL be saved to the Anki TSV file (dot stripped).

#### Scenario: Exporting a phrase with internal punctuation
- **WHEN** the user selects "im Umbruch. Während"
- **THEN** the term "im Umbruch. Während" SHALL be saved to the Anki TSV file (internal dot preserved).
