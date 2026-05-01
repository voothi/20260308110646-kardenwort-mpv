## Purpose

Provides supplemental translation, dictionary, or context information for the currently active or selected subtitle within the Drum Window ('w').
## Requirements
### Requirement: Tooltip Styling Unification
The Tooltip system SHALL support the standard suite of visual parameters (font name, font size, bg opacity, text color, boldness, etc.) following the project's unified schema to ensure stylistic parity with the parent display.

#### Scenario: Stylistic Parity
- **WHEN** the user modifies `tooltip_bg_opacity`, `tooltip_font_size`, or `tooltip_font_name`
- **THEN** the tooltip rendering engine SHALL apply these values to the OSD overlay using standardized ASS tags, matching the visual weight and typography of the Drum Window and Drum Mode.

#### Scenario: Unified Boldness
- **WHEN** the `tooltip_font_bold` option is toggled
- **THEN** the tooltip text SHALL render with the corresponding boldness state, synchronized with the user's preference for the active display mode.

### Requirement: Keyboard Tooltip Toggling
The system SHALL provide configurable keyboard shortcuts (defined in `mpv.conf`) to toggle the visibility of the tooltip for the currently active subtitle. This functionality SHALL be restricted entirely to the Drum Window ('w') mode.

#### Scenario: Toggling the tooltip with 'e' key
- **WHEN** the user presses the assigned toggle key (e.g., 'e' or 'у') while the Drum Window ('w') is active and the tooltip is hidden
- **THEN** the tooltip for the active subtitle SHALL appear on the screen

#### Scenario: Hiding a visible tooltip with 'e' key
- **WHEN** the user presses the assigned toggle key while the Drum Window tooltip is currently visible (forced state)
- **THEN** the tooltip SHALL be hidden, regardless of whether the target subtitle line has changed since it was first displayed.

### Requirement: Dynamic Tooltip Positioning
When a tooltip is visible (toggled via keyboard or pinned via mouse), it SHALL dynamically update its vertical (OSD Y) position to remain centered relative to its associated subtitle line as the line moves during scrolling.

#### Scenario: Tooltip follows scrolling text
- **WHEN** a translation tooltip is visible for a specific subtitle line
- **AND** the user scrolls the Drum Window (e.g., via wheel, arrow keys, or playback)
- **THEN** the tooltip SHALL move vertically on the screen, maintaining its alignment with the horizontal centerline of the target subtitle line.

### Requirement: Context-Sensitive Tooltip Targeting
The toggled keyboard tooltip ('e') SHALL prioritize different text elements based on the player's playback state to ensure the most relevant information is displayed.

#### Scenario: Tooltip follows active subtitle during playback
- **GIVEN** the video is currently playing (not paused)
- **WHEN** the keyboard tooltip is toggled ON ('e')
- **THEN** the tooltip SHALL display information for the **currently playing subtitle** (white highlight)
- **AND** it SHALL dynamically update its content and position as the video advances to the next subtitle.

#### Scenario: Tooltip targets active subtitle on seek while paused
- **GIVEN** the video is currently paused
- **AND** the keyboard tooltip is toggled ON ('e')
- **WHEN** the user seeks to a different subtitle (e.g., via 'a' or 'd')
- **THEN** the tooltip SHALL switch to follow the **active subtitle** (white highlight) at its new position.

#### Scenario: Tooltip targets selection cursor on cursor move
- **GIVEN** the video is currently paused
- **AND** the keyboard tooltip is toggled ON ('e')
- **WHEN** the user moves the manual selection cursor (e.g., via arrows or LMB)
- **THEN** the tooltip SHALL switch to follow the **selection cursor** (yellow pointer).

#### Scenario: Tooltip suppressed when target is off-screen
- **GIVEN** the target subtitle (active or cursor) is currently scrolled off-screen
- **WHEN** the user toggles the keyboard tooltip ON ('e')
- **THEN** the tooltip SHALL NOT appear on screen
- **BUT** the system SHALL remember the forced state, so it appears automatically once the target line scrolls back into view.

### Requirement: RMB Interaction Preservation
The system SHALL preserve legacy Right Mouse Button (RMB) interaction patterns for tooltips.

#### Scenario: Tooltip remains visible and follows focus while RMB is held
- **GIVEN** the Drum Window tooltip is configured for `CLICK` mode
- **WHEN** the user presses and holds RMB and moves the mouse across multiple subtitle lines
- **THEN** the tooltip SHALL dynamically update to show information for the line currently under the mouse pointer.

#### Scenario: Tooltip dismisses when mouse focus leaves pinned line (CLICK Mode)
- **GIVEN** the Drum Window tooltip is in `CLICK` mode (no active keyboard force)
- **WHEN** the user right-clicks a line to pin the tooltip
- **AND** the user then moves the mouse focus to a different subtitle line
- **THEN** the pinned tooltip SHALL be dismissed.

