## Context

The `expand_ru_keys` engine dynamically generates Cyrillic key variants for English inputs to support layout-agnostic operation. In the ЙЦУКЕН layout, the physical `E` key corresponds to `у` (lowercase) and `У` (uppercase). mpv on Windows normalizes `Shift+character` bindings to the uppercase variant. Registering an explicit `Shift+у` binding creates an ambiguity where the unshifted `у` key might fire the shifted action.

## Goals / Non-Goals

**Goals:**
- Eliminate false positive triggers for shifted hotkeys when unshifted keys are pressed in the RU layout.
- Ensure strict case parity in the expansion engine.
- Provide granular diagnostic tracing for hotkey registration and runtime trigger events.

**Non-Goals:**
- Modifying the underlying mpv key-binding engine.
- Supporting non-standard keyboard layouts outside of standard ЙЦУКЕН.

## Decisions

### 1. Strict Shift-Cyrillic Normalization
- **Decision**: For all keys with an explicit `Shift+` modifier, the expansion engine will register only the uppercase Cyrillic character (e.g., `У`) and omit the `Shift+lowercase` variant (e.g., `Shift+у`).
- **Rationale**: mpv on Windows canonicalizes Shift+Cyrillic to the uppercase character. Registering `Shift+у` is redundant at best and causes false positives at worst.

### 2. Diagnostic Binding Wrappers
- **Decision**: Wrap all global and Drum Window key registrations in a diagnostic callback.
- **Rationale**: Allows runtime identification of which physical key triggered which logical binding, essential for debugging "ghost" triggers.

### 3. Option Default Sanitization
- **Decision**: Remove hardcoded Russian characters from default option strings (e.g., `dw_key_tooltip_toggle = "e у"` becomes `"e"`).
- **Rationale**: Prevents accidental double-registration or logic-bypassing collisions.

## Risks / Trade-offs

- **[Risk]** Potential breakage on non-Windows platforms if they expect explicit `Shift+lowercase` strings.
- **[Mitigation]** The change is primarily focused on the `expand_ru_keys` logic which is specifically tuned for Windows/ЙЦУКЕН behavior in this project.
