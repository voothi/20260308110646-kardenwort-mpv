## Context

The recent DM/DW work introduced a new DM-specific viewport margin option (`drum_scrolloff`) and fixed a zero-margin edge case where tiny viewports could compute a negative margin. During integration, two runtime crash regressions appeared in `dw_build_layout` because cached subtitle layout entries coming from `ensure_sub_layout` did not always contain full draw-time fields.

This change documents the final stabilized behavior so future refactors preserve these boundaries and test expectations.

## Goals / Non-Goals

**Goals:**
- Document normative behavior for zero-margin scrolling in DM and DW paths.
- Document compatibility requirements for mixed-shape layout cache entries.
- Document acceptance-test expectations for crash signatures and stability checks.
- Ensure docs/specs align with implemented code and `mpv.conf`/README updates.

**Non-Goals:**
- No new runtime feature beyond existing `drum_scrolloff` and cache guards.
- No redesign of DW rendering architecture or cache invalidation strategy.
- No changes to unrelated tooltip/search/selection semantics.

## Decisions

1. Treat `drum_scrolloff` as DM-mini-only while retaining `dw_scrolloff` for DW window behavior.
- Rationale: DM mini viewport and DW window have different viewport geometry and user intent.
- Alternative considered: single shared option for both modes. Rejected because it couples unrelated layouts and increases regression risk.

2. Require non-negative margin clamping after mode-specific viewport-size calculation.
- Rationale: prevents `-1` margin drift and undefined pointer behavior when visible-line count is very small.
- Alternative considered: minimum enforced viewport size > 1. Rejected because it removes legitimate compact configurations.

3. Accept mixed cache shapes and rebuild when draw-time fields are missing.
- Rationale: `ensure_sub_layout` is navigation-oriented and may produce reduced entries; draw path must be resilient.
- Alternative considered: split caches by namespace/key. Rejected for now to keep implementation minimal and avoid wider refactor risk.

4. Encode failures as explicit regression signatures in acceptance tests.
- Rationale: both observed failures are deterministic (`height` nil arithmetic and `entry` nil indexing) and easy to detect in logs.
- Alternative considered: visual-only verification. Rejected because it would miss silent crash loops in headless runs.

## Risks / Trade-offs

- [Risk] Additional compatibility guards may mask future cache-contract drift.
  - Mitigation: require acceptance tests asserting no `master_tick crash` signatures under cache-shape transition paths.

- [Risk] Mode-specific scrolloff options may confuse configuration usage.
  - Mitigation: document clear scope (`drum_scrolloff` for DM mini, `dw_scrolloff` for DW window) in README and specs.

- [Risk] Headless mpv IPC instability can intermittently block acceptance runs.
  - Mitigation: keep tests deterministic and include syntax-level validation fallback; rerun in stable local runner/CI environment.
