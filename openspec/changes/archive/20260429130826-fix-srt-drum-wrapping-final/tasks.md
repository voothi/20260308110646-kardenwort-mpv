# Tasks: Implement SRT Wrapping and Fix Rendering Crashes

## 1. Core Layout Logic
- [x] 1.1 Implement `wrap_tokens` utility to handle automatic and forced breaks.
- [x] 1.2 Refactor `calculate_osd_line_meta` to return multi-line geometry objects.
- [x] 1.3 Update width/height calculations to support variable line counts.

## 2. Rendering and Hit-Zones
- [x] 2.1 Update `draw_drum` to flatten multi-line metadata into a visual line list.
- [x] 2.2 Re-implement `format_sub` (as `format_sub_wrapped`) to generate multi-line ASS text using `\N`.
- [x] 2.3 Adjust global Y-coordinate logic to accommodate expanded multi-line blocks.

## 3. Stability and Polish
- [x] 3.1 Fix Lua `table.insert` expansion crash by wrapping multi-return `gsub` calls in parentheses.
- [x] 3.2 Ensure source `\n` characters are cleaned from final rendered strings to prevent ASS artifacts.
- [x] 3.3 Verify centering and spacing consistency between Active and Context subtitles.
