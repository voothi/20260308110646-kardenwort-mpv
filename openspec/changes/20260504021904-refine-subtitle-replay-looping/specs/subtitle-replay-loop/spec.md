## ADDED Requirements

### Requirement: Mode-Aware Replay Key
The system SHALL use the `s` / `ы` hotkey to control replay and looping behaviors, behaving differently depending on the `AUTOPAUSE` state.

#### Scenario: Pressing 's' in Autopause OFF mode
- **WHEN** the user presses 's' while Autopause is OFF
- **THEN** the system toggles persistent Loop Mode for the current subtitle

#### Scenario: Pressing 's' in Autopause ON mode
- **WHEN** the user presses 's' while Autopause is ON
- **THEN** the system schedules a one-shot replay of the current subtitle and does NOT toggle Loop Mode

### Requirement: Delayed Replay Trigger
The system SHALL NOT interrupt playback if the replay key is pressed in the middle of a subtitle. The backward seek MUST be deferred until playback reaches the end of the subtitle.

#### Scenario: Pressing 's' mid-subtitle
- **WHEN** the user presses 's' while playback is in the middle of a subtitle
- **THEN** playback continues uninterrupted until the subtitle's end boundary is reached, at which point the player seeks back to the start

#### Scenario: Pressing 's' at the end or while paused
- **WHEN** the user presses 's' while playback is paused at the end of a subtitle, or within 0.2s of the end boundary
- **THEN** the player seeks back to the start of the subtitle immediately

### Requirement: Ghosting-Resistant Sticky Hold
The system SHALL automatically defeat hardware keyboard ghosting that drops the Space bar signal when the `s` key is pressed.

#### Scenario: Pressing 's' while holding Space
- **WHEN** the user presses 's', and the Space key was either held down or released within the last 300ms
- **THEN** the system forcibly sets the internal Spacebar state to "HOLDING" to prevent erroneous autopauses at the end of the replay

### Requirement: Spacebar Loop Override
The system SHALL allow the user to break out of a persistent loop by holding the Space key.

#### Scenario: Holding Space during a loop
- **WHEN** the player reaches the end boundary of a persistent loop, and the user is holding the Space key
- **THEN** the system turns off Loop Mode, seeks back one final time, and continues playback into the next subtitle
