# Proposal: Rework String Preparation for Export

## Problem
The current mechanism for preparing strings for the clipboard and TSV export is inconsistent, redundant, and often destructive. Key issues include:
- **Destructive Cleaning**: The `clean_anki_term` function aggressively strips symbols and punctuation that the user may have explicitly selected.
- **Inconsistent Joining**: Some paths use `compose_term_smart` (which applies OSD typography rules, potentially altering original spacing), while others use ad-hoc concatenation.
- **Granulation Discrepancy**: While the mouse can select symbols (fractional indices), the export logic often flattens or cleans these away, leading to a "what you see is NOT what you get" experience.
- **Code Duplication**: String preparation logic is spread across `cmd_dw_copy`, `cmd_copy_sub`, `dw_anki_export_selection`, and `ctrl_commit_set`, leading to maintenance overhead and behavioral drift.

## Proposed Solution
Unify all string preparation logic into a single, high-fidelity export engine (`prepare_export_text`).
- **Verbatim Preservation**: Prioritize original subtitle tokens and spacing for both clipboard and TSV exports.
- **Selection Fidelity**: Use `logical_idx` comparison (including fractional parts) to honor the exact granulation of the user's selection (keyboard or mouse).
- **Consolidated Path**: Replace ad-hoc logic in all export call sites with the new unified engine.
- **Surgical Cleaning**: Update cleaning rules to preserve selected symbols while still handling mandatory tasks like ASS tag removal and space normalization.

## Goals
- Restore "Copy as is" fidelity: what is selected is what is exported.
- Eliminate discrepancies between keyboard and mouse selection exports.
- Reduce code complexity by centralizing export string reconstruction.
- Ensure consistency between clipboard copies and TSV mining records.
