## 1. Specification Alignment

- [x] 1.1 Update `openspec/specs/inter-segment-highlighter/spec.md` to change the temporal gap from 1.5s to 60.0s.

## 2. Code Cleanup

- [x] 2.1 Delete lines 5741-5742 in `scripts/lls_core.lua` (redundant `book-mode-b` and `book-mode-ru` bindings).

## 3. Verification & Archiving

- [x] 3.1 Verify that `b` and `и` still work as expected (already confirmed by audit of `input.conf` and `lls_core.lua:5740`).
- [x] 3.2 Archive the change `20260425221654-spec-alignment-and-binding-cleanup`.
- [x] 3.3 (Optional) Re-archive the previous audit change if necessary.
