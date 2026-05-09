# Delta Specification: karaoke-autopause

## ADDED Requirements

### Requirement: Manual Navigation Suppression
The autopause mechanism MUST NOT interrupt playback when the user is actively navigating via subtitle-relative seek commands.

#### Scenario: Rewind during Autopause ON
- **WHEN** `FSM.AUTOPAUSE == "ON"`.
- **AND** The user invokes `Shift+a` or `Shift+d`.
- **THEN** The `tick_autopause` loop MUST return immediately without pausing, regardless of playhead position relative to subtitle boundaries.
- **AND** The inhibition MUST remain active until the seek command completes and the `nav_cooldown` period expires.
