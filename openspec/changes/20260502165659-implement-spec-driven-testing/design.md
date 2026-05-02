## Context

The Kardenwort-mpv project is a complex Lua-based mpv configuration with many interactive layers (Drum, SRT, Tooltips, Search HUD). Currently, manual regression testing is the only way to verify changes, which is inefficient and unreliable. We have formal specifications in `spec.md` files but no automated way to enforce them.

## Goals / Non-Goals

**Goals:**
- Implement a CLI-based test runner that boots a clean mpv instance.
- Create a "State Probe" in `lls_core.lua` to expose internal state to the test runner.
- Enable verification of ASS rendering tags (colors, weights) without pixel-based computer vision.
- Automate the validation of "Scenario" blocks in `spec.md`.

**Non-Goals:**
- Building a full CI/CD pipeline (this change focuses on local execution).
- Implementing video-based visual regression (pixel-perfect comparison).
- Testing hardware-specific rendering issues.

## Decisions

- **Inter-Process Communication (IPC)**: We will use mpv's `--input-ipc-server` over named pipes (Windows: `\\.\pipe\mpv-test`). This allows the test runner to send commands and query properties synchronously.
- **State Probe API**: `lls_core.lua` will be extended with `mp.register_script_message("test-probe", ...)` which returns a JSON payload of the current `FSM` state, `Tracks` metadata, and active `OSD` overlay data.
- **Python Test Driver**: A Python script in `/tests` will act as the orchestrator. Python's `json` and `win32file` (for pipes) libraries are robust for this purpose.
- **Aesthetic Verification**: Instead of "looking" at the screen, we will verify the generated ASS strings. 
    - *Example*: To verify a "Gold" highlight, the test runner checks if the OSD overlay data contains the tag `\1c&H00CCFF&`.
- **Event Simulation**: The runner will simulate keypresses via `mpv --input-ipc-server` and simulate mouse clicks by sending OSD coordinates to a new `test-click` script message.

## Risks / Trade-offs

- **Windows Pipe Latency**: Named pipes on Windows can occasionally be flaky. A robust retry/timeout mechanism in the Python driver is required.
- **Monolithic Script**: `lls_core.lua` is a large monolith. Exposing enough state for testing might require making some local variables global or wrapping them in a registry.
- **Maintenance Burden**: If the rendering logic changes significantly (e.g., moving away from ASS), the aesthetic tests will need to be updated. However, the BDD scenarios in `spec.md` will remain valid.
