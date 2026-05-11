## Purpose
Define deterministic subtitle rendering behavior across SRT, Drum, and Drum Window tooltip paths, including visibility control, wrapping, hit-testing, and pointer/highlight continuity.
## Requirements
### Requirement: Unified Mode Styling (SRT & Drum)
The system SHALL provide explicit, synchronized configuration parameters for font selection and weight across standard SRT and Drum (c) rendering modes.

#### Scenario: Customizing Fonts
- **WHEN** the user configures `srt_font_name` or `drum_font_name`
- **THEN** the respective rendering mode SHALL apply that font family to the OSD output.

#### Scenario: Font Strength/Boldness
- **WHEN** the `srt_font_bold` or `drum_font_bold` options are toggled
- **THEN** THE OSD SHALL apply the corresponding `\b1` or `\b0` ASS tags to the rendered subtitle text.

### Requirement: Dynamic Visibility Suppression
The system SHALL periodically suppress native mpv subtitles ONLY for tracks currently being rendered via a custom OSD-based subtitle mode (SRT-OSD, Drum Mode, or Drum Window).
- Native rendering SHALL be permitted to persist for ASS/SSA tracks even when OSD modes are active for other tracks, ensuring preservation of complex styling.
- All tracks SHALL be suppressed if the Drum Window is active to ensure a clean UI.

#### Scenario: Hybrid Rendering (SRT-OSD + Native ASS)
- **GIVEN** a primary SRT track using OSD styling and a secondary ASS track
- **WHEN** the system is in standard playback mode
- **THEN** the system SHALL force `sub-visibility` to `false` (SRT suppressed)
- **AND** it SHALL allow `secondary-sub-visibility` to match the user's preference (ASS displayed natively).

### Requirement: Logarithmic Centering Performance
The system SHALL ensure that subtitle centering logic (e.g., `get_center_index`) operates in logarithmic time ($O(\log N)$) relative to the total number of subtitles in the track.
- **Deduplication**: There SHALL be only a single, globally-accessible implementation of the centering logic to prevent shadowing or redundant linear evaluations.
- **Impact**: This ensures stable CPU usage and low latency even on extremely large subtitle tracks (>5000 lines).

#### Scenario: Large track centering remains performant
- **WHEN** subtitle centering is evaluated on a large track
- **THEN** the system SHALL resolve the active/center index using the shared logarithmic-time implementation
- **AND** it SHALL avoid redundant linear scans in parallel code paths.

### Requirement: Precision-Aware Active Highlighting
The system SHALL ensure that the "active" subtitle (highlighted in white) remains consistently highlighted even during precise navigation or seek operations where the player position might land slightly outside the nominal `[start_time, end_time]` range (e.g., in the temporal gap between two subtitles).
- **Nearest-Neighbor Grounding**: If the current player timestamp falls into a gap between two subtitles, the centering logic MUST identify and return the index of the subtitle whose temporal boundary (start or end) is nearest to the player position.
- **Visual Feedback**: This prevents the active highlight from "flickering" or disappearing during frame-by-frame navigation or precise seeking to subtitle boundaries.

#### Scenario: Seeking to Subtitle Start
- **WHEN** the user seeks to a subtitle's start time using 'a' or 'd'
- **THEN** the subtitle SHALL be highlighted in its active state (white) immediately, even if the landing time is slightly outside the nominal range.

#### Scenario: Active Line Consistency
- **WHEN** in Standard or Drum (C) modes
- **THEN** the subtitle rendering SHALL follow the same highlighting logic as the Drum Window (Mode W), ensuring that the "focused" subtitle (returned by the centering logic) is always rendered in its active state.

### Requirement: Universal Pointer Persistence
The system SHALL maintain the visibility and logical anchoring of the word pointer (Yellow Highlight) across all subtitle rendering modes, including windowless (SRT) playback.

#### Scenario: Pointer visibility in Regular SRT mode
- **WHEN** the Drum Window (Mode W) is OFF and Drum Mode (Mode C) is OFF (Regular SRT mode).
- **IF** `FSM.DW_CURSOR_WORD` is not -1.
- **THEN** the active primary subtitle SHALL render with a yellow highlight on the specified word.

### Requirement: Sliding-Window Boundary Filling
The system SHALL maintain a full range of visible context subtitles even when the active subtitle is near the start or end of the track, provided sufficient subtitles exist in the track.

#### Scenario: Reaching the end of the track
- **GIVEN** a subtitle track with 100 entries and a window size of 15 lines
- **WHEN** the logical center position is at index 100
- **THEN** the system SHALL display subtitle entries from index 86 to 100.
- **AND** the active subtitle (index 100) SHALL be positioned at the bottom of the rendered block.

