## ADDED Requirements

### Requirement: Synchronized Cache Flushing
The system SHALL increment version counters and reset result caches whenever a rendering-critical toggle (Drum Mode, Global Highlight) is triggered.

#### Scenario: Drum Mode Toggle Invalidation
- **WHEN** the user toggles Drum Mode via `cmd_toggle_drum`
- **THEN** the system SHALL call `flush_rendering_caches()` and the next frame SHALL be rendered from scratch.

### Requirement: Mode-Aware Result Caching
The `DRUM_DRAW_CACHE` SHALL include a sentinel for the current rendering mode (Drum vs SRT).

#### Scenario: Preventing Mode Bleed
- **WHEN** the user is in Drum Mode and then toggles to SRT Mode without moving the playhead
- **THEN** the system SHALL detect a mode mismatch in the `DRUM_DRAW_CACHE` and re-render the SRT view.

### Requirement: Reactive Configuration Updates
The system SHALL observe the `script-opts` property and invalidate caches upon modification.

#### Scenario: Real-time Font Size Update
- **WHEN** the user updates `dw_font_size` via `mpv.conf` or `script-opts` at runtime
- **THEN** the system SHALL increment `LAYOUT_VERSION` and re-calculate word-wrapping for all visible subtitles.
