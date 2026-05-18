## ADDED Requirements

### Requirement: Layout-Independent Video Adjustments
Standard video adjustments (contrast, brightness, gamma, saturation) MUST be bound to layout-independent letter keys (`o`/`p`/`k`/`l` and their Russian layout counterparts `щ`/`з`/`л`/`д`) instead of raw digit keys. This ensures that these functions are accessible regardless of the active language layout, and frees up digit keys `1` through `8` for script-level configurable bindings (such as Text-to-Speech triggers).

#### Scenario: Adjusting Contrast Layout-Independently
- **WHEN** the user presses `o` (English layout) or `щ` (Russian layout)
- **THEN** the system MUST decrease contrast by 1.
- **AND** WHEN the user presses `O` (Shift+o) or `Щ` (Shift+щ)
- **THEN** the system MUST increase contrast by 1.
- **AND** raw digit keys `2`, `3`, `4`, `5` MUST NOT be hard-bound to video adjustments.
