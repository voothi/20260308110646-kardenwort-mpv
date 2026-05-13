## ADDED Requirements

### Requirement: Regression Coverage for DW Cache-Shape Compatibility
Acceptance testing SHALL include a regression scenario that exercises reduced subtitle layout cache entries before DW draw rendering.

#### Scenario: Reduced cache entry does not crash draw path
- **WHEN** navigation code populates a reduced `layout_cache.entry` and `dw_build_layout` is executed afterwards
- **THEN** rendering SHALL complete without `master_tick crash`
- **AND** logs SHALL NOT contain nil failures for `entry` indexing or `height` arithmetic.

### Requirement: Regression Coverage for Zero-Scrolloff Stability
Acceptance testing SHALL include a stability scenario for zero-margin scrolling in compact viewports.

#### Scenario: Zero-margin scroll remains stable
- **WHEN** `dw_scrolloff=0` and `drum_scrolloff=0` are applied in tiny viewports
- **THEN** repeated scroll commands SHALL keep `DW_VIEW_CENTER` in valid bounds
- **AND** logs SHALL NOT contain `master_tick crash` signatures.
