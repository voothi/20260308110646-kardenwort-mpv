## MODIFIED Requirements

### Requirement: Drum Window Unified Styling
The Drum Window SHALL allow explicit control over its appearance (font name, size, weight/boldness, and background transparency) via script options, matching the parameters of other rendering modes (SRT, Drum, Tooltip).

#### Scenario: Background Opacity Alignment
- **WHEN** the `dw_bg_opacity` and `dw_text_opacity` configurations are adjusted
- **THEN** the system SHALL apply the corresponding Alpha values (`\4a` and `\1a`) to the Window's localized background boxes and text respectively.

#### Scenario: Visual Normalization
- **WHEN** the user configures `dw_font_size`, `dw_border_size`, or `dw_shadow_offset`
- **THEN** the Drum Window SHALL apply these precisely to the rendering block, allowing the user to visually normalize the monospace interface to match the proportional Drum Mode interface.

#### Scenario: Unified Font and Weight
- **WHEN** the user configures `dw_font_name` or `dw_font_bold`
### Requirement: Scroll-Aware Selection Continuity
The Drum Window SHALL ensure that any active text selection or word-highlight state is preserved and correctly synchronized when the viewport is scrolled using the mouse wheel.

#### Scenario: Wheel Scroll Selection Stability
- **WHEN** the user is actively dragging the mouse to select text (MBTN_LEFT down)
- **AND** the user scrolls the mouse wheel (WHEEL_UP or WHEEL_DOWN)
- **THEN** the system SHALL immediately update the selection range to include the word now under the mouse cursor at its new viewport position.
- **AND** the selection SHALL NOT be cleared or disrupted by the scroll event.

#### Scenario: Stationary Active Highlight
- **WHEN** the Drum Window is scrolled via mouse wheel while NOT dragging
- **THEN** the system SHALL maintain the highlight on the specific text index previously selected.
- **AND** the highlight SHALL NOT snap to the word currently under the mouse pointer.
- **AND** the cursor state (`FSM.DW_CURSOR_WORD`) SHALL NOT be reset to an invalid state.

### Requirement: Exclusive UI Visibility
The Drum Window SHALL maintain exclusive visibility over the active subtitle information, ensuring that native mpv subtitles do not overlap or leak through the UI regardless of media state changes or external property resets.

#### Scenario: Persistent Suppression During Track Selection
- **WHEN** the Drum Window is active (`FSM.DRUM_WINDOW ~= "OFF"`)
- **AND** a subtitle track change or media state update occurs (e.g., SID change)
- **THEN** the system SHALL immediately ensure and maintain that `sub-visibility` and `secondary-sub-visibility` are set to `false`.
- **AND** native subtitle rendering SHALL NOT be restored until the Drum Window is explicitly closed.
