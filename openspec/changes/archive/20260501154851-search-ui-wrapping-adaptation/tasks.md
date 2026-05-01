## 1. Input Field Adaptation

- [x] 1.1 Integrate `wrap_tokens` into the `display_query` construction logic to determine visual line count.
- [x] 1.2 Calculate `input_box_h` dynamically in `draw_search_ui` using `query_lines * line_height + padding_y * 2`.
- [x] 1.3 Update the input field background path rendering to use the dynamic `input_box_h`.
- [x] 1.4 Ensure the search cursor `|` is correctly positioned within the wrapped `display_query`.

## 2. Dropdown Positioning & Layout

- [x] 2.1 Refactor `results_y` calculation to be relative to the dynamic bottom of the input field.
- [x] 2.2 Modify the results processing loop to calculate visual line counts for each displayed result via `wrap_tokens`.
- [x] 2.3 Aggregate these line counts to determine the total `results_h` for the dropdown background.
- [x] 2.4 Update the dropdown background path rendering to use the dynamic `results_h`.

## 3. Result Item Rendering

- [x] 3.1 Replace the fixed `(k - 1) * line_height` offset with a cumulative `current_y` tracker.
- [x] 3.2 Update result text rendering to use the cumulative `current_y`.
- [x] 3.3 Verify that hit highlights and selection colors correctly apply to all visual lines of a wrapped result.

## 4. Verification & Polish

- [x] 4.1 Verify that long queries (wrapping to 2+ lines) correctly expand the input box and push the dropdown down.
- [x] 4.2 Verify that long results correctly expand the dropdown and don't overlap subsequent items.
- [x] 4.3 Ensure "No results found" placeholder still renders correctly with the new layout logic.
