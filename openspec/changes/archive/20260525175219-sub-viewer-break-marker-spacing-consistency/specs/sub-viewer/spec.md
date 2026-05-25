## ADDED Requirements

### Requirement: Reader Cue Serialization Uses Native SRT Line Breaks
The sub-viewer reader conversion pipeline MUST serialize wrapped cue text using native SRT newline characters and MUST NOT emit ASS break markers (`\N`) inside cue payload text.

#### Scenario: Single text input serialization
- **WHEN** a supported reader text file (`.txt`, `.md`, `.rst`, `.log`) is converted to a reader `.srt`
- **THEN** each wrapped cue payload SHALL contain literal line breaks where wrapping occurs
- **AND** cue payload text SHALL NOT contain serialized `\N` markers.

#### Scenario: Paired text input serialization
- **WHEN** two supported text files are converted via paired reader workflow
- **THEN** both generated primary and secondary `.srt` outputs SHALL use native SRT line breaks for wrapped cue payloads
- **AND** neither output SHALL contain serialized `\N` markers in cue payload text.

### Requirement: Reader Cue Spacing Integrity
Reader cue generation MUST preserve textual spacing fidelity around wrapped boundaries, avoiding synthetic double spaces created by marker conversion.

#### Scenario: Wrapped cue boundary spacing
- **WHEN** long lines are split into wrapped cue payload lines
- **THEN** each emitted payload line SHALL be boundary-trimmed without synthetic leading/trailing spaces caused by break-marker serialization
- **AND** hyphenated tokens (for example `high-bandwidth`, `data-center`, `дата-центров`) SHALL remain intact without injected interior spaces.
