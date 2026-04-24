## ADDED Requirements

### Requirement: Unified ensure visible logic
The Drum Window SHALL implement a `dw_ensure_visible(line_idx, paged)` function that supports both incremental and jump-based scrolling.

#### Scenario: Manual Navigation (Pushed)
- **WHEN** `dw_ensure_visible` is called with `paged = false` and `line_idx` is outside the margin
- **THEN** the viewport center SHALL move incrementally to bring `line_idx` exactly into the margin zone.

#### Scenario: Playback Navigation (Paged)
- **WHEN** `dw_ensure_visible` is called with `paged = true` and `line_idx` hits the bottom margin
- **THEN** the viewport center SHALL jump forward such that `line_idx` becomes aligned with the top margin of the new view.

### Requirement: Configurable Context Margins
The system SHALL use `Options.dw_scrolloff` to determine the number of lines to keep as context at the top and bottom of the Drum Window during all automated scrolling operations.

#### Scenario: Margin Configuration
- **WHEN** `dw_scrolloff` is set to `5` in `mpv.conf`
- **THEN** both `paged` and `pushed` scrolling logic SHALL maintain a 5-line buffer from the viewport edges.

### Requirement: Cursor Highlight Persistence
The system SHALL ensure the yellow cursor focus remains visible when navigating with manual seek keys (`a`/`d`).

#### Scenario: Manual Seek Focus
- **WHEN** the user presses `d` in Book Mode
- **THEN** the playback SHALL seek to the next subtitle AND the yellow cursor highlight SHALL move to the first word of that new active subtitle.
