## ADDED Requirements

### Requirement: Robust Karaoke Merging
The system SHALL correctly merge identical subtitle text fragments (karaoke tokens) into a single dialogue block, even when they are separated by interleaved translation tracks, across all supported file formats (ASS and SRT).

#### Scenario: Merging interleaved karaoke
- **WHEN** loading any supported subtitle file (ASS or SRT) with alternating tracks.
- **THEN** identical raw text entries found within a 10-entry backward window SHALL be merged into one.

### Requirement: Language-Aware Context Fetching
The system SHALL filter subtitle tracks based on language characteristics when gathering conversational context for export.

#### Scenario: Filtering by character set
- **WHEN** fetching surrounding context for an English track
- **THEN** the system SHALL skip lines containing Cyrillic characters if they do not match the target language.

### Requirement: Context Quota Satisfaction
The system SHALL continue searching the subtitle array until the specified number of unique context lines is gathered.

#### Scenario: Satisfying line count
- **WHEN** the user requests 2 lines of context
- **THEN** the system SHALL continue its search beyond adjacent entries if those entries are merged or filtered.

### Requirement: Selection Priority in Context Copy
The system SHALL prioritize manual selections over context-aware text harvesting when `COPY_CONTEXT` is enabled, following a strict multi-tier hierarchy:
1. **Pink Set** (Multi-word non-contiguous selection)
2. **Yellow Range** (Contiguous word range selection)
3. **Yellow Pointer** (Single word pointer selection)

#### Scenario: Copying with Pink Set and context ON
- **WHEN** the user has selected multiple non-contiguous words (Pink highlights) in the Drum Window.
- **AND** `COPY_CONTEXT` is "ON".
- **AND** the user triggers the copy command.
- **THEN** only the words in the Pink Set SHALL be copied to the clipboard.

#### Scenario: Copying with active pointer and context ON
- **WHEN** the user has a "yellow cursor" (word pointer) on a specific word in the Drum Window.
- **AND** `COPY_CONTEXT` is "ON".
- **AND** the user triggers the copy command.
- **THEN** only the highlighted word SHALL be copied to the clipboard.

#### Scenario: Copying with active range and context ON
- **WHEN** the user has selected a range of words in the Drum Window.
- **AND** `COPY_CONTEXT` is "ON".
- **AND** the user triggers the copy command.
- **THEN** only the selected range SHALL be copied to the clipboard.

#### Scenario: Regulating Context Copy via Esc
- **WHEN** the user has multiple levels of selection (e.g., Pink Set and Yellow Pointer) and `COPY_CONTEXT` is "ON".
- **AND** the user presses `Esc` sequentially to clear selection stages.
- **AND** the user triggers the copy command at any stage.
- **THEN** the system SHALL copy the highest remaining selection tier, or fall back to harvesting the surrounding dialogue context if no selection remains.

### Requirement: Formatting Preservation (Copy As Is)
The system SHALL preserve all textual formatting markers, including brackets and internal punctuation, during all copy operations to satisfy "Copy as is" requirements.

#### Scenario: Preserving brackets in capture
- **WHEN** copying a line containing metadata markers (e.g., `[räuspern]`)
- **THEN** the resulting clipboard text SHALL include those markers intact.

### Requirement: Language-Aware Fallback
The single-item fallback (word/line) in the system (Drum Window and Global) must respect the selected language target.

#### Scenario: Copying Translation from Drum Window
- **WHEN** the cursor is on a line in the Drum Window, `COPY_MODE` is "B" (Russian), and `Ctrl+C` is pressed.
- **THEN** the clipboard must contain the Russian translation of that specific line instead of the source text.

#### Scenario: Copying Translation in Regular Mode
- **WHEN** the user is in Regular Mode (Drum Window OFF), `COPY_MODE` is "B" (Russian), and `Ctrl+c` is pressed.
- **THEN** the clipboard must contain the Russian translation for the current timestamp, extracted from the internal track table.

### Requirement: OSD-Independent Clipboard Extraction
The system SHALL ensure that global copy operations correctly retrieve subtitle text even when native `mpv` subtitle visibility is disabled for custom OSD rendering.

#### Scenario: Copying in White Subtitles Mode
- **WHEN** the user is in "Regular Mode" (Drum Window OFF) with OSD rendering for SRT enabled.
- **AND** the user presses `Ctrl+c` while `COPY_CONTEXT` is "OFF".
- **THEN** the system SHALL correctly identify the current subtitle from the internal track table and copy it to the clipboard.

### Requirement: Unified Source Fallback
The system SHALL utilize the internal subtitle index as the primary source for standard copy operations, falling back to native properties only if internal data is unavailable.

#### Scenario: Copying with language filter
- **WHEN** the user has multiple tracks loaded and `COPY_MODE` is set to "B" (Russian).
- **AND** the user presses `Ctrl+c`.
- **THEN** the system SHALL extract the Russian translation line from the internal `Tracks.sec.subs` table if the primary track is English.
- **AND** native properties SHALL NOT be used if valid internal data exists for the target language.
