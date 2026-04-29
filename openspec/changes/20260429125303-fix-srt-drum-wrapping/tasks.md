# Tasks: Fix SRT Drum Wrapping

## 1. Refactor Layout Engine

- [ ] 1.1 Extract or implement a wrapping utility function that splits tokens into visual lines based on `max_text_w` (1860px).
- [ ] 1.2 Refactor `calculate_osd_line_meta` to return an array of line metadata objects instead of a single object.
- [ ] 1.3 Ensure `total_width` and `height` in metadata reflect the multi-line block.

## 2. Update OSD Rendering Loop

- [ ] 2.1 Update `draw_drum` (hit-zone calculation block) to iterate over the multi-line metadata returned by `calculate_osd_line_meta`.
- [ ] 2.2 Update `format_sub` or the loop in `draw_drum` to insert `\N` between visual lines.
- [ ] 2.3 Adjust the `y_pixel` and `total_h` calculations in `draw_drum` to account for the increased height of wrapped subtitles.

## 3. Preservation of Source Newlines

- [ ] 3.1 Review `build_word_list_internal` and `format_sub` to ensure `\n` is either preserved or translated to `\N`.
- [ ] 3.2 Verify that `Options.dw_original_spacing` correctly preserves newline tokens.

## 4. Testing and Validation

- [ ] 4.1 Test with the user-provided example SRT (long sentences).
- [ ] 4.2 Verify that secondary subtitles (if overlapping or enabled) are correctly positioned relative to wrapped primary subtitles.
- [ ] 4.3 Confirm hit-testing still works for words on wrapped lines in both Drum and Regular OSD modes.
