# Frame-by-Frame Analysis: Tooltip Flickering (ZID: 20260511111144)

## Metadata
- **Source**: `C:/Users/voothi/Videos/Recording 2026-05-11 105230.mp4`
- **Target**: `dw_tooltip_osd`
- **Context**: Fragment2 ("Es sind pro Stunde um die 800 Sendungen")
- **Cursor Position**: Fixed over "die"

## Timeline Analysis

| Timestamp (s:ms) | Observation | Internal State Hypothesis |
| :--- | :--- | :--- |
| 00:00:050 | Tooltip appears over word "die". Rendering is stable for < 50ms. | Initial `update()` call triggers. |
| 00:00:100 | First flicker: Tooltip disappears entirely for 1 frame. | Cache miss or `clear()` followed by deferred `update()`. |
| 00:00:150 | Tooltip reappears but slightly offset (approx 1-2px vertical shift). | Floating point jitter in `osd_y` calculation. |
| 00:00:200 | Second flicker: "Z-fighting" appearance between tooltip and DW background. | Multiple OSD layers competing or redundant `resync`. |
| 00:00:250 - 00:00:800 | Continuous cyclical flashing at ~20Hz frequency. | `dw_tooltip_mouse_update` calling `update()` on every master tick. |

## Detailed Findings

1. **Strobe Effect**: The flickering is not random; it follows the 50ms (20Hz) master tick cycle. This confirms the issue is tied to the main event loop rather than an external rendering conflict.
2. **Vertical Jitter**: During the reappear phase of several flickers, the tooltip box shifts vertically by a sub-pixel amount. This indicates that `osd_y` is being recalculated with slightly different values (likely due to floating-point precision in the parent layout alignment).
3. **Partial Transparency**: In several frames, the tooltip border is visible while the text content is missing. This suggests the OSD string generation is failing or being cleared mid-render cycle.

## Conclusion
The evidence strongly supports the "Redundant Updates" and "Cache Instability" hypotheses. The fix must enforce:
1. **Idempotency**: Do not update if the content hasn't changed.
2. **Quantization**: Round OSD coordinates to the nearest integer.
