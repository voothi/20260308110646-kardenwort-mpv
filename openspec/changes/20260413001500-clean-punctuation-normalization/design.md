## Context

Subtitle words often include trailing punctuation (e.g., `Bühne.`, `Knie,`). These should be highlighted as clean words for a premium aesthetic and exported to Anki without the punctuation for better dictionary matching.

## Goals / Non-Goals

**Goals:**
- Surgical separation of ASCII punctuation from UTF-8 word bodies.
- Consistent behavior across all rendering modes (Drum, Window) and capture methods (Copy/Export).

## Decisions

### 1. Regex Punctuation Classes
**Decision**: Use Lua's `%p` (Punctuation) and `%s` (Space) classes for boundary removal.
**Rationale**: Unlike custom byte-counting logic, `%p` specifically avoids multi-byte UTF-8 sequences in Lua 5.1/LuaJIT. This ensures Umlaute (`ü`, `ß`) are preserved while trailing periods and commas are stripped.

### 2. Highlighting Layering
**Decision**: Separate each word into `prefix`, `body`, and `suffix` before applying color tags.
**Rationale**: By applying the `{\\c&H...&}` tag only to the `body`, the punctuation naturally inherits the subtitle's base color, resulting in a cleaner "word highlight" effect.

## Risks / Trade-offs

- [Risk] → Some multi-character punctuation (e.g., `...`) might be treated as purely punctuation with no body.
- [Mitigation] → The logic will fallback to coloring the whole string if no alphanumeric body is detected.
