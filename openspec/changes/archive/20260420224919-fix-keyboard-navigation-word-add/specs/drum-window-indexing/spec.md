## MODIFIED Requirements

### Requirement: Keyboard Cursor Synchronization
The system SHALL ensure that line-based keyboard navigation (UP/DOWN) always synchronizes the cursor to a valid word token on the target line.
- **Auto-Snap**: If a line move occurs and the new line contains word tokens, the `FSM.DW_CURSOR_WORD` SHALL be set to the logical index of the first word token on that line.
- **Empty Line Handling**: If a line contains no word tokens, `FSM.DW_CURSOR_WORD` SHALL be set to `-1` to prevent invalid toggle/export actions.

#### Scenario: Navigating to a line with leading punctuation
- **WHEN** the user navigates from one line to the next using the DOWN arrow.
- **AND** the target line starts with leading punctuation (e.g., `[Note]`).
- **THEN** `FSM.DW_CURSOR_WORD` SHALL be set to the logical index corresponding to the first word (e.g., "Note").

## MODIFIED Requirements

## MODIFIED Requirements

### Requirement: Marker-Injection Pivot Anchoring
The system SHALL anchor the focus pivot to a specific logical coordinate rather than a geometric midpoint to eliminate search drift in variable-font environments.
- **Constraint**: The context search engine MUST use the Multi-Pivot map to uniquely identify the exact word occurrence in the subtitle database.
- **Fallback**: If no Multi-Pivot map is present (legacy records), the system SHALL fallback to geometric proximity matching.

#### Scenario: Centering on a specific word index
- **WHEN** the user selects word 5 in a multi-word line.
- **THEN** the system SHALL anchor all coordinate lookups and rendering calculations specifically to the logical index `5`.

### Requirement: Temporal Epsilon Guard
Exports SHALL include a mandatory temporal offset to ensure the recorded timestamp sits reliably within the subtitle's active window.
- **Offset**: `+0.001s` (1ms).
- **Rule**: The Anki export timestamp SHALL be `primary_line.start_time + 0.001`.

#### Scenario: Exporting from start of segment
- **WHEN** a subtitle starts at `00:01:05.100`.
- **THEN** the exported TSV timestamp SHALL be `00:01:05.101`.

### Requirement: Index-Bounded Highlight Verification
The highlight engine SHALL use the coordinate map to perform strict existence checks during render.
- **Grounded Highlighting**: When `anki_global_highlight` is disabled, the engine SHALL only highlight tokens whose logical position matches the stored mapping.
- **Segment Drift Tolerance**: The system SHALL allow a `+/- 1` subtitle segment drift when resolving origin lines to account for temporal epsilon boundaries (`+1ms`).

#### Scenario: Filtering identical words
- **WHEN** a record points to line 10, word 5.
- **THEN** the engine SHALL NOT highlight word 5 on line 11, even if the text is identical.

### Requirement: Logical Hit-Test Snapping
The hit-testing engine SHALL implement logical token snapping for all mouse and keyboard interactions.
- **Visual-to-Logical Mapping**: Clicks, drags, or arrow navigation landing on or targeting tokens SHALL be identified by their unique logical index.
- **Margin Snap**: Mouse coordinates outside the active text block (line gaps or margins) SHALL be clamped to the first/last logical word of the nearest visible subtitle line.
- **Keyboard Precision**: Keyboard navigation SHALL skip non-word tokens (spaces, punctuation) unless explicitly using sub-word navigation modes.
- **Precision**: The system SHALL use a 0.0001 epsilon for all logical index comparisons to ensure stability across floating-point coordinates.

#### Scenario: Snapping keyboard cursor across spacers
- **WHEN** the user is focused on word 1 and presses the RIGHT arrow.
- **AND** word 1 and word 2 are separated by multiple spaces or punctuation tokens.
- **THEN** `FSM.DW_CURSOR_WORD` SHALL jump directly to 2, skipping all fractional logical indices.
