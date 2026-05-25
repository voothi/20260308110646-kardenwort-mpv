## Context

The tooltip overlay is conceptually one feature, but it was grown through DW first and then DM/SRT activation paths later. The current code shares `draw_dw_tooltip()` for the tooltip body, yet the style lifecycle is not shared:

- DW enters a custom UI state and enables `manage_ui_border_override(true)`, so text is rendered under `outline-and-shadow`.
- DM keeps global `osd-border-style=background-box` because the main Drum OSD historically relied on it.
- The tooltip renderer attempts to neutralize DM native text boxes with `line_bgbox_neutral`, but tag order is fragile. If `{\\3a&HFF&\\4a&HFF&}` is emitted before later `{\\3a...}{\\4a...}` styling, the later tags re-enable the dark per-line boxes.

So this is primarily a renderer/style-lifecycle problem, not a wrapping or `string.format()` problem. `string.format()` only makes the bug easy to reintroduce because style semantics are encoded as ad hoc tag strings in several call sites.

## Goals / Non-Goals

**Goals:**

- Make DW, DM, and styled SRT tooltips use one tooltip visual contract.
- Preserve the DW look as the baseline: one measured vector card, consistent typography, no extra native per-line frames.
- Refactor the tooltip style construction enough that tag order and global border style cannot silently diverge by mode.
- Keep the implementation small enough to be safe: isolate tooltip card/text event generation before considering a broader DW/DM renderer merge.
- Make tooltip border/background behavior configurable through explicit tooltip options rather than hidden mode assumptions.
- Add regression tests that inspect generated ASS for DM and DW under `background-box`.

**Non-Goals:**

- Do not rewrite all DW and DM layout/hit-testing in this change.
- Do not change tooltip targeting, secondary subtitle lookup, cache invalidation, or hit-zone lifecycle semantics except where style ownership requires it.
- Do not change the user's existing default visual language beyond removing unintended dark nested boxes in DM tooltip.

## Decisions

### Decision: Extract Tooltip Style Event Construction

Create a small shared style layer around the existing tooltip renderer, for example:

- `build_tooltip_style_context(mode)`
- `format_tooltip_card_event(style, rect)`
- `format_tooltip_text_event(style, anchor_x, line_center_y, line_text)`

Rationale: this keeps the existing layout/wrapping/hit-zone logic intact while removing the fragile string-tag scatter that caused DM and DW to diverge. The "entity" we unify first is the tooltip surface, not the entire DW/DM renderer.

Alternative considered: move all DW and DM rendering into a single generic viewport renderer now. That is architecturally attractive, but it touches too much interaction geometry at once and risks creating regressions far beyond the tooltip.

### Decision: Treat DW Visual Output as the Baseline

The default tooltip profile should match the DW screenshot behavior: a single measured vector card with configured background opacity, border/shadow/text styling, and no nested native background boxes.

Rationale: DW is the mature lineage and is the view the user has identified as visually correct. DM should not have a separate tooltip aesthetic unless an explicit configuration requests it.

Alternative considered: preserve separate DW and DM tooltip skins. That keeps legacy behavior but codifies the exact divergence that keeps causing regressions.

### Decision: Centralize Native Background-Box Isolation

The tooltip style layer must decide how native `background-box` is isolated before text events are emitted. Two valid mechanisms are allowed, but only one should be active for a tooltip render:

- Prefer a scoped border override when it does not destabilize the parent DM subtitle surface.
- Otherwise emit in-band neutralization tags after all text border/shadow tags so later tags cannot re-enable native per-line boxes.

Rationale: the recurring bug is tag-order/lifecycle leakage. The renderer needs an explicit "native box isolation" policy rather than a one-off `line_bgbox_neutral` string whose position can drift.

Alternative considered: keep the current DM-only neutralization branch and patch the tag order. That is the immediate symptom fix, but it leaves the next edit one string concatenation away from recreating the bug.

### Decision: Add Explicit Tooltip Configuration Knobs Only Where They Represent Policy

Keep existing numeric visual knobs (`tooltip_border_size`, `tooltip_shadow_offset`, `tooltip_bg_opacity`) and add a policy option only if needed, such as `tooltip_native_box_policy = "auto" | "override" | "neutralize"`.

Rationale: normal users should not have to configure their way out of a renderer leak. The default `auto` mode should choose the safe DW-equivalent rendering path.

Alternative considered: add many mode-specific tooltip options (`dm_tooltip_*`, `dw_tooltip_*`). That would make the issue configurable but would deepen the split between modes.

### Decision: Test the Generated ASS Contract

Regression tests should assert that, under global `background-box`:

- DM tooltip text events do not contain active native per-line background boxes after style generation.
- DW and DM tooltip card events use the same measured-card style contract.
- The neutralization/override policy cannot be defeated by later `{\\3a...}{\\4a...}` tags in the same text event.

Rationale: the visual bug is caused by ASS tag sequencing, so screenshots are useful, but string-contract tests catch the regression quickly and deterministically.

## Risks / Trade-offs

- [Risk] Scoped border override in DM could alter the main Drum subtitle appearance while a tooltip is visible. → Mitigation: default to in-band neutralization if the parent DM surface still depends on global `background-box`, or explicitly re-render parent surfaces under the same shared style contract before enabling override globally.
- [Risk] In-band neutralization can make tooltip text less outlined if global background-box disables outline semantics. → Mitigation: keep the measured card as the visual foundation and verify legibility against DW screenshots; if outline parity requires it, move to a scoped override after proving parent DM does not regress.
- [Risk] Refactoring style generation without touching layout may leave other DW/DM duplication in place. → Mitigation: define this as a first bounded step; only unify the tooltip surface now, then use later proposals for broader viewport renderer consolidation.
- [Risk] Tests that only inspect strings might miss actual libass/mpv rendering differences. → Mitigation: combine string-contract tests with at least one acceptance scenario that queries DM and DW tooltip overlay data under `background-box`; optional screenshot/manual verification can remain a final confidence check.
