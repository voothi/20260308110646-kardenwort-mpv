## ADDED Requirements

### Requirement: Cache-Backed Translation Context Fallback
When copying secondary subtitle contexts (for example, under Subtitle Mode B) and the secondary translation subtitle track is visually disabled (`Tracks.sec.path` is nil or empty), the copying and context harvesting engine SHALL leverage the preloaded in-memory translation cache (`FSM.DW_TOOLTIP_SEC_SUBS`) if available.

#### Scenario: Subtitle Mode B lookup context with disabled secondary track
- **WHEN** the secondary subtitle track is visually disabled (`Tracks.sec.path` is nil or empty)
- **AND** translation cache (`FSM.DW_TOOLTIP_SEC_SUBS`) is populated and has elements
- **AND** the user triggers copy context lookup (`Shift+c`) under Subtitle Mode B
- **THEN** the system SHALL parse the translation context from `FSM.DW_TOOLTIP_SEC_SUBS` and successfully copy the translation context to the clipboard

#### Scenario: Subtitle Mode B copy mode cycling with disabled secondary track
- **WHEN** the secondary subtitle track is visually disabled (`Tracks.sec.path` is nil or empty)
- **AND** translation cache (`FSM.DW_TOOLTIP_SEC_SUBS`) is populated
- **AND** the user triggers copy mode cycle (`Shift+q`)
- **THEN** the system SHALL allow cycling through copy modes (including Mode B) rather than displaying "Copy Mode: Fixed to Primary"
