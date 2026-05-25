## ADDED Requirements

### Requirement: Shared Tooltip Surface Parity
The tooltip renderer SHALL present the same visual surface contract in Drum Window, Drum Mode, and styled SRT activation paths unless the user explicitly configures a different tooltip policy.

#### Scenario: DM tooltip matches DW card style
- **GIVEN** global `osd-border-style` is `background-box`
- **AND** the tooltip is rendered while Drum Mode is active and Drum Window is closed
- **WHEN** the tooltip ASS is generated
- **THEN** the tooltip SHALL render as one measured vector card using the configured tooltip background, border, shadow, font, opacity, and highlight settings
- **AND** it SHALL NOT add separate native dark background boxes behind individual tooltip text lines.

#### Scenario: DW remains visual baseline
- **GIVEN** the same target subtitle and secondary tooltip content are available in Drum Window and Drum Mode
- **WHEN** the tooltip is rendered in both modes
- **THEN** the card/background/text style contract SHALL be equivalent across modes
- **AND** mode-specific differences SHALL be limited to target line anchoring and hit-zone source, not tooltip visual styling.

### Requirement: Tooltip Style Construction Isolation
Tooltip ASS event construction SHALL be centralized so card and text style tags are built through a shared tooltip style path instead of ad hoc mode-local string fragments.

#### Scenario: Native box neutralization cannot be overwritten
- **GIVEN** the tooltip style path decides to neutralize native background boxes in-band
- **WHEN** it emits text ASS for a tooltip line
- **THEN** the neutralization tags SHALL be applied after any tooltip text tags that could otherwise re-enable native background-box painting
- **AND** later tooltip formatting SHALL NOT override the neutralization within the same text event.

#### Scenario: Existing behavior is preserved outside style
- **WHEN** the shared tooltip style path is used
- **THEN** tooltip wrapping, context slot preservation, hit-zone generation, secondary subtitle fallback, and cache invalidation SHALL retain their existing behavior.
