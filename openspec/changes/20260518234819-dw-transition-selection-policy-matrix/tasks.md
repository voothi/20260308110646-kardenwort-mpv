## 1. Transition Policy Contract

- [ ] 1.1 Finalize and document the post-transition matrix for `dw_clear_selection_after_transition` x `dw_esc_mode` (including Book Mode ON/OFF expectations).
- [ ] 1.2 Ensure Enter and double-click both invoke the same post-transition policy helper.
- [ ] 1.3 Ensure transition logic resets stale neutral-arm state before applying follow/pointer outcomes.

## 2. Runtime Behavior Hardening

- [ ] 2.1 Verify clear=yes clears pointer/range/pink state and applies follow/manual state by Esc mode.
- [ ] 2.2 Verify clear=no preserves pointer and keeps manual mode in `auto_follow_current` until Esc pointer clear.
- [ ] 2.3 Verify neutral modes (`neutral_last_selection`, `neutral_current_subtitle`) remain manual after transition.

## 3. Acceptance Regression Coverage

- [ ] 3.1 Add/maintain Enter transition tests for all mode combinations in the transition policy suite.
- [ ] 3.2 Add/maintain double-click parity tests using the production transition path.
- [ ] 3.3 Add Book Mode ON coverage for auto mode and neutral modes.

## 4. Verification and Release Readiness

- [ ] 4.1 Run focused acceptance tests for transition policy and historical double-click regression.
- [ ] 4.2 Confirm no regressions in Esc staged-clear semantics (pink -> range -> pointer) during transition workflows.
- [ ] 4.3 Prepare change for `/opsx:apply` with artifacts reviewed and implementation-ready.
