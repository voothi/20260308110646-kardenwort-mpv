## ADDED Requirements

### Requirement: Drum Window Anki Export Activation
The Drum Window FSM mode SHALL listen to `MBTN_MID` to initiate the Anki TSV row export for the currently active Drag/Word selection.

#### Scenario: Triggering Export via Mouse
- **WHEN** the Drum Window mode is active and the user presses `MBTN_MID` over an active text selection
- **THEN** the core export mechanism is triggered and any active tooltips for that line are suppressed to prevent visual overlap.

### Requirement: Contextual Range Expansion
The Drum Window SHALL allow capturing context from a configurable number of surrounding lines (`anki_context_lines`) when mining.

#### Scenario: Multi-line mining
- **WHEN** the user exports a single word
- **THEN** the system gathers `N` subtitle lines before and after the active line to provide a rich context for the Anki card.
