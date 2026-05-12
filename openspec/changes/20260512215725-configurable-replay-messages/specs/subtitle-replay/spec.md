## MODIFIED Requirements

### 4. User Experience (OSD)
- **REQ-4.1**: OSD feedback SHALL be configurable via templates provided in the `Options` table.
- **REQ-4.2**: The script SHALL support separate templates for Autopause ON (`replay_on_msg_format`) and Autopause OFF (`replay_msg_format`).

#### Scenario: Configurable Replay OSD
- **WHEN** the `s` key is pressed
- **THEN** the script SHALL evaluate the appropriate template based on `FSM.AUTOPAUSE` state.
- **AND** the script SHALL substitute placeholders `%m`, `%c`, and `%x` with their corresponding dynamic values.
