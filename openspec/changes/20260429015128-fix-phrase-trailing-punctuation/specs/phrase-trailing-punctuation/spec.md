## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: Literal TSV Term Reconstruction
The Anki export system SHALL reconstruct the phrase field using literal token concatenation from the subtitle stream, preserving the original whitespace and punctuation **including closing punctuation tokens that are directly bonded (no intervening word token) to the last selected word on the final subtitle line of a multi-line range selection.**
- **Source**: Tokens MUST be retrieved using `build_word_list_internal(text, true)`.
- **Normalization**: No regex-based space collapsing SHALL be applied to the final reconstructed string.
- **Last-line trailing tokens**: On the final subtitle line only, fractional-index non-word tokens occurring after `p2_w` SHALL be appended until the next `is_word == true` token is reached.
