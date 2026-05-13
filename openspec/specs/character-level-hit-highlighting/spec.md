## ADDED Requirements

### Requirement: Precise Fuzzy Index Identification
The search engine SHALL identify every individual character index that contributes to a fuzzy match to allow for precise visual highlighting.

#### Scenario: Highlighting non-contiguous matches
- **WHEN** the user searches for "mne" and the result is "manage"
- **THEN** the system SHALL store indices [1, 3, 6] for highlighting.

### Requirement: Index-Based OSD Tagging
The system SHALL iteratively apply style tags to search results based on the identified match indices.

#### Scenario: Rendering highlighted text
- **WHEN** the OSD renders a search result
- **THEN** every character at a stored index SHALL be wrapped in bold (`\b1`) and high-contrast color tags.

### Requirement: Search Result Highlight Payload Integrity
The search pipeline SHALL preserve character-level highlight metadata from scoring through dropdown rendering without lossy conversion.

#### Scenario: Score-to-Render data handoff
- **WHEN** search scoring computes match indices for a subtitle result
- **THEN** the result object in `SEARCH_RESULTS` SHALL retain the highlight payload (`hl`) together with `idx`
- **AND** render logic SHALL be able to resolve `hl[char_index] == true` for every matched character position.
