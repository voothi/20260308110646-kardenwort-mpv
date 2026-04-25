## ADDED Requirements

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

### Requirement: Precision-Aware Active Highlighting
The system SHALL ensure that the "active" subtitle (highlighted in white) remains consistently highlighted even during precise navigation or seek operations where the player position might land slightly before the official start time.

#### Scenario: Seeking to Subtitle Start
- **WHEN** the user seeks to a subtitle's start time using 'a' or 'd'
- **THEN** the subtitle SHALL be highlighted in its active state (white) immediately, even if the landing time is slightly outside the nominal range.

#### Scenario: Active Line Consistency
- **WHEN** in Standard or Drum (C) modes
- **THEN** the subtitle rendering SHALL follow the same highlighting logic as the Drum Window (Mode W), ensuring that the "focused" subtitle (returned by the centering logic) is always rendered in its active state.

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
- **GIVEN** Secondary Sub Pos is toggled to "BOTTOM"
- **THEN** the system SHALL use a default position that avoids immediate overlap with the primary track.

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
