# Proposal: Fix Phrase Highlighting Bleed

## Summary

Resolve an issue where selecting multi-word phrases causes excessive highlighting across multiple subtitle lines, even when global highlighting is disabled. This is primarily due to logic in `lls_core.lua` that expands the search window for phrases and relaxes context strictness checks.

## Why

Currently, when a user selects a phrase (multi-word term) like "41 bis 45":
1. The script expands the local time window to +/- 15 subtitle records (`min_scan` to `max_scan`).
2. The script relaxes "strict" context matching because the term has more than one word (`#term_clean > 1`).
3. If the phrase repeats within that 30-line window, all instances are highlighted, leading to "bleed" and visual confusion.

The goal is to ensure that even for multi-word phrases, highlighting is precisely targeted to the selected occurrence when context strictness is enabled or when working in local-only mode.

## What Changes

- Modify `lls_core.lua` to refine the `needs_strict` logic for multi-word phrases.
- Ensure that the logical index of the selection is prioritized to prevent neighbor-match bleed.
- Update default configuration suggestions to encourage `anki_context_strict=yes` for users experiencing this issue.

## Capabilities

### New Capabilities
- None (This is a precision/bug fix).

### Modified Capabilities
- `subtitle-rendering`: Improved precision for multi-word phrase highlighting in the Drum Window.
- `drum-window`: Enhanced selection isolation for repeating phrases.

## Impact

- `scripts/lls_core.lua`: Refactoring of `calculate_highlight_stack` and context matching logic.
- `mpv.conf`: (Configuration advice) Encouraging use of `lls-anki_context_strict=yes`.
