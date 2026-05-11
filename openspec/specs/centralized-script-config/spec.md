# centralized-script-config Specification

## Purpose
TBD - created by archiving change 20260310120822-release-v1-2-10. Update Purpose after archive.
## Requirements
### Requirement: External Parameter Overrides
The system SHALL support the overriding of internal script parameters via the player's global `mpv.conf` file using the `mp.options` mechanism.

#### Scenario: Overriding secondary position
- **WHEN** the user adds `script-opts-append=kardenwort_core-sec_pos_bottom=85` to `mpv.conf`
- **THEN** the system SHALL use 85 as the bottom position for secondary subtitles.

### Requirement: Configuration Documentation
The configuration system SHALL provide cross-referencing documentation within `mpv.conf` to explain parameter dependencies.

#### Scenario: Warning about positional gaps
- **WHEN** a user inspects the `sec_pos_bottom` option in `mpv.conf`
- **THEN** they SHALL find a `[LINKED]` tag warning about the 5% gap required from the primary `sub-pos`.

