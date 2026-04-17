## MODIFIED Requirements

### Requirement: Smart Punctuation Rendering
The Drum Mode display SHALL correctly render punctuation when `dw_original_spacing` is disabled.

#### Scenario: Rendering with unified smart joiner
- **WHEN** `dw_original_spacing` is OFF
- **THEN** the `draw_drum` logic SHALL use the central `compose_term_smart` service to reconstruct the visible subtitle lines.
- **AND** it SHALL correctly join punctuation tokens to their preceding word tokens according to the UPSR rules.
