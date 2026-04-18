## Why

When users highlight/study non-adjacent words as a "paired selection," the system currently saves them as a standard phrase. This causes the high-recall highlighting engine to mark all contiguous occurrences of those same words in orange, which can be distracting and unhelpful if the user only intended to study the split grammatical relationship. Incorporating ellipses into the saved term allows the system to distinguish between these two modes.

## What Changes

- **Adaptive Paired Saving**: When a multi-word selection is saved, the system checks if the words were contiguous in the source subtitle. If they were split by other words or punctuation, it automatically joins them with a space-padded ellipsis (exact string: ` ... `) in the WordSource field (e.g., `Sie ... Hören`).
- **Split-Aware Highlighting**: The highlighting engine will recognize terms containing ellipses as "Split-Only" records. 
- **Matching Logic Refinement**: 
    - Terms with ellipses will be ignored by Phase 1 (Contiguous) matching to prevent "orange bleed" on adjacent phrases.
    - These terms will strictly trigger Phase 3 (Split) matching.
    - Contiguous terms (without ellipses) will continue to match both contiguous and split instances for maximum recall (unless specific user configuration dictates otherwise).

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `window-highlighting-spec`: Update highlighting rules to recognize and prioritize elliptical split-only terms.
- `anki-export-mapping`: Update the save/export logic to detect non-contiguity and inject `...` joiners.

## Impact

Affects the core logic in `lls_core.lua`, specifically `save_anki_tsv_row` and the sequence matching loop in `calculate_highlight_stack`. It requires no changes to external dependencies or the TSV schema as the ellipsis is a valid string character.
