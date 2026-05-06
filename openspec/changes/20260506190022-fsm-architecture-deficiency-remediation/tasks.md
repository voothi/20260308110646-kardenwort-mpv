## 1. Specification Alignment

- [ ] 1.1 Finalize and review the `fsm-architecture` delta spec for ASS gatekeeping, search binding lifecycle symmetry, and Esc-stage contract clarity.
- [ ] 1.2 Confirm proposal/design/spec artifact consistency (no requirement conflicts across documents).

## 2. FSM Gatekeeping Remediation

- [ ] 2.1 Update ASS gatekeeping transition logic in `scripts/lls_core.lua` so ASS contexts force both `FSM.DRUM` and `FSM.DRUM_WINDOW` to safe OFF states.
- [ ] 2.2 Ensure native subtitle visibility/position restoration follows FSM desired-state variables after forced gatekeeping transitions.

## 3. Search Mode Lifecycle Remediation

- [ ] 3.1 Refactor search-mode binding registration/unregistration so the exact same character set is used for both enter and exit lifecycle paths.
- [ ] 3.2 Add explicit regression checks for German character bindings (`ä`, `ö`, `ü`, `ß`, `Ä`, `Ö`, `Ü`, `ẞ`) to verify no forced bindings leak after search modal exit.

## 4. Esc Contract and Regression Hardening

- [ ] 4.1 Align `cmd_dw_esc` implementation comments and behavior with the staged contract (Pink -> Range -> Pointer) and remove contradictory contract text.
- [ ] 4.2 Execute targeted scenario validation for: ASS transition safety, search enter/exit modal integrity, and Esc stage idempotency.
- [ ] 4.3 Record verification notes and residual risks in the change before implementation handoff.
