## Context

The `kardenwort-mpv` project uses a Python-based acceptance testing framework that interacts with `mpv` via JSON IPC. Existing tests in `tests/acceptance/` provide a foundation for verifying subtitle synchronization and state transitions. We need to extend this coverage to four recently archived features.

## Goals / Non-Goals

**Goals:**
- Implement automated verification for Natural Progression, Seek Repeatability, Movie Mode Boundaries, and FSM Spec Gaps.
- Maintain compatibility with the existing `MpvSession` and `MpvIpc` utilities.
- Ensure tests are reliable and non-flaky on Windows.

**Non-Goals:**
- Re-writing the core testing framework.
- Adding exhaustive unit tests for every Lua helper function (focus is on high-level behavior).

## Decisions

### 1. Test Organization: Single Unified File
- **Decision**: Put all four tests in `tests/acceptance/test_archived_changes.py`.
- **Rationale**: Keeps related "feature hardening" tests together while avoiding clutter in the main `test_subtitle_sync.py`.

### 2. Verification Method: IPC State Inspection vs. OSD Parsing
- **Decision**: Use `query_lls_state` and property inspection via IPC.
- **Rationale**: State inspection is more robust than parsing ASS/OSD text, which is subject to rendering and timing variances.

### 3. Seek Repeatability Check
- **Decision**: Inspect the `input-bindings` property in `mpv`.
- **Rationale**: Directly testing "hold-to-repeat" in a headless environment via IPC is difficult. Checking the binding definition ensures the logic is correctly wired at the engine level.

## Risks / Trade-offs

- **[Risk] Timing Flakiness** → **Mitigation**: Use `time.sleep()` strategically and `wait_property_change` where possible to handle IPC latency.
- **[Risk] Fixture Dependency** → **Mitigation**: Use existing test fixtures (`tests/fixtures/20260502165659-test-fixture.mp4`) to ensure consistency.
