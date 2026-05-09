# Delta Specification: Automated Acceptance Testing

## ADDED Requirements

### Requirement: Standardized Environmental Constants
The automated test suite MUST use environment constants that align with production defaults to ensure deterministic verification.

#### Scenario: Audio Padding Alignment
- **WHEN** Initializing a test fixture.
- **THEN** The `audio_padding_start` and `audio_padding_end` values MUST default to **1000ms** (matching the stabilized `lls-audio_padding_start=1000` production standard).
- **AND** Integration tests MUST verify correct behavior across complex subtitle overlaps in `fragment2` fixtures.

### Requirement: Enhanced LlsProbe Method Resolution
The IPC test harness MUST be able to resolve and execute functions defined as methods of the `LlsProbe` table in the Lua global scope.

#### Scenario: Querying LlsProbe:get_state()
- **WHEN** the test harness calls a function named `get_state` via the probe.
- **THEN** the harness MUST first look for `_G.get_state` and, if missing, fallback to `_G.LlsProbe.get_state`.
