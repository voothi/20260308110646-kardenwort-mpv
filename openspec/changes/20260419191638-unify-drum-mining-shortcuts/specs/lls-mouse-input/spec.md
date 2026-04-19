## MODIFIED Requirements

### Requirement: Ctrl+LMB Gesture Routing
When `ctrl_held` is true, LMB press events SHALL be routed to the Ctrl-accumulator handler instead of the drag-selection handler.
Additionally, the system SHALL support explicit key/button mapping for the toggle action via the `dw_key_pair` list, which SHALL NOT require the Ctrl key.

#### Scenario: LMB with Ctrl held routes to accumulator
- **WHEN** the user presses LMB while `ctrl_held` is true
- **THEN** the word under the cursor SHALL be passed to the `ctrl_pending_set` toggle handler
- **AND** the drag-selection state machine SHALL NOT be entered

#### Scenario: Unified pair toggle via configured key
- **WHEN** the user presses any key defined in `dw_key_pair` (e.g., `t`)
- **THEN** the word under the cursor SHALL be toggled in the `ctrl_pending_set`
- **AND** this SHALL work without holding the Ctrl key.

### Requirement: Ctrl+MMB Gesture Routing
When `ctrl_held` is true, MMB press events SHALL be routed to the Ctrl-accumulator commit handler.
Additionally, the system SHALL support explicit key/button mapping for the commit action via the `dw_key_add` list, which SHALL automatically detect and commit paired sets if the word under focus is a member of said set.

#### Scenario: MMB with Ctrl held routes to commit handler
- **WHEN** the user presses MMB while `ctrl_held` is true
- **THEN** the system SHALL pass the event to the `ctrl-multiselect` commit handler
- **AND** the word under the cursor SHALL be evaluated for set membership before dispatching export

#### Scenario: Smart MMB/Key add for paired words
- **WHEN** the user presses a key defined in `dw_key_add` (e.g., `MBTN_MID` or `r`)
- **AND** the word under focus is already highlighted as part of a pending paired set (Pink)
- **THEN** the system SHALL automatically trigger a paired commit (`ctrl_commit_set`) for the entire set.
- **AND** this SHALL work without holding the Ctrl key.

#### Scenario: Smart MMB/Key add fallback for contiguous words
- **WHEN** the user presses a key defined in `dw_key_add`
- **AND** the word under focus is NOT part of a pending paired set
- **THEN** the system SHALL proceed with standard contiguous export (Single word or Red selection).
