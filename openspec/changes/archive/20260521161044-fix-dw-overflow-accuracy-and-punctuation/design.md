## Context

The Drum Window (DW) mode is a high-precision subtitle reader and highlight-mining tool inside Kardenwort. It uses mpv's ASS OSD rendering engine to present a vertical subtitle track context centered around the current active line.
However, extreme layout heights (e.g., low OSD resolution, massive fonts, or heavy multi-line wraps) caused elements to render off-screen with no way to scroll them back in. In addition, independent coordinate mapping calculations in the mouse hit-tester caused cumulative vertical drift in clicked coordinates, making click targeting inaccurate at the bottom of the list.

## Goals / Non-Goals

**Goals:**
- Provide a robust layout centering and safe-area clamping mechanism to keep all subtitles reachable.
- Support a configurable safe margin (`dw_edge_margin`) to prevent text from rendering flush against the screen edges.
- Decouple the intra-subtitle wrap line height (`dw_wrap_line_height_mul`) to eliminate text overlap for descenders (e.g. `g`, `j`, `y`).
- Unify hit testing and rendering coordinate maps through a single cached hit-zone geometry table to achieve 100% click-targeting accuracy.
- Fix translation tooltip formatting crash and unify punctuation selection rules between Drum Mode (DM) and Drum Window (DW).

**Non-Goals:**
- Altering the main subtitle parsing pipelines or TSV file layout formats.
- Modifying standard font sizes or line spacing rules for core Drum Mode (DM) visuals.

## Decisions

### Decision 1: Render-Driven Hit-Zone Caching (Option A)
- **Rationale**: Previously, `draw_dw` and `dw_hit_test` computed the layout geometry independently. This resulted in spatial drift on multi-wrapped lines because the hit-test model's spacing did not match the ASS engine's true font spacing metrics. By populating a shared cache table `FSM.DW_HIT_ZONES` during `draw_dw` and reading from it in `dw_hit_test`, rendering and interactivity are guaranteed to be 100% aligned regardless of font or scaling configurations.
- **Alternatives Considered**: Option B (dynamically calculating actual font metrics at runtime). This was rejected as mpv does not expose low-level font metrics easily, and it would introduce significant performance overhead.

### Decision 2: Decoupled Intra-Subtitle Wrap Spacing
- **Rationale**: Under multi-line wrapping, characters with descenders (e.g., `g`, `j`, `y`) overlapped with the line below because the default line spacing multiplier (0.87) was too tight. Introducing a distinct option `dw_wrap_line_height_mul = 1.05` for intra-subtitle lines allows generous visual breathing room while preserving the tight inter-subtitle block gaps.
- **Alternatives Considered**: Globally increasing `dw_line_height_mul`, but this caused adjacent subtitles to be spaced too far apart.

### Decision 3: Custom Safe-Area Margin Clamping
- **Rationale**: Clamping block offsets directly to `0` or `1080` forced text to touch the screen boundaries under overflow conditions. Adding a configurable `dw_edge_margin` (default 24px) guarantees safe padding on both ends of the screen, enhancing readability.

## Risks / Trade-offs

- **[Risk]**: Interactivity cache desynchronization across frame updates or seek actions.
  - **Mitigation**: We clear the `FSM.DW_HIT_ZONES` and `FSM.DW_LINE_Y_MAP` tables at the start of every render and ensure the cache table is updated and restored on cache-hits within `DW_DRAW_CACHE`.
- **[Risk]**: Punctuation selection in Drum Mode (DM) could trigger search index collisions.
  - **Mitigation**: Verified that downstream selection, highlight color toggling, and Anki exporting pipelines naturally support fractional logical indexes associated with punctuation characters.
