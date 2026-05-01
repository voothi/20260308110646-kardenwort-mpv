## 1. Options Table Update (lls_core.lua)

- [x] 1.1 Add `tooltip_active_bold` and `tooltip_context_bold` to the `Options` table.
- [x] 1.2 Initialize them to `false`.
- [x] 1.3 (Internal) Deprecate/Remove `tooltip_font_bold` if no longer needed, or keep for backward compatibility. Let's keep it but prioritize the new granular ones.

## 2. Rendering Logic (lls_core.lua)

- [x] 2.1 Update `draw_dw_tooltip` to calculate line-specific `bold` state using `tooltip_active_bold` and `tooltip_context_bold`.
- [x] 2.2 Fix the `ass` tag string in `draw_dw_tooltip`:
    - From: `{\\3c&H%s&}{\\4a&H%s&}`
    - To: `{\\3c&H%s&}{\\4c&H%s&}{\\4a&H%s&}` (using `bg_color` for both `\3c` and `\4c`).
- [x] 2.3 Verify that `format_highlighted_word` correctly receives the `bold` state for each word.

## 3. Configuration (mpv.conf)

- [x] 3.1 Update the "Translation Tooltip Settings" section:
    - Replace `lls-tooltip_font_bold=yes` with `lls-tooltip_active_bold=no` and `lls-tooltip_context_bold=no`.
    - Ensure `lls-tooltip_highlight_bold=no` is present.
- [x] 3.2 Ensure all other modes (Drum, DW, SRT) have `highlight_bold=no` for consistent selection behavior.

## 4. Verification

- [x] 4.1 Launch MPV and toggle the tooltip (E).
- [x] 4.2 Verify the background is solid black (semi-transparent) without a white glow.
- [x] 4.3 Select text in the tooltip and verify it remains "thin" (Regular) weight, matching the surrounding text.
- [x] 4.4 Verify that setting `tooltip_active_bold=yes` correctly bolds only the active line in the tooltip.
