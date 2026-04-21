## MODIFIED Requirements

### Requirement: RMB Interaction & Tooltip Pinning
The system SHALL bind `MBTN_RIGHT` dynamically within the Drum Window to manage informational tooltips.
- **Interaction**: Single-click on a word SHALL pin/unpin the tooltip — **provided LMB is NOT currently held**.
- **Gesture Priority**: When LMB is physically held (`DW_LMB_DOWN == true`), RMB press SHALL be treated as the start of the RMB+LMB pink gesture instead, and the tooltip SHALL NOT be opened.
- **Isolation**: RMB interactions when used standalone MUST be isolated from the highlighting engine to prevent unwanted cursor changes during informational lookups.

#### Scenario: Tooltip Click Trigger (standalone RMB)
- **WHEN** in Drum Window Mode
- **AND** LMB is NOT physically held (`DW_LMB_DOWN == false`)
- **THEN** `MBTN_RIGHT` down SHALL dispatch drawing instructions to pin the tooltip
- **AND** this explicit binding SHALL automatically deactivate when Window mode drops

#### Scenario: Tooltip suppressed during LMB-hold gesture
- **WHEN** in Drum Window Mode
- **AND** LMB IS physically held (`DW_LMB_DOWN == true`)
- **AND** the user presses RMB
- **THEN** the tooltip SHALL NOT open
- **AND** `DW_RMB_DOWN` SHALL be set to `true` for gesture tracking
