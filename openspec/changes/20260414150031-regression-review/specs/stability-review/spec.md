# Spec: Stability & Error Handling

## ADDED Requirements

### Requirement: Graceful Recovery from Missing Storage
The script SHALL detect missing TSV files and attempt to stabilize the environment by creating a template file.

#### Scenario: File auto-creation
- **WHEN** `load_anki_tsv` is called and the file is missing
- **THEN** a new file with headers `Term\tSentence\tTime\n` is created
- **AND** the internal highlight cache is cleared to prevent stale data.

### Requirement: Protected UI Toggling
The Drum Window toggle SHOULD NOT crash the entire script or primary OSD if a sub-function fails.

#### Scenario: Handled error in toggle
- **WHEN** `cmd_toggle_drum_window` encounters a Lua error
- **THEN** it displays an OSD error "LLS ERROR: Check console"
- **AND** prints a detailed error message with a traceback.

### Requirement: Observable Continuity
Subtitle and dimension changes SHALL NOT be interrupted by individual observer failures.

#### Scenario: Track list change error
- **WHEN** `update_media_state` fails during a track change
- **THEN** the error is logged but the script continues to respond to other events (e.g. keybinds).
