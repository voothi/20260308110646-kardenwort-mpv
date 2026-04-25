## ADDED Requirements

### Requirement: Synchronized Documentation Updates
The project SHALL ensure that all user-facing documentation (README, Release Notes) is synchronized with the technical state of the latest release.

#### Scenario: Packaging a release
- **WHEN** a release milestone is reached
- **THEN** the `README.md` and `release-notes.md` SHALL be updated to include new keybindings, version badges, and feature descriptions.

### Requirement: Version Badge Synchronization
The project SHALL maintain a consistent version badge in the primary `README.md` that reflects the currently deployed technical state.

#### Scenario: Bumping the version
- **WHEN** the project state is finalized
- **THEN** the version badge SHALL be updated (e.g., to v1.2.18) to reflect the release drop.
