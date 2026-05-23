## Context

The current branch was reset to a stable baseline (`e7003003`) to stop DW/DM transparency regressions. The completed functionality branch ending at `a89c364c` contains the required DW layout, hit-testing, tooltip, and regression-test improvements, but replaying it without guardrails risks reintroducing the same window opacity layering issue.

The transfer touches one large runtime file (`scripts/kardenwort/main.lua`) and five test files. Because this is both behavior-heavy and regression-sensitive, we need a deterministic transfer strategy: define the function scope, restore tests first, replay implementation, and verify with automated gates.

## Goals / Non-Goals

**Goals:**
- Restore the validated behavior set from `e7003003..a89c364c` into the current branch.
- Preserve and enforce DW/DM transparency correctness, including DM + `background-box` no double-dark layering.
- Restore click-accuracy, top/bottom clamping, and customizable long-line spacing (`dw_wrap_line_height_mul`).
- Add and run automated regression tests for all transferred behavior before declaring completion.
- Keep the transfer auditable via a clear function inventory and bounded file scope.

**Non-Goals:**
- Reworking unrelated subtitle parsing or export pipelines outside the diff scope.
- Refactoring architecture beyond what is required to restore the completed behavior.
- Introducing new UI features that were not part of `a89c364c` branch outcomes.

## Decisions

### Decision 1: File-Scoped Replay Instead of Full Branch Merge
- **Decision**: Replay only the known changed files from `e7003003..a89c364c` rather than merging branch history.
- **Rationale**: The user explicitly requested no history-rewriting operations and wants precise correction on top of the rollback branch.
- **Alternative considered**: Merge/cherry-pick the full commit range. Rejected because it carries history complexity and unnecessary metadata churn for this recovery task.

### Decision 2: Test-First Restoration Gate
- **Decision**: Restore regression tests first, run them to establish expected failures on baseline, then restore code and rerun until green.
- **Rationale**: This provides proof that behavior recovery is driven by executable specs, not manual assumptions.
- **Alternative considered**: Restore code and tests together. Rejected because it hides whether tests actually guard the intended regressions.

### Decision 3: Explicit Function Transfer Inventory
- **Decision**: Track newly introduced helper functions and critical modified call sites as the transfer checklist.
- **Rationale**: `main.lua` is large; a function-level inventory reduces accidental omissions.
- **Transferred/new helper functions**:
  - `dw_calculate_block_top`
  - `dw_vline_height`
  - `dw_get_str_width_proportional`
  - `get_dw_drag_threshold_px`
  - `get_dw_mouse_auto_scroll_interval`
  - `dw_pointer_exceeded_drag_threshold`
  - `dw_resolve_neighbor_word`
  - `resolve_tooltip_target_line`
  - `validate_callback`
- **Primary modified integration points**:
  - `draw_dw`
  - `dw_build_layout`
  - `dw_hit_test`
  - `dw_mouse_auto_scroll`
  - `dw_mouse_update_selection`
  - `draw_dw_tooltip`
  - `draw_drum`
  - `tick_dw`

### Decision 4: Transparency Guard as First-Class Regression Condition
- **Decision**: Keep the DM background-box guard that neutralizes per-line tooltip dark layers while preserving global background behavior.
- **Rationale**: This directly addresses the rollback trigger: DW/DM window transparency accumulation.
- **Alternative considered**: Disable tooltip/background features in DM entirely. Rejected because it removes intended functionality and parity.

## Risks / Trade-offs

- **[Risk]** Large `main.lua` replay could silently regress adjacent behavior.
  - **Mitigation**: Use file-level diff verification plus targeted acceptance and unit tests from the source branch.
- **[Risk]** Regression tests restored from source branch may rely on subtle branch state.
  - **Mitigation**: Keep transfer scope to files proven in `e7003003..a89c364c` and adjust only when test failure demonstrates branch coupling.
- **[Risk]** Transparency fixes can conflict with different OSD border styles.
  - **Mitigation**: Preserve conditional guard only for DM + `background-box`; leave other modes/styles unchanged.

## Migration Plan

1. Restore/introduce regression tests from `a89c364c` into current branch.
2. Run targeted pytest suites and capture baseline status.
3. Restore `scripts/kardenwort/main.lua` from `a89c364c` and verify function inventory presence.
4. Re-run unit and acceptance suites until all planned gates pass.
5. Keep manual visual checks (DW/DM transparency and long wrapped subtitles) as post-automation validation.

## Open Questions

- None blocking implementation. Manual rendering checks remain recommended after automated gates pass.
