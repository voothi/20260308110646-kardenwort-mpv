## 1. Rendering Recovery

- [ ] 1.1 Fix syntax errors in `scripts/lls_core.lua`: Restore missing `end` statements in `draw_drum` and `draw_dw` rendering loops to restore OSD visibility.

## 2. Priority Refactoring

- [ ] 2.1 Refactor highlighting logic in `draw_drum`: Separate focus point evaluation from automated matching and apply a strict `priority` hierarchy.
- [ ] 2.2 Refactor highlighting logic in `draw_dw`: Migrate Selection and Focus evaluation to a higher tier (Priority 2) than database highlights (Priority 3).
- [ ] 2.3 Implement `meta.priority == 0` guards: Ensure that once a high-priority highlighter claims a token, lower-priority highlighters are skipped.

## 3. Verification and Polish

- [ ] 3.1 Interaction Test: Verify that hovering (Vibrant Yellow) correctly masks Orange database highlights.
- [ ] 3.2 Selection Test: Verify that drag-selecting (Vibrant Yellow) correctly masks automated highlights within the range.
- [ ] 3.3 Regression Test: Confirm that "Pale Yellow" persistent selections still maintain absolute top priority and are not masked by hover focus.
