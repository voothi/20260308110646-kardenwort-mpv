## Why

Recent architectural refinements in Kardenwort v1.80.8, including the "Drum scrolloff" logic and a critical layout cache-shape fix, were implemented to address edge-case crashes and improve navigation ergonomics. To maintain the project's high stability standards and prevent regressions in these sensitive areas, automated acceptance tests are required.

## What Changes

- Add regression tests for `drum_scrolloff` and `dw_scrolloff=0` clamping logic to ensure viewport stability.
- Add regression tests for the `dw_build_layout` cache-shape mismatch fix to prevent arithmetic errors during layout reconstruction.
- Implement necessary IPC diagnostic hooks if current instrumentation is insufficient for layout state assertions.

## Capabilities

### New Capabilities
- `regression-testing-v1-80-8`: Comprehensive test coverage for v1.80.8 specific fixes, focusing on layout robustness and configuration edge cases.

### Modified Capabilities
- `extended-layout-robustness`: Adding formal verification for cache validity and partial entry rejection.
- `drum-scroll-sync`: Adding verification for scrolloff-aware viewport clamping.

## Impact

- **Test Suite**: Expansion of the `pytest` based acceptance suite.
- **Instrumentation**: Potential addition of IPC state getters for `win_lines` or layout margins.
- **Maintenance**: Improved confidence in future refactors of the `dw_build_layout` loop.
