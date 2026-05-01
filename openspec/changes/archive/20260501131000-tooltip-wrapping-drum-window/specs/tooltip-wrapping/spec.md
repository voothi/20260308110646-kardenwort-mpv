## ADDED Requirements

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

