## Context

Kardenwort v1.80.8 introduced fixes for a layout cache crash and scrolloff calculation bugs. The layout crash was caused by `ensure_sub_layout` producing partial cache entries that lacked a `height` field, which subsequently caused arithmetic errors in `dw_build_layout`. The scrolloff bug allowed negative margins in small windows, causing viewport instability. This design outlines the automated verification of these fixes.

## Goals / Non-Goals

**Goals:**
- Automated verification of `dw_build_layout` robustness against partial cache entries.
- Automated verification of `drum_scrolloff` and `dw_scrolloff` clamping logic.
- Integration of these tests into the existing `pytest` acceptance suite.

**Non-Goals:**
- Large-scale refactoring of the layout or caching logic.
- Modification of the core FSM beyond necessary instrumentation.

## Decisions

- **Decision: Use IPC Diagnostic Hooks for State Injection**
  - **Rationale**: Reproducing a "partial cache entry" crash requires precise control over the internal `layout_cache`. Adding an IPC hook to manually invalidate or corrupt a cache entry is more reliable than trying to trigger the race condition naturally.
- **Decision: Parameterized Scrolloff Testing**
  - **Rationale**: Testing multiple scrolloff values (`0`, `-1`, `100`, etc.) using a single parameterized test ensures that clamping works across the entire domain of potential user inputs.

## Risks / Trade-offs

- **[Risk] Test Fragility** → [Mitigation] Link assertions to high-level FSM states (`DW_CURSOR_LINE`, `DW_ANCHOR_WORD`) rather than fragile OSD string matching where possible.
- **[Risk] Instrumentation Bloat** → [Mitigation] Only add the minimum required IPC hooks for the regression scenarios.
