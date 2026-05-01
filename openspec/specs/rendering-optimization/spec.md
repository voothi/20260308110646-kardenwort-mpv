# Specification: Rendering Optimization

## Requirement: O(1) Token-Level Memoization
The rendering pipeline SHALL memoize the results of expensive highlight-stack calculations at the token level to ensure O(1) performance during redraws of static subtitle lines.

#### Scenario: Rapid Redraw Performance
- **WHEN** the system redraws the same subtitle line multiple times (e.g., during cursor hover or small seeking adjustments)
- **THEN** the system SHALL skip `calculate_highlight_stack` for tokens with a valid memoized result
- **AND** CPU usage during high-frequency OSD updates SHALL be significantly reduced.

### Requirement: Pre-calculated Normalized Tokens
The tokenization engine SHALL pre-calculate and store normalized lowercase text for all word tokens during initial track load or subtitle entry processing.
- **Normalization**: The normalization MUST include case mapping and the removal of common punctuation/metadata brackets.

#### Scenario: Subtitle Loading
- **WHEN** a subtitle track is loaded or a new subtitle is encountered
- **THEN** every word token in that subtitle SHALL be assigned a `lower_clean` property
- **AND** subsequent highlight matching operations SHALL use this property instead of calling `utf8_to_lower` repeatedly.

### Requirement: IPairs-based Iteration
The system SHALL use `ipairs()` instead of `pairs()` for iterating over performance-critical tables (e.g., hit-zones, token lists) to ensure deterministic execution order and improved OSD rendering speed.

#### Scenario: Hit-zone Processing
- **WHEN** the user interacts with the OSD via mouse
- **THEN** the system SHALL iterate through the `hit_zones` table using `ipairs()` to ensure the correct layering of interactive elements.

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
