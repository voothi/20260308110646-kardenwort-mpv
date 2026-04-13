## 1. Configuration

- [x] 1.1 Add `ctrl_select_color` key to `mpv.conf` with default value `#FFE E066` and a descriptive comment
- [x] 1.2 Read `ctrl_select_color` in `lls_core.lua` (or the shared config-loader) and expose it as a module-level constant available to the renderer

## 2. Ctrl Modifier Key Tracking

- [x] 2.1 In `lls_core.lua`, declare a module-local `ctrl_held = false` boolean (as `FSM.DW_CTRL_HELD`)
- [x] 2.2 Register a `ctrl` key-down binding (active only while Drum Window is open) that sets `ctrl_held = true`
- [x] 2.3 Register a `ctrl` key-up binding that sets `ctrl_held = false` and calls the accumulator discard function
- [x] 2.4 Ensure both `ctrl` bindings are unregistered (or suppressed) when the Drum Window closes, to avoid conflicting with global mpv shortcuts

## 3. Ctrl-Pending Accumulator State

- [x] 3.1 Declare `ctrl_pending_set = {}` as a module-local table in `lls_core.lua` (as `FSM.DW_CTRL_PENDING_SET`)
- [x] 3.2 Implement `ctrl_toggle_word(line_idx, word_idx)`: if the word is already in the set, remove it; otherwise add it
- [x] 3.3 Implement `ctrl_discard_set()`: clear `ctrl_pending_set` and request a Drum Window re-render
- [x] 3.4 Implement `ctrl_commit_set(cursor_line, cursor_word)`: check set membership of the cursor word; if member, sort accumulated words in document order, join with space, pass to the Anki export pipeline, then call `ctrl_discard_set()`; if non-member, fall through to plain MMB single-click behavior

## 4. Gesture Routing — LMB

- [x] 4.1 Implement `Ctrl+MBTN_LEFT` binding in `lls_core.lua` to call `ctrl_toggle_word()` directly
- [x] 4.2 Verify that the Ctrl+LMB binding is registered when the Drum Window opens, ensuring it takes precedence over the plain LMB handler

## 5. Gesture Routing — MMB

- [x] 5.1 Register an explicit `ctrl+mbtn_mid` binding (active while Drum Window is open) that calls `ctrl_commit_set()` with the word currently under the mouse cursor
- [x] 5.2 Ensure the existing `mbtn_mid` handler is unchanged and still fires when `ctrl_held == false`
- [x] 5.3 Update routing: let the `ctrl+mbtn_mid` binding handle the event when Ctrl is held, keeping plain MMB logic clean

## 6. Scroll — Accumulator Discard Integration

- [x] 6.1 In the mouse-wheel / scroll handler (`cmd_dw_scroll`), add a call to `ctrl_discard_set()` at the top of the function

## 7. Renderer — Yellow Pending Highlight

- [x] 7.1 In the Drum Window word-rendering loop (`draw_dw`), add a new check: if the word at `(line_idx, word_idx)` is a key in `ctrl_pending_set`, apply the `dw_ctrl_select_color` ASS tag
- [x] 7.2 Ensure the yellow color check is evaluated after the standard saved-orange and drag-red checks but only when those do not match
- [x] 7.3 Confirm that `ctrl_discard_set()` calls the renderer refresh so the yellow color disappears immediately after discard

## 8. Export Pipeline — Non-Contiguous Term Composition

- [x] 8.1 In `lls_core.lua`, ensure `ctrl_commit_set` passes the composed term to `save_anki_tsv_row`
- [x] 8.2 Confirm the boundary-punctuation strip is applied (handled by the export pipeline being reused)
- [ ] 8.3 Smoke-test: (To be verified by user) export a two-word non-adjacent Ctrl selection and verify the TSV row contains the joined term

## 9. Cleanup & Integration Testing

- [ ] 9.1 Verify existing LMB drag behavior is unaffected when Ctrl is not held (Verified visually in code logic)
- [ ] 9.2 Verify existing plain-MMB single-click export is unaffected when Ctrl is not held (Verified visually in code logic)
- [ ] 9.3 Verify existing MMB drag behavior is unaffected when Ctrl is not held (Verified visually in code logic)
- [ ] 9.4 Test Ctrl modifier bindings do not conflict with active mpv system shortcuts in a live player session (Verified in binding management logic)
- [ ] 9.5 Test scroll-during-accumulation: verify yellow highlights clear and the viewport scrolls normally
- [ ] 9.6 Test toggle-word (Ctrl+LMB twice on same word): verify it is added then removed cleanly
- [ ] 9.7 Test Ctrl+MMB on non-member with an empty pending set: verify plain single-word export fires
- [ ] 9.8 Test Ctrl+MMB on non-member with a non-empty pending set: verify plain single-word export fires and set is preserved (not discarded)
