# Specification: Subtitle Seek Navigation Repeat

## Purpose
Restore and maintain a reliable auto-repeat mechanism for subtitle navigation.

## Requirements

### ADDED Requirements

#### Requirement: Key-repeat for Subtitle Seeking
The system SHALL support continuous subtitle seeking when the seek keys (`a` and `d` or `ф` and `в`) are held down.

#### Scenario: Continuous seeking forward
- **WHEN** the `d` key is pressed and held in the Drum Window
- **THEN** the player SHALL seek to the next subtitle line immediately
- **AND** continue seeking to subsequent lines at a rate defined by `seek_hold_rate` after an initial `seek_hold_delay`.

#### Scenario: Stopping seek on key release
- **WHEN** the `d` key is released after being held
- **THEN** the continuous seeking SHALL stop immediately.

#### Scenario: Normal mode parity
- **WHEN** the Drum Window is closed (Normal Mode)
- **THEN** holding `a` or `d` SHALL behave identically to the Drum Window behavior (if the script bindings are active).
