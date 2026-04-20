## MODIFIED Requirements

### Requirement: MMB Release-to-Export
Upon release of the MMB, the active selection SHALL be automatically committed to Anki and transitioned to long-term storage highlighting.
- **Saved Colors**:
    - **Orange**: Applied if the selection is contiguous (Standard).
    - **Purple**: Applied if the engine identifies the term as a "Split" phrase (fragmented).
- **Selection Protection**: If `FSM.DW_PROTECTED_SELECTION` is true, the export engine SHALL ignore the Pointer Jump Sync logic during the release event and use the pre-existing anchor and cursor boundaries for the commitment.
- **State Reset**: The protection flag MUST be cleared after the export callback is initiated.

#### Scenario: Preserving Selection on Release
- **WHEN** a multi-word selection is already active.
- **AND** the user clicks MMB inside that selection and releases.
- **THEN** `FSM.DW_CURSOR_LINE/WORD` SHALL NOT be updated to the release point.
- **AND** the entire original selection SHALL be exported.