#### Scenario: Reaching the start of the track
- **GIVEN** a subtitle track with 100 entries and a window size of 15 lines
- **WHEN** the logical center position is at index 1
- **THEN** the system SHALL display subtitle entries from index 1 to 15.
- **AND** the active subtitle (index 1) SHALL be positioned at the top of the rendered block.

#### Scenario: Visual Consistency during Seek/Scroll
- **WHEN** navigating near track boundaries using the mouse wheel or navigation keys ('a', 'd')
- **THEN** the total number of rendered lines SHALL remain constant (matching `dw_lines_visible` or `context_lines` * 2 + 1) to prevent vertical shifting of the OSD block on the screen.

### Requirement: Independent Manual Positioning for Multiple Tracks
The system SHALL respect the user's manual subtitle position adjustments even when multiple subtitle tracks are active in Drum Mode.

#### Scenario: Manual Adjustment via Hotkeys
- **GIVEN** Drum Mode C is active with two tracks (Primary and Secondary)
- **WHEN** the user presses `r`/`t` or `Shift+r`/`Shift+t` to adjust subtitle positions
- **THEN** both the primary and secondary OSD blocks SHALL move to the positions requested by the user.
- **AND** the script SHALL NOT automatically overwrite these positions in the rendering loop.

#### Scenario: Decoupled Track Stacking
- **THEN** the system SHALL use a default position that avoids immediate overlap with the primary track.

### Requirement: Safety-Aware Positioning
The subtitle rendering engine SHALL apply automatic offsets to the secondary subtitle track if its manual position would cause it to overlap with the primary track.

#### Scenario: Collision Prevention
- **GIVEN** Primary sub position is at 90 and Secondary sub position is at 80 (bottom half)
- **WHEN** Drum Mode or OSD rendering is active
- **THEN** The system SHALL calculate a safety offset based on the primary track's height and apply it to the secondary track to ensure legibility, while still allowing the user's relative adjustments (`r/t`) to be reflected.

### Requirement: Drum Window Selection Priority
The system SHALL prioritize the presentation of persistent multi-word selections (Ctrl + LMB) over transient cursor-based highlighting or drag-selection ranges in the Drum Window (Mode W).

#### Scenario: Selection Overlap
- **GIVEN** one or more words are already marked with `dw_ctrl_select_color` (muted yellow)
- **WHEN** the user hovers the mouse over one of these words or includes it in a standard selection range (LMB drag)
- **THEN** THE OSD SHALL continue to display the word using `dw_ctrl_select_color` instead of overriding it with `dw_highlight_color` (vibrant yellow).

### Requirement: Smart Punctuation Rendering
The Drum Mode display SHALL correctly render punctuation when `dw_original_spacing` is disabled.

#### Scenario: Rendering with unified smart joiner
- **WHEN** `dw_original_spacing` is OFF
- **THEN** the `draw_drum` logic SHALL use the central `compose_term_smart` service to reconstruct the visible subtitle lines.
- **AND** it SHALL correctly join punctuation tokens to their preceding word tokens according to the UPSR rules.

### Requirement: Character-Based Word Boundaries
All word-width calculations for hit-testing and selection highlights SHALL use character-aware iteration.

#### Scenario: Cyrillic Hit-Testing
- **GIVEN** A Russian word "Привет" (12 bytes, 6 characters)
- **WHEN** Calculating the width for selection zones
- **THEN** The system SHALL iterate exactly 6 times and apply width heuristics per character, ensuring the selection zone matches the visual glyphs.

### Requirement: Drum Mode Visibility Master
The Drum Mode (Mode C) toggle SHALL control the rendering style (single-line vs multi-line context), but SHALL respect the global subtitle visibility toggle (`s` key).

#### Scenario: Hiding Subtitles in Drum Mode
- **GIVEN** Drum Mode is toggled ON and subtitles are visible
- **WHEN** the user toggles native subtitle visibility OFF (using `s` or `ы`)
- **THEN** the custom OSD rendering SHALL immediately become invisible.

#### Scenario: Showing Subtitles in Drum Mode
- **GIVEN** Drum Mode is toggled ON and subtitles are hidden
- **WHEN** the user toggles native subtitle visibility ON (using `s` or `ы`)
- **THEN** the custom OSD rendering SHALL immediately become visible using Drum Mode styling.

