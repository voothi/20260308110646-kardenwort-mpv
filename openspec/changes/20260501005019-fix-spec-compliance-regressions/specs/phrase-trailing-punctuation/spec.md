## MODIFIED Requirements

### Requirement: Phrase Trailing Punctuation Capture
The Anki export system SHALL include closing punctuation tokens (non-word tokens with fractional logical indices that immediately follow the last selected word) in the reconstructed phrase field when a multi-line range selection ends at the last word of the final subtitle line.
- This applies exclusively to the **final subtitle line** of a multi-line selection. The inclusion stops at the next word token boundary (i.e., a token with `is_word == true` and `logical_idx > p2_w`).
- **Restoration Policy**: This requirement SHALL be preserved even when "Sentence Punctuation Restoration" is disabled. Bonded punctuation is part of the user's selection intent, not a synthetic restoration.

#### Scenario: Closing parenthesis attached to last word
- **WHEN** the user selects words 1–3 of subtitle line `[UMGEBUNG] Sport-Thieme (Gersdorf/Straubing-Ost)`
- **AND** word 3 is `Ost` and `)` is the immediately following non-word token
- **THEN** the exported phrase SHALL be `[UMGEBUNG] Sport-Thieme (Gersdorf/Straubing-Ost)` (including the closing `)`)

#### Scenario: Trailing period attached to last word
- **WHEN** the user selects words spanning multiple subtitle lines and the last line ends with `Straubing.`
- **AND** the word `Straubing` is the last selected word and `.` is a trailing punctuation token
- **THEN** the exported phrase SHALL include the `.` following `Straubing`
