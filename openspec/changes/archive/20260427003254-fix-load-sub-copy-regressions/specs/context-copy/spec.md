## MODIFIED Requirements

### Requirement: Language-Aware Fallback
The single-item fallback (word/line) in the system (Drum Window and Global) must respect the selected language target.

#### Scenario: Copying Translation from Drum Window
- **WHEN** the cursor is on a line in the Drum Window, `COPY_MODE` is "B" (Russian), and `Ctrl+C` is pressed.
- **THEN** the clipboard must contain the Russian translation of that specific line instead of the source text.

#### Scenario: Copying Translation in Regular Mode
- **WHEN** the user is in Regular Mode (Drum Window OFF), `COPY_MODE` is "B" (Russian), and `Ctrl+c` is pressed.
- **THEN** the clipboard must contain the Russian translation for the current timestamp, extracted from the internal track table.

### Requirement: Unified Source Fallback
The system SHALL utilize the internal subtitle index as the primary source for standard copy operations, falling back to native properties only if internal data is unavailable.

#### Scenario: Copying with language filter
- **WHEN** the user has multiple tracks loaded and `COPY_MODE` is set to "B" (Russian).
- **AND** the user presses `Ctrl+c`.
- **THEN** the system SHALL extract the Russian translation line from the internal `Tracks.sec.subs` table if the primary track is English.
- **AND** native properties SHALL NOT be used if valid internal data exists for the target language.
