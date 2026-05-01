# Delta: Drum Window (Tooltip Highlights)

## MODIFIED Requirements

### Requirement: Tooltip Content Rendering
The Drum Window translation tooltip SHALL render secondary subtitles with full highlight synchronization, mirroring the selection state of the primary track.

#### Scenario: Selection Sync in Tooltip
- **GIVEN** a word or range is highlighted in Yellow or Pink in the Drum Window.
- **WHEN** the tooltip (E) is displayed for the corresponding line.
- **THEN** the secondary tokens in the tooltip SHALL be rendered with the same colors and bold styling as their primary counterparts, provided they share the same logical index.
- **AND** the highlighting SHALL be "surgical," preserving the base color of punctuation and whitespace.
