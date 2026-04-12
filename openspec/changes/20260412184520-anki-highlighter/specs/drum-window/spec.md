## ADDED Requirements

### Requirement: Drum Window Anki Export Activation
The Drum Window FSM mode SHALL listen to `MBTN_MID` to initiate the Anki TSV row export for the currently active Drag/Word selection.

#### Scenario: Triggering Export via Mouse
- **WHEN** the Drum Window mode is active and the user presses `MBTN_MID` over an active text selection
- **THEN** the core export mechanism is triggered with the indices of the selection passed to the exporter.
