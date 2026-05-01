## ADDED Requirements

### Requirement: Parameter-Driven Token Colorization
The `populate_token_meta` architectural service SHALL support parameter-driven colorization to allow different rendering contexts (Drum Window, Tooltip, Drum Mode, SRT Mode) to apply distinct selection palettes without logic duplication.

#### Scenario: Multi-Context Coloration
- **WHEN** any core rendering loop (`draw_dw_core`, `draw_dw_tooltip`, `draw_drum`) calls `populate_token_meta`
- **THEN** it SHALL pass context-specific highlight and control colors derived from the `Options` table.
- **AND** the resulting token metadata SHALL reflect these specific colors, ensuring that primary and secondary tracks can maintain independent luminance levels.

### Requirement: Unified Aesthetic Parity
The OSD rendering pipeline SHALL synchronize border and shadow properties across all modes to prevent "blooming" and ensure visual uniformity.

#### Scenario: Border/Shadow Synchronization
- **WHEN** rendering OSD blocks in any mode
- **THEN** the `\3c` (border color) and `\4c` (shadow color) tags SHALL be synchronized to the mode's background color.
- **AND** the `\3a` (border transparency) SHALL be synchronized to the `\4a` (shadow transparency) to prevent artificial font thickening.
