## Context

The FSM review identified three deficiencies that are small in implementation scope but high in architectural significance:
1) ASS gatekeeping behavior is not fully symmetrical to the current requirement intent.
2) Search-mode forced character bindings are not lifecycle-symmetric for all whitelisted characters.
3) Esc-stage behavior and its documented contract are partially drifted.

These issues concentrate in a single module (`scripts/lls_core.lua`) and can be remediated without introducing new dependencies.

## Goals / Non-Goals

**Goals:**
- Enforce deterministic ASS gatekeeping behavior at FSM transition points.
- Guarantee that all search-mode forced bindings created at enter time are removed at exit time.
- Align Esc-stage behavior and spec language to one unambiguous contract.
- Add regression-oriented checks to keep these contracts stable after refactoring.

**Non-Goals:**
- Re-architecture of the entire FSM core.
- New UI capabilities or keymap redesign.
- Broad performance optimization unrelated to these deficiencies.

## Decisions

1. **Decision: Treat remediation as a spec-first correction with narrow code touchpoints**
- Rationale: The observed issues are specification fidelity gaps, not feature gaps. A focused change lowers risk and speeds verification.
- Alternatives considered:
  - Broad FSM refactor: rejected due to larger blast radius.
  - Code-only hotfix without spec updates: rejected because it preserves long-term drift risk.

2. **Decision: Add explicit lifecycle requirement for forced search bindings**
- Rationale: Binding/unbinding symmetry is a modal safety invariant and should be testable as a requirement, not left implicit.
- Alternatives considered:
  - Keep behavior implicit in implementation comments: rejected as non-auditable.

3. **Decision: Keep Esc behavior staged and deterministic; align docs to implementation intent**
- Rationale: Esc-stage predictability is user-critical in Drum Window workflows and should not depend on historical comments or legacy assumptions.
- Alternatives considered:
  - Expand Esc to close windows in the same command path: deferred; outside this remediation scope.

4. **Decision: Use acceptance-oriented checks tied to critical FSM invariants**
- Rationale: These issues are regression-prone because they involve modal state cleanup and transition edges.
- Alternatives considered:
  - Rely only on manual spot checks: rejected due to repeatability risk.

## Risks / Trade-offs

- [Risk] Tightened ASS gatekeeping may affect edge workflows where users expect partial Drum behavior with mixed tracks.  
  → Mitigation: constrain behavior to explicit ASS states and validate with track-state scenarios.

- [Risk] Binding cleanup changes may alter how rare keyboard layouts behave in search mode.  
  → Mitigation: validate with existing Latin/Cyrillic/German input paths and ensure no leakage after exit.

- [Risk] Esc contract clarification could conflict with undocumented user expectations.  
  → Mitigation: keep staged semantics unchanged unless required by spec delta; document exact behavior.

- [Risk] Regression checks could become stale if not maintained with future keymap/FSM edits.  
  → Mitigation: map checks directly to named requirements and keep them in change tasks.

## Migration Plan

1. Update spec delta for `fsm-architecture` with explicit corrected requirements.
2. Implement minimal code fixes in `scripts/lls_core.lua` aligned to the updated requirements.
3. Run targeted validation scenarios for ASS transitions, search enter/exit lifecycle, and Esc stages.
4. Record verification evidence in change task completion notes before archiving.

Rollback strategy: revert the remediation commit(s) if any mode-transition regression is observed; no schema or external data migration is involved.

## Open Questions

- Should ASS gatekeeping force Drum Window OFF immediately on any ASS presence, or only for selected active track combinations?
- Should Esc stage behavior remain strictly selection-tier-only in this command, with window close delegated elsewhere?
- Do we want a reusable internal helper that auto-registers/unregisters forced bindings to prevent future asymmetry bugs?
