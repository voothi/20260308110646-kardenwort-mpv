## MODIFIED Requirements

### Requirement: External Parameter Overrides
The system SHALL support the overriding of internal script parameters via the player's global `mpv.conf` file using the `mp.options` mechanism.

#### Scenario: Overriding secondary position
- **WHEN** the user adds `script-opts-append=kardenwort-sec_pos_bottom=85` to `mpv.conf`
- **THEN** the system SHALL use 85 as the bottom position for secondary subtitles.
