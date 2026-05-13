## Why

Recent DM/DW improvements introduced a new `drum_scrolloff` option and a safety clamp for zero-margin scrolling, but the repository documentation and spec artifacts do not yet capture these behavior guarantees. We also fixed two `dw_build_layout` crash paths caused by partial `layout_cache` entries, and these stability boundaries need explicit regression documentation.

## What Changes

- Document the new DM mini viewport option `kardenwort-drum_scrolloff` and its intended behavior (`0` means no reserved margin).
- Document zero-margin clamping rules so `dw_scrolloff=0` and `drum_scrolloff=0` cannot create negative margins in tiny viewports.
- Document cache-shape compatibility guarantees for `dw_build_layout` when reduced `layout_cache` entries are present.
- Document the new acceptance regression tests that guard against `master_tick crash` signatures related to `entry`/`height` nil failures.

## Capabilities

### New Capabilities
- `dw-layout-cache-compatibility-guards`: Defines behavior guarantees for DW layout rendering when subtitle layout caches are partial.

### Modified Capabilities
- `drum-scroll-sync`: Clarify zero-scrolloff behavior and non-negative margin clamping in DM/DW scrolling.
- `config-documentation`: Add and describe `kardenwort-drum_scrolloff` in user-facing configuration docs.
- `automated-acceptance-testing`: Require regression coverage for layout-cache compatibility and zero-scrolloff stability.

## Impact

- Affected code: `scripts/kardenwort/main.lua` (layout cache compatibility + scrolloff clamping logic).
- Affected config/docs: `mpv.conf`, `README.md`, `docs/conversation.log` release traceability.
- Affected tests: `tests/acceptance/test_20260513143307_dw_layout_cache_and_scrolloff_zero.py`.
- Runtime impact: improved resilience in master tick rendering path for DW/DM modes, especially in tiny viewport or zero-margin configurations.
