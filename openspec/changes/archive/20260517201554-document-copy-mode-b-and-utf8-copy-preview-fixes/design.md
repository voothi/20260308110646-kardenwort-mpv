## Context

Dual-subtitle mining depends on deterministic routing between primary and secondary subtitle tracks. Recent runtime findings showed a path split: no-selection copy respected mode `B`, but manual selection export (`SET`/`RANGE`) still read primary data. In parallel, DW preview truncation used byte indexing, which is unsafe for UTF-8 and corrupted Cyrillic previews in OSD.

## Goals / Non-Goals

**Goals:**
- Enforce one copy-source contract for all export selection shapes (`POINT`, `RANGE`, `SET`) based on `FSM.COPY_MODE`.
- Guarantee UTF-8-safe preview truncation for DW copy feedback.
- Add deterministic regression coverage that validates truncation and preview formatting without flaky runtime timing dependencies.

**Non-Goals:**
- No redesign of general OSD cooldown policy.
- No changes to search rendering or tooltip content.
- No schema/API changes for external tools.

## Decisions

- Introduce a unified source selection in export preparation.
: `prepare_export_text` resolves `target_subs` once from `COPY_MODE`, then all branches consume it.
Alternative considered: patch each branch independently. Rejected due to drift risk and duplicated logic.

- Use character-aware truncation via `utf8_to_table` and `utf8_truncate`.
: Prevents splitting multibyte characters and mojibake artifacts.
Alternative considered: byte-length clipping + sanitize fallback. Rejected because corruption is already at slicing boundary.

- Centralize preview string creation with `build_copy_preview(label, text, max_chars)`.
: Keeps runtime and test instrumentation consistent.
Alternative considered: keep inline concatenation in each callsite. Rejected due to future inconsistency risk.

- Add test instrumentation hook for deterministic preview assertions.
: `test-build-copy-preview` allows verification independent of OSD cooldown and paused playback clock behavior.
Alternative considered: runtime OSD assertions only. Rejected due to known non-determinism from cooldown gates.

## Risks / Trade-offs

- [Risk] Slight behavior change in mode `B` for users who unknowingly depended on old selection bug.
: Mitigation: explicitly document that mode `B` now always exports secondary for all selection types.

- [Risk] Additional helper/test hook increases surface area.
: Mitigation: hook remains test-only usage and does not alter production command map semantics.

- [Risk] Existing tests may assume byte-based truncation behavior.
: Mitigation: add explicit UTF-8 expectations and keep truncation length stable.
