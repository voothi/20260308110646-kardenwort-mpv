## Why

To maintain high software quality and prevent regressions, we need automated acceptance tests for four recently implemented features: Natural Progression sub-skipping, Seek Repeatability, Movie Mode SRT boundary compliance, and FSM architecture gap fixes. These tests will ensure that future changes do not break these critical immersion engine behaviors.

## What Changes

- **Add Automated Tests**: Create a new suite of acceptance tests in `tests/acceptance/test_archived_changes.py`.
- **Test Natural Progression**: Verify that the FSM transitions to the next subtitle when the playhead enters its padded start zone.
- **Test Seek Repeatability**: Verify that seek keybindings have the `repeatable` flag set in the `mpv` input layer.
- **Test Movie Mode Boundary**: Verify that autopause occurs at or after the SRT `end_time` in `MOVIE` mode.
- **Test FSM Architecture Gaps**: Verify visibility toggling and secondary track state synchronization.

## Capabilities

### New Capabilities
- `archived-features-verification`: Verification suite for recently archived features to ensure long-term stability.

### Modified Capabilities
- `fsm-architecture`: Requirements for state synchronization and visibility toggling under specific conditions (Drum Window).

## Impact

- **Tests**: New test file `tests/acceptance/test_archived_changes.py` and potentially new fixtures in `tests/fixtures/`.
- **Development Workflow**: Enhanced confidence during refactoring and feature additions.
