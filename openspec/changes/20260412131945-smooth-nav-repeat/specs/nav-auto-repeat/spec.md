# Spec: Navigation Auto-Repeat

## ADDED Requirements

### Requirement: Global Subtitle Repeat
The system SHALL provide a unified auto-repeat mechanism for subtitle navigation keys (`a`, `d`, `ф`, `в`) that is independent of OS keyboard settings.

#### Scenario: Holding navigation key triggers repeat
- **WHEN** the user holds down the `d` key
- **THEN** after a 500ms delay, the system SHALL begin seeking to the next subtitle repeatedly at a rate of 10 times per second until the key is released.

### Requirement: Configurable Repeat Parameters
The system SHALL expose controls for the repeat delay and repetition rate via script options.

#### Scenario: User changes repeat speed
- **WHEN** the user sets `lls-seek_hold_rate=20` in their `mpv.conf`
- **THEN** the system SHALL repeat the navigation at 20 times per second.

### Requirement: Mode Consistency
The auto-repeat mechanism SHALL behave identically regardless of whether the player is in Normal Mode, Drum Mode (`c`), or Drum Window Mode (`w`).

#### Scenario: Repeating in Drum Mode
- **WHEN** Drum Mode is ON and the user holds `a`
- **THEN** the context "drum" SHALL scroll backward smoothly across multiple subtitle lines.
