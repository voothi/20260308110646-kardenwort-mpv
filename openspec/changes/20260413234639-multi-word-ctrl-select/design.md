## Context

The Drum Window currently supports two distinct selection gestures:

1. **LMB drag** — contiguous range selection with a red pending highlight; released without saving.
2. **MMB drag / click** — range selection that auto-saves on release (orange persistent highlight); single click exports the word under cursor or commits an existing LMB selection.

Neither gesture handles a **non-contiguous, discrete click-accumulation** workflow, which is necessary for language constructs where the relevant components are separated by unrelated words (e.g., *räumt … auf* for the separable verb *aufräumen*, or *look … up* for a phrasal verb). This design introduces a third gesture family gated behind the **Ctrl modifier key**, using an isolated accumulator state machine that co-exists cleanly with the existing two families.

---

## Goals / Non-Goals

**Goals:**
- Allow the user to click individual words (Ctrl+LMB) to accumulate a non-contiguous pending set highlighted in **yellow**.
- Allow the user to confirm and export the accumulated set by clicking any set member with **Ctrl+MMB**.
- Discard the accumulated set if the user releases Ctrl without committing.
- Produce a saved TSV record whose term field is the collected words joined by a space, in document order.
- Preserve all existing LMB drag, MMB drag, and MMB single-click behaviors without modification.

**Non-Goals:**
- Multi-set accumulation (only one pending Ctrl-set at a time).
- Span-across-subtitle-boundary accumulation (words from different subtitle blocks are supported by the existing inter-segment highlighter at render time; accumulation merely collects indices).
- Changing the export format or TSV schema.
- Reordering accumulated words (document order always wins).

---

## Decisions

### D1 — Dedicated Accumulator Table Instead of Reusing the Drag Range

**Decision**: The Ctrl-select state is held in a separate `ctrl_pending_set` table (array of `{line, word}` index pairs), independent of the existing `sel_start` / `sel_end` drag-range variables.

**Rationale**: The drag range is a contiguous interval that maps cleanly to `[start, end]` semantics. Non-contiguous clicks cannot be expressed as a single interval without structural coupling. Keeping them separate avoids conditionals scattered throughout the existing drag renderer and simplifies the rollback-on-Ctrl-release logic.

**Alternative considered**: Extending the range model to support a list of ranges — rejected because existing range logic (highlight coloring, word-join for export) assumes a single contiguous span, requiring invasive modification.

---

### D2 — Ctrl Modifier Detection via mpv's `script-binding` + Modifier Prefix

**Decision**: Register explicit bindings for `Ctrl+MBTN_LEFT` and `Ctrl+MBTN_MID` using mpv's modifier-prefix syntax (`ctrl+mbtn_left`, `ctrl+mbtn_mid`). Ctrl state for *release* is tracked via a boolean `ctrl_held` updated by `ctrl` key-down / up bindings that activate only when the Drum Window is open.

**Rationale**: mpv does not expose a continuous "is Ctrl held?" API between mouse events. The cheapest reliable approach is binding `ctrl` as a key that sets a flag on press and unsets it on release — a well-established pattern in other Drum Window keyboard bindings (`shift`, etc.).

**Alternative considered**: `mp.get_mouse_pos()` combined with asking mpv for modifier state via `mp.command_native` — not possible; mpv Lua doesn't expose modifier state outside of key/mouse event callbacks.

---

### D3 — Disambiguation: Ctrl+MMB on Non-Set Member → Plain MMB Behavior

**Decision**: When `Ctrl+MBTN_MID` fires and the word under the cursor is **not** in `ctrl_pending_set`, the system treats it identically to a plain `MBTN_MID` click (export that single word).

**Rationale**: This is the least-surprise behavior. If the user holds Ctrl but hasn't started a multi-pick session (or clicks outside the current set by mistake), they still get a useful outcome. It also keeps the gesture mnemonic consistent: MMB always means "export something."

---

### D4 — Term Composition: Document-Order Word Join

**Decision**: When committing, words in `ctrl_pending_set` are sorted by `(line_index, word_index)` and joined with a single space. No intervening filler words are inserted.

**Rationale**: "räumt … auf" is the user's intended export term. The TSV `word` field stores the literal picked tokens. The highlighter's existing inter-segment and windowed-neighborhood matching already handles re-matching these non-contiguous tokens across subtitle renders.

---

### D5 — Color Token: Yellow for Pending, No New Color for Saved

**Decision**: Pending Ctrl-picks are rendered in a configurable **yellow** (`ctrl_select_color`, default `#FFE066`). After commit, the saved record uses the standard **orange** saved-highlight path — no new color tier for saved Ctrl-selections.

**Rationale**: Yellow clearly signals "not yet saved" within the existing red (drag-pending) → orange (saved) color language. Adding a new saved color for Ctrl-exports would complicate the renderer and confuse recall (the user should associate orange = "in Anki" regardless of how it got there).

---

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| Ctrl key binding conflicts with mpv system shortcuts (e.g., Ctrl+Q) | Bind only `ctrl+mbtn_left` and `ctrl+mbtn_mid`; `ctrl` key itself is bound only while Drum Window is active |
| User accidentally adds a word by a mis-click and doesn't realize the set is dirty | Yellow visual indicator is persistent; releasing Ctrl without MMB clears it with a brief flash (no permanent side effect) |
| Words in `ctrl_pending_set` become stale if the subtitle viewport scrolls | Set is keyed by `(line_index, word_index)` from the current render frame; a scroll event that shifts lines should clear the pending set (same as releasing Ctrl) for safety |
| Ctrl+MMB on a set member that coincides with an existing saved word triggers double-export | Export function is idempotent at the TSV level (duplicate term at same timestamp is a no-op or update); no data corruption |
| Long accumulated sets produce an unwieldy TSV term | By design — the user is explicitly constructing a compound. No truncation imposed at accumulation time |

---

## Migration Plan

No schema or file-format migration needed. The feature is purely additive at the TSV level. New Lua state variables and bindings activate only when the Drum Window opens and clean up when it closes — no global state leaks.

**Rollback**: Remove the three new binding registrations (`ctrl+mbtn_left`, `ctrl+mbtn_mid`, `ctrl` key pair) and the `ctrl_pending_set` accumulator table. All other existing behaviors are unaffected.

---

## Open Questions

- **OQ1**: Should scrolling during an active Ctrl-set clear the set, or attempt to remap indices to the new viewport? (Proposed: clear for simplicity; revisit if UX feedback suggests remapping is needed.)
- **OQ2**: Should toggling Book Mode while a Ctrl-set is active preserve or discard the set? (Proposed: discard — Book Mode changes the conceptual context.)
- **OQ3**: Should the `ctrl_select_color` be exposed in `mpv.conf` from day one, or only after user demand? (Proposed: include from day one, with a clear default.)
