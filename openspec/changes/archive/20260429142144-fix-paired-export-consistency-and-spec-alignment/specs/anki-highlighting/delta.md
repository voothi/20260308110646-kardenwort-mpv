# Delta: anki-highlighting

## MODIFIED Requirements

### Requirement: Sentence-Aware Context Extraction
**Reason**: To prevent abbreviation-related truncation bugs (e.g. "ca.", "z.B.") which are prevalent in German subtitles.
**Change**: Redefine sentence boundaries to align with literal subtitle segment edges rather than punctuation marks.

#### Scenario: Subtitle boundary as sentence anchor
- **WHEN** a term is selected across one or more subtitle segments
- **THEN** the context extraction SHALL use the start of the first segment and the end of the last segment (plus any defined line buffers) as the authoritative sentence viewport.
- **AND** it SHALL NOT truncate the context based on internal punctuation within those segments.
