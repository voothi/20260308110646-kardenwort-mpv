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