#### Scenario: Visibility Toggle in Drum Window
- **GIVEN** the Drum Window (Mode W) is active
- **WHEN** the user presses `s` or `ы`
- **THEN** the system SHALL toggle the FSM visibility intent (`FSM.native_sub_vis` and `FSM.native_sec_sub_vis`)
- **AND** the Drum Window SHALL remain open and continue rendering its own OSD surface while active
- **AND** when the Drum Window is closed, native subtitle visibility restoration SHALL reflect the updated FSM intent.

### Requirement: Automatic Line Wrapping (SRT, Drum & Tooltip)
The OSD rendering engine SHALL automatically wrap subtitle lines that exceed the visual safe area into multiple vertical lines to prevent text from bleeding off the screen.
- For Primary (SRT & Drum) subtitles, the safe area is defined as 1860px.
- For Tooltip (Secondary) subtitles, the safe area is defined as 1400px.

#### Scenario: Long Sentence Wrapping
- **WHEN** a subtitle (Primary or Secondary Tooltip) contains a sentence longer than its respective safe area.
- **THEN** it SHALL be split into two or more visual lines.
- **AND** each visual line SHALL be aligned according to its mode's anchor (Center for Primary, Right for Tooltip).
- **AND** the system SHALL maintain accurate hit-testing (where applicable) for every word on every wrapped visual line.

#### Scenario: Empty Subtitle Slot Preservation
- **WHEN** a context subtitle entry has empty text (e.g., a gap-filler line)
- **THEN** the rendering engine SHALL still reserve a vertical slot equal to `(font_size * line_height_mul) + vsp` for that entry.
- **AND** the slot SHALL produce no visible ASS text output.
- **AND** the total OSD block height SHALL be consistent regardless of whether context subtitles are empty or not.

### Requirement: Inter-Subtitle Gap Calculation Source
The gap inserted between two adjacent rendered subtitles in the OSD block SHALL be calculated using the font size of the subtitle that **just finished rendering** (the previous one), not the subtitle about to be rendered next.

#### Scenario: Active-to-Context Transition
- **GIVEN** the active subtitle uses `drum_active_size_mul = 1.3` and context subtitles use `drum_context_size_mul = 1.0`
- **WHEN** the gap is calculated between the active subtitle (bottom) and the next context subtitle
- **THEN** `calculate_sub_gap` SHALL receive the **active** subtitle's effective font size (`font_size * 1.3`)
- **AND** the resulting gap height SHALL match the visual spacing produced by the ASS `\\vsp` separator tag.

#### Scenario: Context-to-Active Transition
- **GIVEN** the active subtitle uses `drum_active_size_mul = 1.3` and context subtitles use `drum_context_size_mul = 1.0`
- **WHEN** the gap is calculated between a context subtitle (above) and the active subtitle below it
- **THEN** `calculate_sub_gap` SHALL receive the **context** subtitle's effective font size (`font_size * 1.0`)
- **AND** the resulting gap height SHALL be smaller than the gap after the active line.

### Requirement: Forced Line Breaks
The rendering engine SHALL respect explicit newline characters (`\n`) in the source subtitle file as forced line breaks, regardless of current line width.

#### Scenario: Explicit newline is preserved
- **WHEN** a subtitle line contains an explicit `\n` in source text
- **THEN** the renderer SHALL preserve that explicit break as a forced visual line boundary
- **AND** it SHALL not collapse that break due to width heuristics.

### Requirement: Drum Primary Tooltip Rendering
Subtitle rendering SHALL support tooltip extraction from Drum Mode primary subtitle hit-zones on the bottom subtitle stream.

#### Scenario: Tooltip extraction from primary hit-zone
- **WHEN** a Drum tooltip action targets a word in the active primary subtitle line
- **THEN** the renderer SHALL map the pointer to the corresponding token
- **AND** it SHALL render tooltip text derived from that token via the tooltip overlay.

### Requirement: Visibility-Safe Tooltip Rendering
Drum Mode tooltip rendering SHALL obey effective subtitle visibility and media compatibility guards.

#### Scenario: Global subtitles disabled
- **WHEN** effective subtitle visibility is disabled by global toggle state
- **THEN** Drum tooltip overlay SHALL not render
- **AND** any existing tooltip overlay buffer SHALL be cleared.

#### Scenario: Secondary subtitle toggle does not suppress tooltip anchor 20260506200831
- **WHEN** the user toggles secondary subtitles via `Shift+C` so the secondary subtitle track becomes hidden or `OFF`
- **AND** Drum Mode primary subtitle tooltip rendering is otherwise eligible
- **THEN** the tooltip overlay SHALL remain available for primary subtitle interactions
- **AND** tooltip content resolution SHALL NOT depend on current secondary subtitle visibility state.

