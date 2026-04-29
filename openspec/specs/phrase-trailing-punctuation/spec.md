# phrase-trailing-punctuation Specification

## Purpose
TBD - created by archiving change 20260429015128-fix-phrase-trailing-punctuation. Update Purpose after archive.
## Requirements
### Requirement: Phrase Trailing Punctuation Capture
The Anki export system SHALL include closing punctuation tokens (non-word tokens with fractional logical indices that immediately follow the last selected word) in the reconstructed phrase field when a multi-line range selection ends at the last word of the final subtitle line.

This applies exclusively to the **final subtitle line** of a multi-line selection. The inclusion stops at the next word token boundary (i.e., a token with `is_word == true` and `logical_idx > p2_w`).

#### Scenario: Closing parenthesis attached to last word
- **WHEN** the user selects words 1–3 of subtitle line `[UMGEBUNG] Sport-Thieme (Gersdorf/Straubing-Ost)`
- **AND** word 3 is `Ost` and `)` is the immediately following non-word token
- **THEN** the exported phrase SHALL be `[UMGEBUNG] Sport-Thieme (Gersdorf/Straubing-Ost)` (including the closing `)`)

#### Scenario: Trailing period attached to last word
- **WHEN** the user selects words spanning multiple subtitle lines and the last line ends with `Straubing.`
- **AND** the word `Straubing` is the last selected word and `.` is a trailing punctuation token
- **THEN** the exported phrase SHALL include the `.` following `Straubing`

#### Scenario: Middle lines are unaffected
- **WHEN** a multi-line selection spans three subtitle lines
- **AND** the middle line ends with closing punctuation
- **THEN** the middle-line closing punctuation SHALL be included by the existing token ordering (unchanged), and no regression SHALL occur

#### Scenario: No trailing punctuation present
- **WHEN** the last selected word on the final line is the absolute last character of the subtitle
- **AND** no punctuation token follows it
- **THEN** the export SHALL behave identically to before this change (no regression)

#### Scenario: Single-word export is unaffected
- **WHEN** the user exports a single word via MMB click (no anchor/cursor range)
- **THEN** the single-word export path SHALL be unchanged and unaffected by this fix

