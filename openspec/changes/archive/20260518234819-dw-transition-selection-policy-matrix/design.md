## Context

The Drum Window transition path (`Enter` and double-click) now supports a configurable post-transition selection policy via `dw_clear_selection_after_transition`, and behavior must remain deterministic across Esc modes (`auto_follow_current`, `neutral_last_selection`, `neutral_current_subtitle`) and Book Mode ON/OFF.

Recent fixes solved concrete regressions, but the final contract must be explicit: users need predictable pointer retention/clearing, follow/manual transitions, and Esc recovery semantics. This change formalizes the matrix and aligns runtime and tests around one policy.

## Goals / Non-Goals

**Goals:**
- Define one canonical post-transition state machine shared by `Enter` and double-click.
- Guarantee deterministic interaction between `dw_clear_selection_after_transition` and `dw_esc_mode`.
- Preserve Manual Mode when pointer is intentionally retained (`clear=no`) until explicit `Esc` clear.
- Ensure testability with acceptance scenarios covering all mode combinations and Book Mode ON/OFF.

**Non-Goals:**
- Redesign of Esc staged-clear ordering (pink/range/pointer stages remain unchanged).
- Changes to non-transition navigation (`a/d`, scroll, search mode).
- Visual theme or rendering format updates.

## Decisions

1. **Shared transition contract for Enter and double-click**
- Decision: Both inputs SHALL route through equivalent post-transition state logic.
- Rationale: Prevent drift where one path clears/arms/follows differently.
- Alternative considered: keep separate logic blocks and mirror manually. Rejected due to high regression risk.

2. **Policy matrix keyed by `dw_clear_selection_after_transition` first, then Esc mode**
- Decision: `clear=yes` clears pointer/range/set immediately; `clear=no` preserves pointer/anchor.
- Rationale: This directly expresses user intent (clear or keep) and keeps Esc modes focused on follow/neutral semantics.
- Alternative considered: Esc mode overriding clear policy. Rejected because it weakens explicit user control.

3. **Follow restoration semantics**
- Decision: In `auto_follow_current`, transition SHALL restore follow unless pointer remains active (`clear=no`); in neutral modes transition SHALL remain manual.
- Rationale: Matches agreed workflow: retained pointer means intentional manual focus until explicit clear.
- Alternative considered: always restore follow in auto mode even when pointer remains. Rejected due to reported study-flow friction.

4. **Neutral arm reset after transition**
- Decision: Transition SHALL reset `DW_ESC_NEUTRAL_ARMED=false` before applying selection/follow policy.
- Rationale: Prevent stale neutral state from requiring extra Esc presses.
- Alternative considered: preserve prior arm state. Rejected due to observed inconsistent Esc behavior.

5. **Book Mode treatment tied to mode policy, not hard-coded transition branch**
- Decision: Book Mode shall not independently override transition policy; resulting follow/manual state comes from the policy matrix.
- Rationale: Avoid contradictory behavior and simplify predictability.
- Alternative considered: forcing manual after all transitions when Book Mode ON. Rejected as incompatible with agreed `auto_follow_current` behavior.

## Risks / Trade-offs

- **[Risk] Increased cognitive load from matrix complexity** -> Mitigation: explicit spec scenarios per mode combination and focused acceptance tests.
- **[Risk] Legacy assumptions in older tests/docs (Book Mode always manual after transition)** -> Mitigation: update modified capability specs and add parity tests for Enter/double-click.
- **[Risk] Future drift between runtime and test hooks** -> Mitigation: test hook executes shared production transition path.

## Migration Plan

1. Land spec deltas for `dw-esc-mode`, `dw-mouse-selection-engine`, `drum-window-reading-mode`, and new `dw-transition-selection-policy` capability.
2. Keep `kardenwort-dw_clear_selection_after_transition` default as currently configured.
3. Run acceptance matrix tests and selected historical regressions.
4. If regression appears, rollback to previous helper behavior while preserving spec/test scaffolding for rapid re-application.

## Open Questions

- Should `dw_clear_selection_after_transition` remain globally scoped, or later evolve to per-input granularity (`Enter` vs double-click)?
- Do we want lightweight runtime OSD diagnostics for resolved Esc mode and clear policy when debugging user reports?
