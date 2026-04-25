## ADDED Requirements

### Requirement: Unified ensure visible logic
The Drum Window SHALL implement a `dw_ensure_visible(line_idx, paged)` function that supports both incremental and jump-based scrolling.

#### Scenario: Manual Navigation (Pushed)
- **WHEN** `dw_ensure_visible` is called with `paged = false` and `line_idx` is outside the margin
- **THEN** the viewport center SHALL move incrementally to bring `line_idx` exactly into the margin zone.

#### Scenario: Playback Navigation (Paged)
- **WHEN** `dw_ensure_visible` is called with `paged = true` and `line_idx` hits the bottom margin
- **THEN** the viewport center SHALL jump forward such that `line_idx` becomes aligned with the top margin (leaving `dw_scrolloff` lines above).

### Requirement: Configurable Context Margins
The system SHALL use `Options.dw_scrolloff` to determine the number of lines to keep as context at the top and bottom of the Drum Window during all automated scrolling operations.

#### Scenario: Margin Configuration
- **WHEN** `dw_scrolloff` is set to `5` in `mpv.conf`
- **THEN** both `paged` and `pushed` scrolling logic SHALL maintain a 5-line buffer from the viewport edges.

### Requirement: Independent Pointer and Selection States
The Drum Window SHALL maintain separate states for the active video subtitle (white) and the manual navigation cursor (yellow) to allow for decoupled reading and seeking.

#### Scenario: Manual Seek in Book Mode
- **WHEN** the user presses `a` or `d` in Book Mode
- **THEN** the video SHALL seek AND the white active highlight SHALL move AND the yellow cursor highlight SHALL NOT be updated (maintaining its current position).

#### Scenario: Selection Dismissal on Manual Seek
- **WHEN** the user starts manual seeking via `a`/`d` in Book Mode OFF
- **THEN** any active yellow word-focus (`DW_CURSOR_WORD`) SHALL be dismissed (`-1`).

#### Scenario: Automatic Selection Cleanup (Regular Mode)
- **WHEN** the system is in Book Mode OFF and the playback moves to a new subtitle
- **THEN** the yellow line highlight SHALL follow the player AND the yellow word-focus SHALL be reset to `-1`.

### Requirement: High-Performance Navigation
### Historical Regression Context

This implementation reconciles several critical project states to prevent known regressions:

- **Commit `af9c776` Alignment**: Restored the edge-aware "Paged" jump targeting. When playing, the system jumps so the active line is at the top margin, maximizing visible upcoming context.
- **Commit `d264b61` Alignment**: Restored independent cursor behavior.
  - In Book Mode, manual seeking (`a`/`d`) moves only the video focus (white).
  - In Regular Mode, selection follows player but word-focus resets on every line change to prevent "phantom" yellow highlights.
- **Commit `38d2f94` Regression Fix**: Resolved responsiveness issues where `a`/`d` were blocked by conflicting repeat timers.

#### Scenario: Virtual Seek Target
- **WHEN** the user holds `d` for rapid seeking
- **THEN** the system SHALL calculate the next seek target based on a virtual `DW_SEEK_TARGET` to bypass engine latency.