### Requirement: Precision Centering and Interval Sync
When `tooltip_y_offset_lines = 0`, the tooltip's active line midpoint must align perfectly with the target OSD line midpoint.

#### Scenario: Alignment Calculation
- **GIVEN** a tooltip is displayed for a target line
- **WHEN** the tooltip renderer (`draw_dw_tooltip`) calculates vertical positioning
- **THEN** it SHALL use a `logical_interval` derived from `layout_line_h + (double_gap ? layout_line_h : 0) + block_gap`
- **AND** the final OSD Y coordinate SHALL be `target_osd_y + (offset * logical_interval)`.

#### Scenario: Visual Consistency
- **GIVEN** the Drum Window and Tooltip are both visible
- **WHEN** `line_height_mul` or `block_gap_mul` are modified
- **THEN** the context lines in the translation tooltip SHALL maintain identical visual spacing to the navigation window context lines.

### Requirement: Automatic Tooltip Line Wrapping
The Drum Window translation tooltip SHALL automatically wrap secondary subtitle lines that exceed a visual safe area to prevent text from bleeding off the screen.

#### Scenario: Long Translation Wrapping
- **WHEN** a secondary subtitle in the tooltip contains a sentence longer than the defined maximum width (1400px)
- **THEN** it SHALL be split into two or more visual lines within the subtitle block.
- **AND** the system SHALL maintain visual consistency with the main Drum Window wrapping heuristic.

### Requirement: Multi-Line Tooltip Height Calculation
The tooltip rendering engine SHALL calculate the total vertical height of the tooltip block based on the aggregate number of visual lines across all logical subtitle entries.

#### Scenario: Centering Multi-Line Tooltips
- **GIVEN** a tooltip containing multiple secondary subtitles, some of which are wrapped into multiple lines
- **WHEN** the system calculates the `block_height` for vertical centering
- **THEN** it SHALL sum the heights of every *visual line* (wrapped) and every *inter-subtitle gap* within the block.
- **AND** the final `osd_y` position SHALL ensure the entire multi-line block remains centered relative to the target primary subtitle line.

### Requirement: Tooltip Cache Synchronization
The tooltip rendering engine SHALL participate in the centralized cache invalidation system to prevent stale data display after track reloads or configuration updates.

#### Scenario: Flushing Tooltip Caches
- **WHEN** the `flush_rendering_caches()` function is executed
- **THEN** the tooltip OSD overlay SHALL be cleared (`data = ""`).
- **AND** the tooltip result cache SHALL be invalidated to force a full re-wrap on the next render request.

### Requirement: Verbatim Secondary Track Fidelity
The tooltip rendering engine SHALL preserve the raw, unnormalized content of secondary subtitles, adhering to the "Verbatim-first" architectural standard.

#### Scenario: Rendering Original Spacing
- **WHEN** a secondary subtitle is rendered in the tooltip
- **THEN** the system SHALL use `get_sub_tokens(s, true)` to ensure original spacing and punctuation are preserved during the wrapping process.
- **AND** no automated whitespace normalization or "cleaning" SHALL be applied to the tokens.

### Requirement: Oversized Token Handling
The wrapping engine SHALL gracefully handle individual tokens that exceed the maximum defined width.

#### Scenario: Single Token Wider Than Max Width
- **WHEN** a single word or token is wider than the 1400px limit
- **THEN** the system SHALL render the token in full on its own visual line.
- **AND** it SHALL force a line break immediately after the oversized token.

### Requirement: Anchor-Aligned Wrapping
Wrapped visual lines within a translation block SHALL maintain consistent alignment with the tooltip's global anchor.

#### Scenario: Right-Center Alignment Preservation
- **WHEN** a translation is wrapped into multiple visual lines
- **THEN** every visual line SHALL be right-aligned relative to the `x=1800` (`\an6`) anchor point.
- **AND** the visual block SHALL appear to "grow" leftwards from the right edge as line lengths increase.

### Requirement: Vertical Boundary Clamping
The tooltip system SHALL prevent multi-line subtitle blocks from extending beyond the physical screen boundaries.

#### Scenario: Vertical Overflow Protection
- **GIVEN** a tooltip containing multiple context lines or extremely long wrapped sentences
- **WHEN** the aggregate `block_height` exceeds the available vertical resolution (1080px minus 20px safety margins)
- **THEN** the system SHALL clamp the entire block to the top or bottom screen edge.
- **AND** the positioning logic SHALL ensure the "Active" (center) translation remains as visible as possible.

### Requirement: Context Slot Preservation
The tooltip rendering engine SHALL preserve visual slots for empty or metadata-only subtitles to maintain vertical synchronization with the primary Drum Window.

#### Scenario: Preserving Empty Logical Entries
- **WHEN** a logical subtitle in the context range contains no renderable text
- **THEN** it SHALL be rendered as a single empty visual line.
- **AND** the standard inter-subtitle gap SHALL be applied after the entry.
