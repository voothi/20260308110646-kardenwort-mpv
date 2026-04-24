## 1. Unified Key Bindings

- [x] 1.1 Add `dw_key_cycle_copy_mode` and `dw_key_toggle_copy_context` to the `Options` table in `lls_core.lua` (defaulting to "z я" and "x ч").
- [x] 1.2 Add `cycle-copy-mode` and `toggle-copy-context` to `manage_dw_bindings` using these new options.

## 2. Context Extraction Refactoring

- [x] 2.1 Refactor `get_copy_context_text(time_pos)` in `lls_core.lua` to accept an optional `line_idx` parameter.
- [x] 2.2 Update internal logic to use `line_idx` as the center if provided, otherwise fallback to `get_center_index`.

## 3. Enhanced Drum Copy Logic

- [x] 3.1 Update `cmd_dw_copy` to respect `FSM.COPY_MODE`. For single-line fallbacks (mode B), attempt to pull text from `Tracks.sec.subs`.
- [x] 3.2 Update `cmd_dw_copy` to respect `FSM.COPY_CONTEXT`. If enabled, pass the extracted text through the refactored context engine.
- [x] 3.3 Ensure final text cleaning (strip ASS tags, whitespace) is applied consistently after context merging.

## 4. Verification

- [ ] 4.1 Verify `z` and `x` toggle OSD messages while in Book Mode.
- [ ] 4.2 Verify `Ctrl+C` in Drum Window includes context when `x` is ON.
- [ ] 4.3 Verify `Ctrl+C` in Drum Window copies translation when `z` is set to B.
