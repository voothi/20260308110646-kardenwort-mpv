## ADDED Requirements

### Requirement: Unified Mining Interaction (Mouse & Key)
The system SHALL support explicit key/button mapping for both toggle and commit actions via the `coordinated-input-system`.

#### Scenario: Unified pair toggle via configured key
- **WHEN** the user presses any key defined in `dw_key_pair` (e.g., `t`)
- **THEN** the word under the cursor SHALL be toggled in the `ctrl_pending_set`
- **AND** this SHALL work without holding the Ctrl key.

#### Scenario: Smart MMB/Key add for paired words
- **WHEN** the user presses a key defined in `dw_key_add` (e.g., `MBTN_MID` or `r`)
- **AND** the word under focus is already highlighted as part of a pending paired set (Pink)
- **THEN** the system SHALL automatically trigger a paired commit (`ctrl_commit_set`) for the entire set.
- **AND** this SHALL work without holding the Ctrl key.

#### Scenario: Smart MMB/Key add fallback for contiguous words
- **WHEN** the user presses a key defined in `dw_key_add`
- **AND** the word under focus is NOT part of a pending paired set
- **THEN** the system SHALL proceed with standard contiguous export (Single word or Red selection).
