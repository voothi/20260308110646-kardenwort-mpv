## ADDED Requirements

### Requirement: Alpha Context Synchronization
The rendering engine SHALL preserve global `bg_opacity` settings across all OSD layers by explicitly restoring the background alpha context after every surgical tag injection.

#### Scenario: Navigating with transparent background
- **WHEN** the `dw_bg_opacity` is set to a non-zero value (semi-transparent)
- **THEN** all rendered subtitle lines SHALL maintain their intended transparency even when containing high-intensity interactive highlights.
