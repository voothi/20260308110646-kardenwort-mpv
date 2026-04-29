# Design: SRT Subtitle Wrapping for OSD Rendering

## Context
The project uses custom OSD overlays (`mp.create_osd_overlay("ass-events")`) to render subtitles with premium styling and interactivity (word-level highlighting). The current implementation in `draw_drum` assumes each subtitle is a single horizontal line. Long SRT subtitles, which are often sentences grouped by the user, exceed the screen width and are cut off because of the `{\q2}` (no-wrap) tag and lack of multi-line layout logic.

## Goals / Non-Goals

**Goals:**
- Implement manual word-wrapping for `draw_drum` OSD.
- Preserve hit-testing accuracy for all words on all wrapped lines.
- Maintain vertical spacing consistency between wrapped lines and context lines.

**Non-Goals:**
- Switching back to native `mpv` subtitle rendering (OSD rendering is required for the premium style).
- Implementing full ASS-spec wrapping (we only need word-level wrapping for our custom renderer).

## Decisions

### 1. Manual Wrapping vs. Native Wrapping
We will use **Manual Wrapping**. By calculating where lines break within the script, we can accurately populate `FSM.DRUM_HIT_ZONES` with the correct (x, y) coordinates for every word. Native wrapping (`{\q0}`) would make word-level hit-testing nearly impossible without complex OSD-to-screen coordinate mapping.

### 2. Multi-Line Metadata Structure
`calculate_osd_line_meta` will be refactored to return an array of line objects. Each object will contain:
- `words`: List of words on that specific visual line.
- `total_width`: Width of that visual line.
- `y_offset`: Vertical offset relative to the subtitle's starting Y.

### 3. Rendering Logic in `draw_drum`
`draw_drum` will iterate through these visual lines and append `\N` tags where appropriate. It will also adjust the total height calculation for a subtitle block to ensure context lines don't overlap with wrapped active lines.

## Risks / Trade-offs

**Heuristic Accuracy:** The script uses a width heuristic for proportional fonts. While generally accurate, extreme cases or unusual fonts might result in slightly off-center text or unexpected wrapping. This is mitigated by using a safe margin (e.g., 1860px instead of 1920px).

**Performance:** Re-calculating layout every tick could be expensive for very large subtitle files. We will leverage the existing caching patterns (similar to `FSM.DW_LAYOUT_CACHE`) if performance becomes an issue.
