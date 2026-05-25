## ADDED Requirements

### Requirement: Escaped Break-Marker Normalization
Before tokenization or render-path text preparation, subtitle text processing MUST normalize escaped inline break markers (`\N`, `\n`, `\h`) into canonical render-safe forms.

#### Scenario: Legacy escaped markers in subtitle payload
- **WHEN** a subtitle payload includes escaped break markers from legacy ASS-style serialization
- **THEN** `\N` and `\n` SHALL be interpreted as forced line boundaries
- **AND** `\h` SHALL be interpreted as a non-breaking spacing boundary equivalent for downstream text-prep.

### Requirement: Boundary-Trimmed Forced Line Breaks Across Modes
Forced line boundaries MUST be normalized without synthetic boundary padding so equivalent subtitle payloads produce consistent spacing in DW, DM, and tooltip text surfaces.

#### Scenario: Cross-mode spacing parity
- **WHEN** the same subtitle content is rendered through DW, DM, and tooltip preparation paths
- **THEN** whitespace immediately adjacent to forced line boundaries SHALL be normalized to prevent synthetic double spaces
- **AND** mode-specific rendering SHALL not introduce additional spacing drift at the break boundary.
