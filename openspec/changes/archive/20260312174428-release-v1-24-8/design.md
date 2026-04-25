## Context

The transition to a more complex search and reading environment introduced several "edge case" bugs. Users reported UI elements rendering in the wrong order, script crashes when typing rapidly, and desynchronization when using ASS subtitles. This release addresses these points through structural hardening and algorithmic improvements.

## Goals / Non-Goals

**Goals:**
- Implement a truly fuzzy search that supports partial, non-contiguous queries.
- Ensure the Search HUD always renders on top of other elements.
- Fix desynchronization for ASS subtitles.
- Prevent crashes caused by Lua's late-binding of functions.

## Decisions

- **Fuzzy Matching**: `is_fuzzy_match` is implemented using a pointer-based character-order check. It ensures that characters in the query appear in the same order in the target string, regardless of what's between them.
- **Layering Enforcement**: Every OSD object used by the script is explicitly assigned a `z` property to dictate its stack priority. This prevents native subtitles from covering the Search HUD.
- **Code Relocation**: Command functions like `cmd_dw_*` are moved to the top of `lls_core.lua`. This guarantees they are "in scope" and defined before any `mp.add_forced_key_binding` calls are made.
- **Centisecond Math**: The subtitle parser is updated to detect 2-digit time fields in the centisecond position and multiply them by 10 to normalize them into milliseconds for internal use.

## Risks / Trade-offs

- **Risk**: Fuzzy search matching too many irrelevant items.
- **Mitigation**: The algorithm remains strict about character order, maintaining high relevance despite the increased flexibility.
