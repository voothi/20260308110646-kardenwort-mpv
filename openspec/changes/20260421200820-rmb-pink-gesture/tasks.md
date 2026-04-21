## 1. Add FSM State Fields

- [x] 1.1 Open `scripts/lls_core.lua`. Find the FSM state block (around line 182). Locate the line `DW_MOUSE_DRAGGING = false, -- True while LMB is held and dragging`. Immediately AFTER that line, insert three new fields:
  ```lua
  DW_LMB_DOWN = false,           -- True while LMB is physically held
  DW_RMB_DOWN = false,           -- True while RMB is physically held
  DW_RMB_GESTURE_LAST_TIME = 0,  -- Timestamp of last pink gesture commit (debounce)
  ```
  Do NOT touch any other line in the FSM block.

- [x] 1.2 Verify the three new fields appear in the file and that the surrounding FSM block still compiles (no missing commas).

## 2. Rewrite `cmd_dw_tooltip_pin` to Track RMB State and Guard Gesture

- [x] 2.1 Find `local function cmd_dw_tooltip_pin(tbl)` (around line 2801 in the baseline). The function currently starts with:
  ```lua
  local function cmd_dw_tooltip_pin(tbl)
      if FSM.DRUM_WINDOW == "OFF" then return end
      
      if tbl.event == "down" then
          FSM.DW_TOOLTIP_FORCE = false
          FSM.DW_TOOLTIP_HOLDING = true
  ```
  Replace the entire function body (from the opening `local function` line through the closing `end`) with the following. Do NOT rename the function — it must remain `cmd_dw_tooltip_pin`:
  ```lua
  local function cmd_dw_tooltip_pin(tbl)
      if FSM.DRUM_WINDOW == "OFF" then return end

      -- Track physical RMB state FIRST, before any guard
      if tbl.event == "down" then
          FSM.DW_RMB_DOWN = true
      elseif tbl.event == "up" then
          FSM.DW_RMB_DOWN = false
      end

      -- GESTURE: If LMB is held while RMB is released, trigger pink highlight
      if tbl.event == "up" and FSM.DW_LMB_DOWN then
          local now = mp.get_time()
          if (now - FSM.DW_RMB_GESTURE_LAST_TIME) > 0.05 then
              FSM.DW_RMB_GESTURE_LAST_TIME = now
              -- Reset drag state before toggle to avoid ghost behavior
              FSM.DW_MOUSE_DRAGGING = false
              cmd_dw_toggle_pink(tbl, true)
          end
          FSM.DW_LMB_DOWN = false
          FSM.DW_RMB_DOWN = false
          return
      end

      -- SUPPRESS tooltip opening if LMB is held (gesture mode)
      if tbl.event == "down" and FSM.DW_LMB_DOWN then
          return -- RMB_DOWN already set above; tooltip suppressed
      end

      -- Standard tooltip-pin behavior (unchanged from baseline)
      if tbl.event == "down" then
          FSM.DW_TOOLTIP_FORCE = false
          FSM.DW_TOOLTIP_HOLDING = true
          local subs = Tracks.pri.subs
          if not subs or #subs == 0 then return end
          
          local osd_x, osd_y = dw_get_mouse_osd()
          local line_idx, _ = dw_hit_test(osd_x, osd_y)
          
          if line_idx then
              FSM.DW_TOOLTIP_LOCKED_LINE = -1
              FSM.DW_TOOLTIP_LINE = line_idx
              local y = FSM.DW_LINE_Y_MAP[line_idx] or osd_y
              local ass = draw_dw_tooltip(subs, line_idx, y)
              dw_tooltip_osd.data = ass
              dw_tooltip_osd:update()
          end
      elseif tbl.event == "up" then
          FSM.DW_TOOLTIP_HOLDING = false
      end
  end
  ```

- [x] 2.2 Confirm there is exactly ONE definition of `cmd_dw_tooltip_pin` in the file. The original `cmd_toggle_dw_tooltip_hover` function that follows it MUST remain untouched.

## 3. Create `cmd_dw_lmb_select` Wrapper for LMB

