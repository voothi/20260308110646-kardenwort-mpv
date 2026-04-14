## Requirements

### Requirement: Drum Window Observer Resilience
The system SHALL wrap all `mp.observe_property` callbacks that invoke `update_media_state` in `pcall` so that a Lua error inside that function does not cause mpv to silently drop the observer. If an observer error occurs, the error message SHALL be written via `print()` to ensure visibility in the terminal regardless of mpv's configured log level.

#### Scenario: Observer callback crashes during subtitle load
- **WHEN** `update_media_state` throws a Lua error while processing a track change
- **AND** the error occurs inside an `mp.observe_property` callback
- **THEN** the observer SHALL remain registered and continue firing on future property changes
- **AND** the error SHALL be printed to the terminal as `[LLS ERROR] ...`

### Requirement: Drum Window Force Refresh on Open
When transitioning from `OFF` to `DOCKED` state, the system SHALL call `load_anki_tsv(true)` before any state mutation, so that mid-session file deletions are reflected at the exact moment the user opens the window rather than waiting for the next periodic timer cycle.

#### Scenario: File deleted before opening Drum Window
- **WHEN** the `.tsv` file is deleted while mpv is running
- **AND** the user presses the Drum Window toggle before the 5-second timer fires
- **THEN** the window SHALL open with an empty highlights table
- **AND** no phantom highlights from the deleted file SHALL be visible

### Requirement: Drum Window Opens Without TSV
The Drum Window SHALL open and render subtitle content normally even when no `.tsv` record file exists. An absent TSV file results in an empty highlights table, which is a valid state. The system SHALL NOT block the window transition based on the size of the highlights table.

#### Scenario: No TSV file present
- **WHEN** no `.tsv` file exists for the current media
- **AND** the user presses the Drum Window toggle
- **THEN** the window SHALL open in `DOCKED` state
- **AND** subtitle lines SHALL render without any saved-word highlights
- **AND** all Drum Window key bindings SHALL be active and functional
