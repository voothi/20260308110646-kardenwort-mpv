## ADDED Requirements

### Requirement: Dynamic Traversal Quota Satisfaction
The system SHALL satisfy the requested context line quota by dynamically traversing the subtitle array and skipping filtered (foreign-language) tracks.

#### Scenario: Gathering 2 previous sentences
- **WHEN** the user requests 2 previous context sentences in an interleaved dual-track file
- **THEN** the system SHALL continue searching backwards beyond adjacent tracks until precisely 2 valid (native-language) strings are identified.

### Requirement: Center Pivot Language Snapping
The system SHALL ensure the center pivot index for context extraction is snapped to the targeted native-language track when multiple tracks share a timestamp.

#### Scenario: Pivot lands on translation
- **WHEN** `get_center_index` pivots on a filtered foreign-language track
- **THEN** the system SHALL immediately snap the pivot to the corresponding native-language track sharing the same timestamp.

### Requirement: Clipboard Pipeline Optimization
The system SHALL use the `is_context` flag to bypass redundant parsing overhead during clipboard extraction.

#### Scenario: Optimized extraction
- **WHEN** extracting context to the clipboard
- **THEN** the system SHALL utilize the `is_context` shortcut to reduce processing cycles.
