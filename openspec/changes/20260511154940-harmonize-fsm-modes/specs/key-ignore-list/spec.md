## ADDED Requirements

### Requirement: Global Key Ignore List
The system SHALL provide a centralized mechanism to ignore specific keys in the `input.conf` file to prevent accidental triggers during immersion sessions.

#### Scenario: Ignoring a key
- **WHEN** a key listed as `ignore` in `input.conf` is pressed
- **THEN** no action is triggered and the key event is discarded by the system

### Requirement: Russian Layout Parity for Ignored Keys
The system SHALL automatically ignore the Russian (Cyrillic) layout equivalents for all keys explicitly ignored in the configuration.

#### Scenario: Ignoring RU equivalent
- **WHEN** a key `j` is set to `ignore`
- **THEN** its RU equivalent `о` is also implicitly ignored
