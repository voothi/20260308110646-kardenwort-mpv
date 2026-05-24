## Why

The branch was rolled back to v1.82.26 because prior transfer attempts introduced visual regressions and unstable recovery patches. The pain is concentrated in:
- shading/frame behavior under `osd-border-style=background-box`,
- text-to-background envelope mismatch (especially long Cyrillic tooltip lines),
- tooltip geometry/alignment in fullscreen Drum Mode (DM),
- sequencing drift where large changes were attempted before foundational lifecycle fixes.

This change restores the visual improvements with a clean, minimally invasive, phase-gated transfer.

## Main Findings (Ordered by Risk)

1. Broad startup safety shims and broad binding rewrites are high-risk for this transfer and can reintroduce instability.
2. Tooltip centering must be DM-only, otherwise SRT tooltip parity can regress.
3. Border-style lifecycle must be stabilized before renderer rewrites.
4. Large hit-test rewrites are not required for first-pass visual recovery and should be conditional.

## What Changes

1. Establish baseline options and state diagnostics for geometry verification.
2. Implement robust UI border-style lifecycle handling for DW/Search/Tooltip overlays.
3. Fix DM tooltip geometry: Cyrillic width envelope, horizontal centering, DM vertical placement, hit-zone parity.
4. Decouple wrap-line spacing from inter-subtitle gaps and add safe-edge clamping.
5. Migrate to cohesive vector-card backgrounds (tooltip first, DW second) with compatibility alpha tags.
6. Add punctuation selection parity and only then evaluate deeper hit-test/drag changes if still needed.
7. Run targeted tests last, after user-approved visual checkpoints.

## Clean-Transfer Exclusions (Deferred Unless Proven Necessary)

- No global startup callback shim layer.
- No broad `manage_dw_bindings()` refactor.
- No mandatory `dw_hit_test()` architecture rewrite before visual acceptance.
- No global retheme/recolor pass; preserve existing color palette unless a specific defect requires a local fix.
- No broad ASS tag reshaping; keep existing text tags stable and add only narrowly scoped compatibility tags where required.

## Capabilities

### Modified Capabilities
- `drum-window`: spacing decoupling, safe-area clamping, unified visual card rendering.
- `drum-window-tooltip`: DM-only centering/placement, calibrated width envelopes, unified visual card rendering.
- `drum-context`: trailing punctuation selection parity.

## Impact

- `scripts/kardenwort/main.lua`: targeted, minimally invasive changes in rendering, tooltip geometry, and UI lifecycle paths.
- `tests/`: targeted acceptance coverage added/updated in the final phase only.
