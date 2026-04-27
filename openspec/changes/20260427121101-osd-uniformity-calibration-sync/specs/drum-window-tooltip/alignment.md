# Specification: Tooltip Alignment and Interval Sync

## Precision Centering
When `tooltip_y_offset_lines = 0`, the tooltip's active line midpoint must align perfectly with the target OSD line midpoint.

### Formula
1.  **Block Height**: `(num_lines * layout_line_h) + ((num_lines-1) * (gap_size + block_gap))`
2.  **Vertical Positioning**: 
    - The tooltip uses `{\an6}` or `{\an4}` (Right/Left Center alignment).
    - The `\pos(x, final_y)` coordinate uses `final_y = target_osd_y + (offset * logical_interval)`.
    - `logical_interval = layout_line_h + (double_gap ? layout_line_h : 0) + block_gap`.

## Interval Synchronization
The tooltip renderer (`draw_dw_tooltip`) must use the same `line_height_mul` and `block_gap_mul` as the Drum Window (`dw`) to ensure that context lines in the translation tooltip align visually with the context lines in the navigation window.
