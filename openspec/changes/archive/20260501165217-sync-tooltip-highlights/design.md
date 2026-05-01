## Context

The Drum Window Tooltip currently renders secondary subtitles as plain text. While the Drum Window (Primary) uses a complex rendering pipeline to show highlights, the tooltip rendering loop in `draw_dw_tooltip` only concatenates raw token text. This lacks synchronization with the user's active selections (Yellow/Pink).

## Goals / Non-Goals

**Goals:**
- Inject the highlight engine (`populate_token_meta`) into the tooltip rendering loop.
- Synchronize Yellow Pointer and Pink Set highlights to the tooltip text.
- Maintain surgical highlighting (uncolored punctuation) in the tooltip.

**Non-Goals:**
- Implementing complex temporal alignment for non-matching tracks (we assume 1:1 index mapping as per the user's "just like Mode C" request).
- Adding new colors specifically for the tooltip.

## Decisions

- **Token Meta Injection**: Call `populate_token_meta(Tracks.sec.subs, i, tokens, base_color, sub.start_time)` for each secondary line `i` in the tooltip.
- **Surgical Formatting**: Use `format_highlighted_word(tokens[idx], token_meta[idx].color, base_color, token_meta[idx].is_phrase, bold, true)` to construct the OSD strings.
- **Cache Invalidation**: Update `DW_TOOLTIP_DRAW_CACHE` to include `FSM.DW_CURSOR_LINE`, `FSM.DW_CURSOR_WORD`, and `FSM.ANKI_VERSION` to ensure highlights update responsively.

## Risks / Trade-offs

- **Performance**: Calling `populate_token_meta` and `format_highlighted_word` for tooltip lines adds some overhead. However, the tooltip is small (usually 1-3 lines) and uses an O(1) draw cache, so the impact will be negligible.
- **Index Misalignment**: If the secondary track has a different line count, the highlights might appear on the "wrong" line index. Rationale: This is acceptable as it matches the current Mode C behavior requested by the user.
