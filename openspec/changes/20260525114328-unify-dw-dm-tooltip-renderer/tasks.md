## 1. Renderer Diagnosis And Guard Rails

- [x] 1.1 Confirm the current DM regression by inspecting tooltip ASS output when global `osd-border-style=background-box`.
- [x] 1.2 Add a focused regression assertion proving DM tooltip text events do not contain active native per-line background boxes.
- [x] 1.3 Add a focused regression assertion proving DW and DM tooltip card/text style contracts are equivalent except for anchoring.
- [x] 1.4 Add a tag-order regression assertion so background-box neutralization cannot be followed by later `{\\3a...}` or `{\\4a...}` tags in the same tooltip text event.

## 2. Shared Tooltip Style Context

- [x] 2.1 Extract tooltip style policy construction into a shared helper that receives the active parent mode (`dw`, `dm`, or `srt`).
- [x] 2.2 Extract measured tooltip card ASS construction into a shared helper using `tooltip_bg_color`, `tooltip_bg_opacity`, `tooltip_border_size`, and `tooltip_shadow_offset`.
- [x] 2.3 Extract tooltip text ASS construction into a shared helper that applies font, size, color, opacity, border/shadow, and native-box isolation in one deterministic order.
- [x] 2.4 Replace the current ad hoc `line_bgbox_neutral` concatenation path with the shared helper.

## 3. Border-Style Policy

- [x] 3.1 Add `tooltip_native_box_policy` with default `auto` and accepted values `auto`, `neutralize`, and `override`.
- [x] 3.2 Implement `auto` so DM under global `background-box` avoids native per-line frames while keeping the parent Drum Mode subtitle surface stable.
- [x] 3.3 Implement `neutralize` so final tooltip text events suppress native background-box painting after all possible re-enabling tags.
- [x] 3.4 Implement `override` using existing scoped `manage_ui_border_override` ownership without leaking or double-releasing override depth.

## 4. Integration

- [x] 4.1 Route `draw_dw_tooltip()` through the shared tooltip style helpers while preserving layout, wrapping, hit-zone, cache, and secondary-subtitle fallback behavior.
- [x] 4.2 Update `apply_tooltip_ass()` so tooltip override ownership is policy-driven rather than DW-only.
- [x] 4.3 Ensure tooltip clearing and cache invalidation release tooltip-specific style ownership reliably in DW, DM, and SRT modes.
- [x] 4.4 Ensure runtime `script-opts` reload invalidates tooltip rendering so policy/style changes apply immediately.

## 5. Validation

- [x] 5.1 Run the targeted tooltip/style regression tests only.
- [ ] 5.2 Manually compare `docs/assets/20260525113530.png` and a refreshed DM tooltip screenshot to verify DM now matches the DW tooltip card behavior.
- [x] 5.3 Verify styled SRT tooltip still activates and does not inherit native per-line boxes under `background-box`.
- [x] 5.4 Document any remaining broader DW/DM renderer unification candidates separately rather than expanding this change scope.
- [x] 5.5 Trace `20260525122538` and add a mode-aware DM tooltip card opacity setting to prevent double-dark stacking without changing DW/SRT tooltip behavior or DM main subtitle frames.
- [x] 5.6 Trace `20260525123946` and add a SRT tooltip card opacity override so SRT can be calibrated independently while preserving the shared renderer.
