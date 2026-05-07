# Capability: Automated Acceptance Testing

## ADDED Requirements

### Requirement: Pure-Function Unit Coverage
The system SHALL expose a set of pure utility functions in a stand-alone Lua module so they can be tested without booting mpv.

#### Scenario: Running unit tests offline
- **WHEN** a developer executes the unit-test runner against `scripts/lls_utils.lua`
- **THEN** the tests SHALL complete without instantiating mpv, without network access, and without LuaRocks-installed packages.

#### Scenario: Catching a regression in alpha calculation
- **WHEN** a developer changes `calculate_ass_alpha` in a way that produces incorrect output for a documented input
- **THEN** the unit-test suite SHALL fail with a diff showing expected vs actual values.

---

### Requirement: Headless mpv Test Lifecycle
The system SHALL provide a PowerShell helper that boots mpv in a headless configuration suitable for unattended runs.

#### Scenario: Booting a headless test instance
- **WHEN** the test harness invokes `Start-MpvTest` with a fixture path
- **THEN** mpv SHALL launch with no video window, no terminal interaction, no user-config bleed-through, and an IPC server on a known named pipe.

#### Scenario: Tearing down after a crash
- **WHEN** an acceptance test throws before reaching its cleanup step
- **THEN** the harness SHALL still terminate the spawned mpv process so the next test can re-bind the pipe.

---

### Requirement: IPC Command/Response Correlation
The system SHALL provide a PowerShell IPC client that correlates JSON-IPC responses to outgoing requests using `request_id`.

#### Scenario: Matching response to request under event interleaving
- **WHEN** the IPC stream emits property-change events between a request being sent and its response arriving
- **THEN** the client SHALL return the correct response object and SHALL NOT mistake an event for a response.

#### Scenario: Timing out on missing response
- **WHEN** mpv fails to acknowledge a command within the configured timeout
- **THEN** the client SHALL throw a descriptive error rather than block indefinitely.

---

### Requirement: State Probe Side Channel
The script SHALL expose curated semantic state via the `user-data/lls/state` and `user-data/lls/render` properties, populated on demand by IPC `script-message` triggers.

#### Scenario: Querying playback state
- **WHEN** the test harness sends `script-message-to lls_core lls-state-query` and reads `user-data/lls/state`
- **THEN** the property SHALL contain a JSON object with stable, semantic field names (`autopause`, `drum_mode`, `playback_state`, etc.) and SHALL NOT expose raw FSM internal field names directly.

#### Scenario: Probe is dormant in production
- **WHEN** no test client sends a probe message
- **THEN** the probe SHALL perform no per-tick work and SHALL allocate no per-tick objects.

---

### Requirement: Rendering Verification via ASS Inspection
The system SHALL support verification of visual elements by exposing the raw `.data` ASS string of named overlays for inspection.

#### Scenario: Verifying highlight color
- **WHEN** a word is highlighted and the test harness queries `lls-render-query dw`
- **THEN** the returned ASS string SHALL contain the `\1c&Hxxxxxx&` tag matching the configured highlight color.

#### Scenario: Querying an unknown overlay name
- **WHEN** the harness queries an overlay name that does not exist
- **THEN** the property SHALL be set to an empty string and SHALL NOT raise a Lua error.

---

### Requirement: Spec Citation in Tests
Acceptance test files SHALL begin with a comment header citing the spec capability and scenario they verify.

#### Scenario: Tracing a test back to its spec
- **WHEN** a developer reads any acceptance test file
- **THEN** the first non-empty comment SHALL identify the source spec path and the scenario name.
