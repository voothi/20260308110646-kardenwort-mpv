# Design: Search Selection Fix (Scoping Bug)

## System Architecture
The fix involves structural changes to the utility section of `lls_core.lua` and variable name alignment in the Drum Window command handlers.

### Components
1.  **Utility Logic**:
    - Reordered function definitions: `is_word_char` → `get_word_boundary`.
    - This ensures the lexical scope is correctly populated when `get_word_boundary` is parsed and executed.
2.  **Drum Window State**:
    - Unified variable naming: Ensuring all selection-related state fields in the Drum Window use the `DW_` prefix (e.g., `DW_ANCHOR_LINE`).

## Implementation Strategy
- **Code Reordering**: Move the `is_word_char` block to a line number preceding any calls to it.
- **Variable Audit**: Search for legacy `ANCHOR_LINE` (without `DW_` prefix) within Drum Window functions and update them to `DW_ANCHOR_LINE`.
- **Error Trapping**: While Lua's `local` scoping is strict, ensuring these base utilities are defined early in the file is a standard best practice for the script's architecture.
