## Deferred Renderer Unification Candidates

This change intentionally unifies only the tooltip style surface. The broader DW/DM renderer merge remains out of scope for safety.

## Trace 20260525122538: DM Tooltip Double-Dark Regression

Observed from `docs/assets/20260525122449.png`, `docs/assets/20260525122509.png`, and `docs/assets/20260525122534.png`: SRT remains acceptable, DW remains the visual baseline, while DM stacks a tooltip card over the Drum Mode subtitle surface and becomes visibly darker.

Considered options:

- Global tooltip `osd-border-style` override for all modes. Rejected because it also mutates the active Drum Mode subtitle surface and reproduces the lost main/secondary frame regression.
- Pure in-band native-box neutralization. Rejected as insufficient because it preserves DM frames but still leaves the measured tooltip vector card at the same opacity as DW/SRT, causing DM double-dark stacking.
- Keep the shared tooltip renderer, but make tooltip card alpha mode-aware while keeping text/native-box policy shared. Chosen because it removes the extra dark DM panel without changing DW/SRT behavior or touching the parent DM subtitle frames.

Implementation decision: `tooltip_dm_bg_opacity` defaults to `100` after visual calibration; empty value falls back to `tooltip_bg_opacity`. This is intentionally narrower than a full DW/DM renderer merge and gives the recurring visual problem a stable configuration point.

## Trace 20260525123946: SRT Tooltip Card Calibration

SRT differs from DW because `tooltip_native_box_policy=auto` intentionally gives the scoped global override only to DW. SRT, like DM, keeps the parent `background-box` style stable and neutralizes native tooltip text boxes in-band. Therefore the remaining visible dark surface is the measured vector tooltip card, not a DW-style global window.

Implementation decision: `tooltip_srt_bg_opacity` was added as a SRT-only card alpha override. It defaults to `100` after visual calibration; empty value falls back to `tooltip_bg_opacity`.

## Trace 20260525124408: DW Tooltip Card Calibration

DW originally used `tooltip_bg_opacity` as the baseline card alpha because it was the mode used to define the tooltip renderer. After adding DM and SRT card alpha overrides, leaving DW implicit would keep one evolutionary special case in the shared style context.

Implementation decision: `tooltip_dw_bg_opacity` was added as a DW-only card alpha override. It defaults to empty so the code fallback remains backward-compatible. Visual testing rejected `tooltip_dw_bg_opacity=100`, so DW should normally inherit `tooltip_bg_opacity`.

## Trace 20260525125206: DW Transparent Card Rejected

`tooltip_dw_bg_opacity=100` was tested visually in `docs/assets/20260525125200.png` and rejected. DW is different from DM/SRT because its `auto` policy still uses the scoped global border-style override, so making the measured tooltip card fully transparent leaves an outline/text composition that does not match the intended DW tooltip window.

Implementation decision: keep the DW parameter for symmetry and manual tuning, but leave it empty in defaults/config so DW falls back to `tooltip_bg_opacity`.

## Trace 20260525125430: Replace User-Facing `opacity=100` With ASS Alpha

The mode-specific card override approach is mechanically sound, but exposing the calibrated value as `tooltip_*_bg_opacity=100` is misleading because this renderer converts numeric `0..100` values as transparency percentages. In other words, `100` means fully transparent, not fully opaque.

Implementation decision: add preferred `tooltip_bg_alpha`, `tooltip_dw_bg_alpha`, `tooltip_dm_bg_alpha`, and `tooltip_srt_bg_alpha` options. These use explicit ASS alpha semantics: `00` is opaque and `FF` is fully transparent. The legacy `tooltip_*_bg_opacity` options remain accepted as fallbacks for existing configs.

## Trace 20260525135736: Screenshot Drift Versus ASS Drift

The screenshots `docs/assets/20260525140307.png`, `docs/assets/20260525140324.png`, and `docs/assets/20260525140557.png` can look different even when the tooltip ASS contract is stable, because DM/SRT now use transparent extra tooltip cards and the underlying video/slides strongly affect perceived contrast.

Implementation decision: add a deterministic `test-query-tooltip-style-contract` probe that reports DW/DM/SRT style contexts plus sample card/text ASS. Regression coverage now checks that `render-query` exposes `drum`, `dw`, and `tooltip` overlays, and that the mode contract under `background-box` remains: DW uses scoped override/fallback card alpha; DM/SRT neutralize native boxes and use transparent card alpha.

### Candidate 1: Shared Card/Text Event Builder For DW And DM Main Overlays
- Lift card/text ASS event formatting from `draw_dw` and `draw_drum` into common helpers.
- Keep layout and hit-zone logic separate at first.
- Goal: reduce style drift without changing navigation geometry.

### Candidate 2: Shared Border-Ownership Registry Per Overlay
- Replace mode-local border override calls with per-overlay ownership keys (`dw`, `search`, `tooltip`, `notice`, `seek`).
- Goal: prevent override depth leaks and hidden coupling between overlays.

### Candidate 3: Unified Style Context For All OSD Surfaces
- Create a normalized style context (`font`, `alpha`, `bord`, `shad`, `native-box policy`) for all surfaces.
- Goal: make `background-box` handling explicit and testable in one place.

### Candidate 4: Cross-Mode Snapshot Tests
- Add integration tests that compare generated ASS contracts for DW/DM/SRT across the same timeline snapshot.
- Goal: catch visual parity regressions before they reach manual screenshot review.
