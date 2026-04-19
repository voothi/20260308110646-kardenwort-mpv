## Context

The Drum Window (Mode W) is the primary subtitle mining interface. Current interaction requires specific combinations (e.g., Ctrl+MMB) that are difficult to map to limited-button remote controls like the 8BitDo Zero 2. The configuration is also color-coupled (e.g., `dw_mark_pink_key`), which is fragile.

## Goals / Non-Goals

**Goals:**
- Provide 100% parity between mouse and keyboard mining actions.
- Implement "Smart Add" logic that automatically handles contiguous and paired selections.
- Decouple configuration from UI colors and layout names.
- Support multiple inputs per action via flexible, multi-delimiter lists.

**Non-Goals:**
- Removing legacy modifier support (Ctrl+MMB is preserved via explicit mapping).
- Changing the underlying TSV export format.

## Decisions

- **Multi-Delimiter Parser**: Use a robust string scanning approach (`[^%s,;]+`) to treat spaces, commas, and semicolons as valid separators. This allows users to avoid "comma as a divider" conflicts.
- **Unified Action-Based Names**: Standardized on `dw_key_...` prefixes to group interactions logically (Add, Pair, Tooltip).
- **Context-Aware Callbacks**: Refactored mining functions to check the word type under the cursor/mouse rather than relying on the specific key pressed. This enables a single button to perform different logical actions (add single vs. commit pair).
- **Explicit Modifier Mapping**: Instead of hardcoding `Ctrl` behavior, it is now explicitly defined in the `dw_key_add` list. The script still automatically identifies the primary mouse button for context-specific behavior.

## Risks / Trade-offs

- **[Delimiter Conflict]** → Users might want to use a space or comma as a key. **Mitigation**: Encourage using `SPACE` and `COMMA` token names, and support multiple delimiters so the user can choose the clearest one.
- **[Overlapping Bindings]** → `r` and `t` are globally used for subtitle positioning. **Mitigation**: These are forced only when the Drum Window is active, preserving their original function during normal playback.
