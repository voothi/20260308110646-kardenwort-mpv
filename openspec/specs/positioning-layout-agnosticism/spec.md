# positioning-layout-agnosticism Specification

## Purpose
TBD - created by archiving change 20260310141127-release-v1-2-12. Update Purpose after archive.
## Requirements
### Requirement: Symmetrical Positional Keys
The system SHALL map subtitle positioning commands to equivalent physical keys across English and Russian keyboard layouts.

#### Scenario: Adjusting primary position in Russian layout
- **WHEN** the user presses the `к` or `е` keys
- **THEN** the system SHALL execute the `add sub-pos` command (equivalent to `r` and `t`).

#### Scenario: Adjusting secondary position in Russian layout
- **WHEN** the user presses the `К` or `Е` keys
- **THEN** the system SHALL execute the `add secondary-sub-pos` command (equivalent to `Shift+R` and `Shift+T`).

