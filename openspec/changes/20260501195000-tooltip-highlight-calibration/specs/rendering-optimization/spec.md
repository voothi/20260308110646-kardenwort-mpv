## ADDED Requirements

### Requirement: Parameter-Driven Token Colorization
The `populate_token_meta` architectural service SHALL support parameter-driven colorization to allow different rendering contexts (Drum Window, Tooltip, Drum Mode, SRT Mode) to apply distinct selection palettes without logic duplication.

#### Scenario: Multi-Context Coloration
- **WHEN** any core rendering loop (`draw_dw_core`, `draw_dw_tooltip`, `draw_drum`) calls `populate_token_meta`
- **THEN** it SHALL pass context-specific highlight and control colors derived from the `Options` table.
- **AND** the resulting token metadata SHALL reflect these specific colors, ensuring that primary and secondary tracks can maintain independent luminance levels.
