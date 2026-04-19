## MODIFIED Requirements

### Requirement: Specialized Input States (SEARCH_MODE & COPY_MODE)
The system configuration explicitly tracks modal interfaces that hijack default keyboard bindings. These states ensure that user input is correctly routed to transient UI components without triggering core media playback or navigation actions.

#### Scenario: Search Mode Hijack
- **WHEN** `FSM.SEARCH_MODE == true`
- **THEN** it SHALL instantiate a dedicated input grabber, routing all character keystrokes away from native bindings into the Search Query buffer (`FSM.SEARCH_QUERY`).
- **AND** the system SHALL render the `search_osd` overlay according to the visualization rules defined in the `search-system` spec.
