# Design: Export Engine Simplification and Gap Alignment

## Context
The `prepare_export_text` service currently manages three distinct export modes with overlapping "smart" logic for sentence reconstruction. The "Sentence Punctuation Restoration" feature has proven to be a source of parity regressions and violates the user's expectation of verbatim data fidelity. Furthermore, the cross-line gap detection is currently hardcoded to trigger ellipses on any line transition, even when tokens are contiguous in the dialog.

## Goals / Non-Goals

**Goals:**
- Eliminate non-verbatim text modification (Sentence Restoration).
- Unify selection behavior across `RANGE`, `SET`, and `POINT` modes by removing mode-specific restoration passes.
- Implement "Adaptive Gap Detection" to support seamless cross-line text joining.
- Reduce code complexity and remove orphaned helpers (`starts_with_uppercase`).

**Non-Goals:**
- Modifying the underlying tokenization engine (`build_word_list_internal`).
- Changing the `clean_anki_term` behavior (metadata stripping).
- Modifying UI/OSD rendering logic (which uses `compose_term_smart`).

## Decisions

### 1. Deprecation of Sentence Restoration
We will remove the final conditional block in `prepare_export_text` that evaluates `options.restore_sentence`. 
- **Rationale**: Strict adherence to verbatim fidelity.
- **Cleanup**: Remove `starts_with_uppercase` and associated multi-pass lookahead logic in `RANGE` and `SET` branches.

### 2. Adaptive Gap Implementation (SET Mode)
We will refine the `has_gap` evaluation in `SET` mode.
- **Current**: `has_gap = (m.line > last_m.line) or (m.word > last_m.word + 1.05)`
- **New**: 
  - Same line: `m.word > last_m.word + 1.05`
  - Different line (Consecutive): `m.line == last_m.line + 1`. Check if any words exist between `last_m.word` and the end of `last_m.line`, and before `m.word` on its line.
  - Different line (Jump): `m.line > last_m.line + 1` -> Always gap.
- **Implementation**: Leverage `get_sub_tokens` which provides cached, logic-indexed tokens for rapid adjacency verification.

### 3. Removal of Parity Logic
Requirement 153 is deprecated. Modes no longer need to synchronize lookahead state because the lookahead itself is being removed.

## Risks / Trade-offs
- **Risk**: Users who relied on the "auto-period" feature for sentence mining will now have to manually include the period in their selection.
- **Mitigation**: Update UI tooltips or documentation to clarify that exports are now strictly verbatim.
- **Trade-off**: Slightly higher CPU usage during cross-line Pink selection due to adjacency checks, mitigated by the existing `get_sub_tokens` cache.
