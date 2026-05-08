# Design: Regression Test Suite for Archived Changes

## Context
The project has undergone rapid development with many features and fixes archived via OpenSpec. While some basic tests exist, a comprehensive suite covering specific historical changes is missing. This design outlines how to build a robust set of acceptance tests targeting these archived changes using the existing Python + mpv IPC infrastructure.

## Goals / Non-Goals

**Goals:**
- Implement automated verification for all 18 archived changes listed in the request.
- Use the existing `MpvSession` and `MpvIpc` harness for headless testing.
- Organize tests by functional domain (Immersion, Input, UI/Aesthetics, Integration).
- Ensure high fidelity between the tests and the OpenSpec requirements in the archives.

**Non-Goals:**
- Creating unit tests for every internal Lua function (focus on behavioral acceptance).
- Redesigning the test harness itself.
- Testing external applications (e.g., GoldenDict) directly; instead, verify the mpv side of the integration (clipboard contents, command execution).

## Decisions

- **Test Framework**: Use `pytest` as the primary runner.
- **Test Organization**: Create a dedicated test file `tests/acceptance/test_archived_regressions.py` to keep these specific historical verifications grouped.
- **Verification Method**: Use `query_lls_state` to inspect the internal FSM state of the immersion engine and `query_lls_render` to verify OSD outputs.
- **Mocking/Fixtures**: Use existing fixtures in `conftest.py` where possible, and create new ones for specific scenarios (e.g., session resume test).
- **Domain Mapping**:
    - `Immersion`: Test adaptive replay, looping, and navigation desync fixes.
    - `Input`: Test hotkey false positives and layout-agnostic bindings.
    - `UI/Aesthetics`: Test tooltip hit-zones and highlight consistency.
    - `System`: Test SRT parser hardening, logging suppression, and session resume.

## Risks / Trade-offs

- **Timing Sensitivity**: IPC-based tests can be flaky if sleep durations are too short. I will use conservative delays or polling where necessary.
- **Complexity**: Testing 18 changes at once is a large task. I will structure the test file with clear sections and shared utility methods to manage complexity.
- **Environment**: Tests rely on `mpv` being in the PATH and available on Windows.
