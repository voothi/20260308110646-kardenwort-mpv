## MODIFIED Requirements

### Requirement: MMB Release-to-Export
Upon release of the MMB, the active selection SHALL be automatically committed to Anki and transitioned to long-term storage highlighting, provided the selection contains valid text content.
- **Content Validation**: The engine MUST verify that the term contains at least one non-tag, non-whitespace character before proceeding to export.
- **Saved Colors**:
    - **Orange**: Applied if the selection is contiguous (Standard).
    - **Purple**: Applied if the engine identifies the term as a "Split" phrase (fragmented).
- **Selection Protection**: If `FSM.DW_PROTECTED_SELECTION` is true, the export engine SHALL ignore subsequent mouse movement during the click and use the pre-existing anchor and cursor boundaries for the commitment.

#### Scenario: Auto-export on release
- **WHEN** the user releases MMB after selecting a phrase.
- **THEN** the phrase SHALL be saved to Anki.
- **AND** the highlight SHALL immediately transition from Gold to Orange (or Purple).

#### Scenario: Preserving Selection on Click
- **WHEN** a multi-word selection is already active.
- **AND** the user clicks MMB *inside* that selection.
- **THEN** the system SHALL enter the "Protected Selection" state.
- **AND** upon release, the entire original selection SHALL be exported, preventing it from collapsing to a single word.

#### Scenario: Clicking on empty space (No Export)
- **WHEN** the user middle-clicks on a line containing only tags or spaces.
- **THEN** the system SHALL detect that the resulting term is empty.
- **AND** no export operation SHALL be initiated.
- **AND** the system SHALL remain responsive.