- [x] 3.1 Find the line `local cmd_dw_mouse_select = make_mouse_handler(false)` (around line 3508 in the baseline). BEFORE this line, insert the following new function:
  ```lua
  -- LMB wrapper: tracks DW_LMB_DOWN and intercepts RMB+LMB pink gesture on release
  local function cmd_dw_lmb_select(tbl)
      -- Track physical LMB state FIRST, before any guard
      if tbl.event == "down" then
          FSM.DW_LMB_DOWN = true
      elseif tbl.event == "up" then
          FSM.DW_LMB_DOWN = false
      end

      -- GESTURE: If RMB is held while LMB is released, trigger pink highlight
      if tbl.event == "up" and FSM.DW_RMB_DOWN then
          local now = mp.get_time()
          if (now - FSM.DW_RMB_GESTURE_LAST_TIME) > 0.05 then
              FSM.DW_RMB_GESTURE_LAST_TIME = now
              -- Clean up drag state
              FSM.DW_MOUSE_DRAGGING = false
              mp.remove_key_binding("dw-mouse-drag")
              if FSM.DW_MOUSE_SCROLL_TIMER then
                  FSM.DW_MOUSE_SCROLL_TIMER:kill()
                  FSM.DW_MOUSE_SCROLL_TIMER = nil
              end
              FSM.DW_PROTECTED_SELECTION = false
              cmd_dw_toggle_pink(tbl, true)
          end
          FSM.DW_LMB_DOWN = false
          FSM.DW_RMB_DOWN = false
          return
      end

      -- Standard LMB selection behavior
      cmd_dw_mouse_select(tbl)
  end
  ```
  Note: `cmd_dw_lmb_select` delegates to `cmd_dw_mouse_select` for all normal cases, so it MUST be placed AFTER the `local cmd_dw_mouse_select = make_mouse_handler(false)` line that defines `cmd_dw_mouse_select`.

- [x] 3.2 CORRECTION to 3.1 — because `cmd_dw_lmb_select` calls `cmd_dw_mouse_select`, the insertion point must be AFTER (not before) `local cmd_dw_mouse_select = make_mouse_handler(false)`. Find that line and insert the `cmd_dw_lmb_select` function immediately AFTER it.

## 4. Update Drum Window Key Binding Table

- [x] 4.1 Inside `manage_dw_bindings`, find the `keys` table. Locate the entry:
  ```lua
  {key = "Shift+MBTN_LEFT", name = "dw-mouse-select-shift", fn = cmd_dw_mouse_select_shift, complex = true},
  ```
  Add a new entry BEFORE this line:
  ```lua
  {key = "MBTN_LEFT", name = "dw-mouse-select", fn = cmd_dw_lmb_select, complex = true},
  ```
  This registers `cmd_dw_lmb_select` for plain LMB.

- [x] 4.2 Verify that the `parse_and_bind(Options.dw_key_select, ...)` call (around line 4143) still exists unchanged. It will continue to bind whatever the user configures in `dw_key_select` (typically already `MBTN_LEFT`), but now the static entry in the `keys` table provides the gesture-aware wrapper for the default binding. If `dw_key_select` is set to `MBTN_LEFT`, there will be two bindings registered — this is acceptable in mpv as the last one wins, or you may verify and only add the static entry if not redundant. If in doubt, **leave the `parse_and_bind` line intact** and accept that the static entry in `keys` takes priority due to mpv binding order.

## 5. Reset New FSM Fields on Drum Window Close

- [x] 5.1 In `manage_dw_bindings`, find the `if not enable then` block that resets mouse state on deactivation. The block currently contains:
  ```lua
  FSM.DW_MOUSE_DRAGGING = false
  mp.remove_key_binding("dw-mouse-drag")
  ```
  Immediately after `FSM.DW_MOUSE_DRAGGING = false`, insert:
  ```lua
  FSM.DW_LMB_DOWN = false
  FSM.DW_RMB_DOWN = false
  FSM.DW_RMB_GESTURE_LAST_TIME = 0
  ```

## 6. Acceptance Test

- [ ] 6.1 **Yellow-only (baseline regression)**: Open Drum Window. Drag LMB across several words → selection turns gold. Release LMB alone (no RMB) → selection remains gold; no pink toggle fires.
- [ ] 6.2 **RMB alone opens tooltip (baseline regression)**: With LMB NOT held, press RMB on a word → tooltip appears as normal.
- [ ] 6.3 **LMB-up gesture**: Drag LMB to select words. While LMB is held, press and hold RMB. Release LMB (RMB still held) → words turn pink. Tooltip did NOT appear during the gesture.
- [ ] 6.4 **RMB-up gesture**: Drag LMB to select words. While LMB is held, press RMB. Release RMB (LMB still held) → words turn pink symmetrically.
- [ ] 6.5 **Debounce**: Simultaneously release both buttons — pink fires exactly once (no double toggle, no double-pink that reverts to yellow).
- [ ] 6.6 **Ctrl key still works (regression)**: Hold Ctrl, click LMB on a word → word turns pink. No regression.
- [ ] 6.7 **`t` key still works (regression)**: Make a gold selection, press `t` → turns pink. No regression.
