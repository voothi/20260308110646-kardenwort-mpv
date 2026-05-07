## Context

`calculate_highlight_stack` in `scripts/lls_core.lua` iterates over all candidate TSV records to compute an `orange_stack`, `purple_stack`, and `has_phrase` result for a single word position. The `has_phrase` boolean governs how `format_highlighted_word` renders the backlight: `true` → full-word color (Phrase Continuity Mode); `false` → surgical highlighting (punctuation isolated from the colored token body).

The bug was introduced because `has_phrase` was assigned unconditionally inside the match accumulation block:

```lua
if match_found then
    ...
    matched_terms[term_key] = true
    has_phrase = (#term_clean > 1)   -- ← overwrites, doesn't accumulate
    ...
end
```

Since candidates are iterated in TSV row order, a single-word record appearing after a phrase record would reset the flag.

## Goals / Non-Goals

**Goals:**
- Make `has_phrase` order-independent: the flag is `true` iff at least one matched term is multi-word.
- Keep the fix minimal — no refactoring of adjacent logic.

**Non-Goals:**
- Changing how `orange_stack` / `purple_stack` are accumulated.
- Altering the candidate ordering or deduplication strategy.

## Decisions

### 1. Monotone accumulation for `has_phrase`

Replace the unconditional assignment with a logical OR:

```lua
-- before
has_phrase = (#term_clean > 1)

-- after
has_phrase = has_phrase or (#term_clean > 1)
```

**Rationale:** `has_phrase` is semantically "does this word participate in at least one phrase match?" — a property that should be `true` once any phrase matches, regardless of what follows. The OR idiom is the minimal expression of this invariant and makes the intent explicit to future readers.

**Alternative considered:** Sorting candidates so phrase records always appear last, ensuring the last assignment is correct.
- **Pros:** Preserves the existing assignment semantics.
- **Cons:** Ordering candidates introduces fragility for future features; the root cause (unconditional overwrite) remains latent.

## Risks / Trade-offs

- **Risk:** None. The change is a boolean OR on a local variable; it cannot affect `orange_stack`, `purple_stack`, `purple_depth`, or `matched_terms`.
- **Trade-off:** None — this is a strict correctness fix with no observable regression surface.
