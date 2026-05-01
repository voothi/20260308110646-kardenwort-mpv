# Specification: Drum Draw Cache

## Requirement: O(1) Redraw Performance
The system SHALL cache the final ASS string for Drum Mode rendering to avoid redundant re-formatting of complex multi-line OSD layers when the view state is static.

#### Scenario: Active subtitle unchanged between ticks
- **WHEN** `master_tick` calls `tick_drum` and the `center_idx`, selection state (anchor/cursor line+word), `DW_CTRL_PENDING_VERSION`, and highlight count have not changed since the last call
- **THEN** `draw_drum()` SHALL return the previously cached ASS string without re-running `calculate_osd_line_meta`, `populate_token_meta`, or `format_sub_wrapped`

#### Scenario: Active subtitle changes during playback
- **WHEN** the playback position crosses a subtitle boundary causing `center_idx` to change
- **THEN** `draw_drum()` SHALL invalidate the cache and perform a full rebuild

#### Scenario: Highlight added while Drum Mode is active
- **WHEN** the user adds a new Anki highlight via the export function
- **THEN** the cache SHALL be invalidated (because `#FSM.ANKI_HIGHLIGHTS` changed) and the next `draw_drum()` call SHALL rebuild the ASS string with the new highlight visible
