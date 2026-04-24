## ADDED Requirements

### Requirement: Robust Karaoke Merging
The system SHALL correctly merge identical subtitle text fragments (karaoke tokens) into a single dialogue block, even when they are separated by interleaved translation tracks.

#### Scenario: Merging interleaved karaoke
- **WHEN** loading a subtitle file with alternating English and Russian tracks
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

### Requirement: Contextual Drum Copy
The Drum Window copy command (`Ctrl+C`) must support context-aware extraction when enabled.

#### Scenario: Verbatim Selection with Context
- **WHEN** a range of words is selected in the Drum Window and `COPY_CONTEXT` is "ON".
- **THEN** the clipboard must contain the selected text wrapped with `copy_context_lines` from the surrounding subtitle track.

### Requirement: Language-Aware Fallback
The single-item fallback (word/line) in the Drum Window must respect the selected language target.

#### Scenario: Copying Translation from Drum Window
- **WHEN** the cursor is on a line in the Drum Window, `COPY_MODE` is "B" (Russian), and `Ctrl+C` is pressed.
- **THEN** the clipboard must contain the Russian translation of that specific line instead of the source text.
