## Purpose
Enable multi-word selection across non-contiguous subtitle segments and lines, facilitating the creation of complex Anki flashcards for split phrases or multi-word expressions.

## Requirements

### Requirement: Paired Word Accumulation (Cool Path)
The Drum Window SHALL accumulate individually-clicked words or ranges into a persistent "Paired Selection Set" (`ctrl_pending_set`). Interaction logic MUST support multiple input devices via the coordinated-input-system.

#### Scenario: Word accumulation via pairing key
- **WHEN** the user triggers the "Pair" action (e.g., `t`, `е`, or `Ctrl+LMB`) on a word that is not already in the pending set
- **THEN** the word SHALL be added to the `ctrl_pending_set` accumulator.
- **AND** it SHALL be rendered in the "Cool Path" pending color (**Neon Pink #FF88FF**).

#### Scenario: Persistence across modifier release
- **WHEN** the user releases the `Ctrl` key or other modifier used for pairing
- **THEN** the `ctrl_pending_set` SHALL NOT be cleared; the Pink highlights MUST remain visible to support remote controllers and focused curation.

#### Scenario: Selection toggle
- **WHEN** the user triggers the "Pair" action on a word already in the `ctrl_pending_set`
- **THEN** the word SHALL be removed from the accumulator and its Pink highlight SHALL disappear.

### Requirement: Cool Path Visual Feedback
Words in the `ctrl_pending_set` SHALL be rendered with a distinct Neon Pink pending-highlight, visually isolated from the Gold focus indicators and Orange/Purple saved highlights.

#### Scenario: Neon Pink pending color applied
- **WHEN** one or more words are in `ctrl_pending_set`
- **THEN** each such word SHALL be wrapped in the ASS color tag corresponding to `ctrl_select_color` (default `#FF88FF`) during the render pass.

### Requirement: Smart Multi-Word Commit
The system SHALL commit the accumulated `ctrl_pending_set` to Anki when the user triggers the "Add" action (e.g., `r`, `к`, or `Ctrl+MMB`) on any word already in the set.

#### Scenario: Successful commit of a split phrase
- **WHEN** `ctrl_pending_set` contains two or more non-contiguous words
- **AND** the user triggers the "Add" action on a member of the set
- **THEN** the system SHALL sort the accumulated words in document order (line index, then word index).
- **AND** it SHALL join them using the smart-joiner-service (injecting ellipses ` ... ` for gaps).
- **AND** it SHALL generate a Multi-Pivot coordinate string for the `SentenceSourceIndex` field in the format `LineOffset:WordIndex:TermPos` for every word.
- **AND** the export timestamp SHALL be set to the `start_time` of the earliest-selected line + 0.001s.
- **AND** `ctrl_pending_set` SHALL be cleared.

### Requirement: Explicit Discard Gesture
The system MUST provide a high-priority escape mechanism to clear the persistent selection set.

#### Scenario: Discard via Ctrl+ESC
- **WHEN** the user presses `Ctrl+ESC`
- **THEN** both the `ctrl_pending_set` and all active selection anchors SHALL be cleared immediately.

### Requirement: Punctuation Preservation
Composed terms from multi-word selections MUST preserve all internal punctuation (e.g., dashes, slashes), only stripping symbols from the extreme boundaries of the final string.

#### Scenario: Preserving middle-word dashes
- **WHEN** composing a term from tokens "Marken", "-", and "Discount"
- **THEN** the resulting term MUST be "Marken-Discount".

### Requirement: Configurable Palette
The system SHALL allow user overrides for all terminal colors in the "Warm vs. Cool" system.
- `ctrl_select_color`: Default `#FF88FF` (Neon Pink)
- `focus_range_color`: Default `#00CCFF` (Gold)
