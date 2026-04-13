## 1. Configuration

- [ ] 1.1 Add `ctrl_select_color` key to `mpv.conf` with default value `#FFE066` and a descriptive comment
- [ ] 1.2 Read `ctrl_select_color` in `lls_core.lua` (or the shared config-loader) and expose it as a module-level constant available to the renderer

## 2. Ctrl Modifier Key Tracking

- [ ] 2.1 In `lls_dw.lua`, declare a module-local `ctrl_held = false` boolean
- [ ] 2.2 Register a `ctrl` key-down binding (active only while Drum Window is open) that sets `ctrl_held = true`
- [ ] 2.3 Register a `ctrl` key-up binding that sets `ctrl_held = false` and calls the accumulator discard function
- [ ] 2.4 Ensure both `ctrl` bindings are unregistered (or suppressed) when the Drum Window closes, to avoid conflicting with global mpv shortcuts

## 3. Ctrl-Pending Accumulator State

- [ ] 3.1 Declare `ctrl_pending_set = {}` as a module-local table in `lls_dw.lua` (keyed by `"line:word"` string for O(1) membership test, with an ordered array shadow for export)
- [ ] 3.2 Implement `ctrl_toggle_word(line_idx, word_idx)`: if the word is already in the set, remove it; otherwise add it — update both the key-table and the ordered array
- [ ] 3.3 Implement `ctrl_discard_set()`: clear `ctrl_pending_set`, clear the array shadow, and request a Drum Window re-render
- [ ] 3.4 Implement `ctrl_commit_set(cursor_line, cursor_word)`: check set membership of the cursor word; if member, sort accumulated words in document order, join with space, pass to the Anki export pipeline, then call `ctrl_discard_set()`; if non-member, fall through to plain MMB single-click behavior

## 4. Gesture Routing — LMB

- [ ] 4.1 In the `MBTN_LEFT` press handler in `lls_dw.lua`, add a guard: if `ctrl_held == true`, call `ctrl_toggle_word()` for the word under the cursor and return early (skip drag state machine entry)
- [ ] 4.2 Verify that the Ctrl+LMB binding (`ctrl+mbtn_left`) is registered when the Drum Window opens, routing directly to the same `ctrl_toggle_word()` path without entering the drag handler

## 5. Gesture Routing — MMB

- [ ] 5.1 Register an explicit `ctrl+mbtn_mid` binding (active while Drum Window is open) that calls `ctrl_commit_set()` with the word currently under the mouse cursor
- [ ] 5.2 Ensure the existing `mbtn_mid` handler is unchanged and still fires when `ctrl_held == false`
- [ ] 5.3 Update the Single-Click Selection Commitment (SCM) logic: add a guard at the top of the plain-MMB handler — if `ctrl_held == true`, skip SCM and let the `ctrl+mbtn_mid` binding handle the event

## 6. Scroll — Accumulator Discard Integration

- [ ] 6.1 In the mouse-wheel / scroll handler (`cmd_dw_scroll` or equivalent), add a call to `ctrl_discard_set()` at the top of the function if `ctrl_pending_set` is non-empty before processing the scroll

## 7. Renderer — Yellow Pending Highlight

- [ ] 7.1 In the Drum Window word-rendering loop (wherever per-word color is resolved), add a new check: if the word at `(line_idx, word_idx)` is a key in `ctrl_pending_set`, apply the `ctrl_select_color` ASS tag
- [ ] 7.2 Ensure the yellow color check is evaluated after the standard saved-orange and drag-red checks but only when those do not match (priority: saved > drag > ctrl-pending)
- [ ] 7.3 Confirm that `ctrl_discard_set()` calls the renderer refresh so the yellow color disappears immediately after discard

## 8. Export Pipeline — Non-Contiguous Term Composition

- [ ] 8.1 In `lls_core.lua` (the Anki export function), accept a pre-composed term string (the space-joined words from `ctrl_commit_set`) and verify it is handled identically to a contiguous drag-selected term
- [ ] 8.2 Confirm the boundary-punctuation strip (from `high-recall-highlighting` spec: "Clean Boundary Capture") is applied to the composed term before TSV write
- [ ] 8.3 Smoke-test: export a two-word non-adjacent Ctrl selection (e.g., *räumt* … *auf*) and verify the TSV row contains `räumt auf` as the term and that the orange highlight appears correctly on the next subtitle render

## 9. Cleanup & Integration Testing

- [ ] 9.1 Verify existing LMB drag behavior is unaffected when Ctrl is not held
- [ ] 9.2 Verify existing plain-MMB single-click export is unaffected when Ctrl is not held
- [ ] 9.3 Verify existing MMB drag behavior is unaffected when Ctrl is not held
- [ ] 9.4 Test Ctrl modifier bindings do not conflict with active mpv system shortcuts in a live player session
- [ ] 9.5 Test scroll-during-accumulation: verify yellow highlights clear and the viewport scrolls normally
- [ ] 9.6 Test toggle-word (Ctrl+LMB twice on same word): verify it is added then removed cleanly
- [ ] 9.7 Test Ctrl+MMB on non-member with an empty pending set: verify plain single-word export fires
- [ ] 9.8 Test Ctrl+MMB on non-member with a non-empty pending set: verify plain single-word export fires and set is preserved (not discarded)
