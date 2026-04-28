## MODIFIED Requirements

### Requirement: Non-Contiguous Term Context Anchor (Sequential Forward Search)
When the composed term cannot be found verbatim in the context block (due to non-contiguous selection or cross-line boundaries), the context extraction system SHALL find the occurrences of each word in the term in their natural document order.

#### Scenario: Non-contiguous term spanning sentence boundaries
- **WHEN** `extract_anki_context` is called with a term containing multiple segments (e.g. `"she's ... six ... four"`)
- **THEN** the system SHALL anchor the search using the first word closest to the pivot center
- **AND** search for all subsequent words strictly forward from the previous match's end position
- **AND** use the absolute character offsets of the first and last matches (relative to the source line) to map the span into word indices.

### Requirement: Sentence Scoping via Subtitle Boundaries
The sentence extraction phase of `extract_anki_context` SHALL use NUL sentinel characters (`\0`) embedded in the context string to locate the subtitle line containing the selection, and SHALL NOT scan for period characters to determine sentence start or end.

#### Scenario: Sentence scoping from sentinel-delimited context
- **WHEN** `extract_anki_context` receives a context string with `\0`-delimited subtitle segments and a character offset (`start_pos`) within that string
- **THEN** the system SHALL search backwards from `start_pos` for the nearest `\0` to find the start of the containing subtitle
- **AND** search forwards from `end_pos` for the nearest `\0` (or string end) to find the end of the containing subtitle
- **AND** use the text between those two positions as the primary sentence for word-count evaluation

#### Scenario: Backwards scan no longer uses period characters
- **WHEN** the context string contains `"Es liegt ca.\097 km"` (NUL between subtitle lines) and the selection anchors to `"97"`
- **THEN** the backwards scan SHALL stop at the `\0` sentinel, not at `"ca."`
- **AND** the returned primary sentence SHALL be `"97 km"` (the subtitle containing the selection), not a fragment starting after `"ca."`
