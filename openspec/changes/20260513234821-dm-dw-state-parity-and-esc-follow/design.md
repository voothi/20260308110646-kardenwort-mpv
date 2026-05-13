## Context

Recent fixes stabilized behavior for:
- restoring auto-leading after final `Esc` clear,
- preventing stale pointer origin after `a`/`d` and manual scroll,
- and aligning DM Book Mode paging behavior with DW.

The implementation now behaves as intended, but the repository needs a standards-compliant OpenSpec change package so these guarantees are explicit, reviewable, and archive-ready.

## Goals / Non-Goals

**Goals:**
- Convert the resolved behavior chain into a formal OpenSpec proposal.
- Ensure each critical state transition has unambiguous normative language.
- Preserve cross-mode parity between DW and DM for Book Mode and Esc-stage semantics.
- Provide a single traceability source bound to the provided ZID anchors.

**Non-Goals:**
- No new feature beyond the already validated runtime behavior.
- No redesign of the navigation engine or rendering architecture.
- No changes to unrelated search, tooltip aesthetics, or export mapping logic.

## Decisions

1. Treat `Esc` Stage 3 as a state-transition boundary, not only a visual-clear action.
- Rationale: Stage 3 is where manual interaction context ends; follow-leading must resume deterministically.

2. Keep null-pointer source resolution deterministic and mode-agnostic.
- Rationale: prevents stale line selection after seek/scroll and keeps DM/DW behavior coherent.

3. Synchronize standing line for null-pointer context after manual seek/scroll.
- Rationale: ensures first post-clear arrow activation always reflects current white-context state.

4. Extend Book Mode paging parity to DM mini viewport.
- Rationale: user workflow expects Book Mode semantics to be invariant across DW and DM.

5. Keep traceability in `openspec/specs` as a first-class capability.
- Rationale: this is normative state behavior history and must live with specs, not ad hoc docs.

## Risks / Trade-offs

- [Risk] Potential overlap between navigation and drum-window specs may duplicate language.
  - Mitigation: use one traceability capability and focused modified requirements per capability.

- [Risk] Future implementation may partially satisfy one mode (DW) and drift in DM.
  - Mitigation: explicitly state cross-mode parity in modified requirements and acceptance checklist.

- [Risk] Anchor-heavy narrative may become stale as code evolves.
  - Mitigation: keep the traceability spec concise and reference canonical requirement sections.
