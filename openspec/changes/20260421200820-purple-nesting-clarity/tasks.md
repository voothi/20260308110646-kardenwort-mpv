## 1. Fix Drum Window Rendering Pass (Primary Rendering Path)

The primary rendering pass is inside the Drum Window's word-coloring loop. The relevant code is around line 2399 in the baseline commit `a1d1a0c8`. Locate it by searching for `calculate_highlight_stack(subs, i, j, subs[i].start_time)`.

- [x] 1.1 In `scripts/lls_core.lua`, find the following block (it begins with the `calculate_highlight_stack` call that uses `purple_depth`):
  ```lua
  local orange_stack, purple_stack, is_phrase, matching_terms, purple_depth = calculate_highlight_stack(subs, i, j, subs[i].start_time)
  meta.purple_depth = purple_depth -- Save for neighbor derivation
  local h_color = color
  
  if orange_stack > 0 and purple_stack > 0 then
      local mix_depth = math.min((orange_stack + purple_depth) - 1, 3)
      if mix_depth == 1 then h_color = Options.anki_mix_depth_1 or "4A4AD3"
      elseif mix_depth == 2 then h_color = Options.anki_mix_depth_2 or "3636A8"
      elseif mix_depth >= 3 then h_color = Options.anki_mix_depth_3 or "151578" end
  elseif orange_stack > 0 then
      if orange_stack == 1 then h_color = Options.anki_highlight_depth_1
      elseif orange_stack == 2 then h_color = Options.anki_highlight_depth_2
      elseif orange_stack >= 3 then h_color = Options.anki_highlight_depth_3 end
  elseif purple_stack > 0 then
      if purple_depth == 1 then h_color = Options.anki_split_depth_1 or Options.dw_split_select_color or "FF88B0"
      elseif purple_depth == 2 then h_color = Options.anki_split_depth_2 or "D97496"
      elseif purple_depth >= 3 then h_color = Options.anki_split_depth_3 or "B3607C" end
  end
  ```

- [x] 1.2 Replace the entire block found in 1.1 with the following. Note the changes: `mix_depth` is removed, the `purple_stack > 0` branch now uses a single flat color, and the orange depth logic is unchanged:
  ```lua
  local orange_stack, purple_stack, is_phrase, matching_terms, purple_depth = calculate_highlight_stack(subs, i, j, subs[i].start_time)
  meta.purple_depth = purple_depth -- Retained for potential future use; not used for color selection
  local h_color = color
  
  if orange_stack > 0 and purple_stack > 0 then
      h_color = Options.anki_mix_depth_1 or "4A4AD3"
  elseif orange_stack > 0 then
      if orange_stack == 1 then h_color = Options.anki_highlight_depth_1
      elseif orange_stack == 2 then h_color = Options.anki_highlight_depth_2
      elseif orange_stack >= 3 then h_color = Options.anki_highlight_depth_3 end
  elseif purple_stack > 0 then
      h_color = Options.anki_split_depth_1 or Options.dw_split_select_color or "FF88B0"
  end
  ```

- [x] 1.3 Verify the surrounding code (`if h_color ~= color then ... end` and `token_meta[j] = meta`) is unchanged.

## 2. Fix Playback/Subtitle Rendering Pass (Secondary Rendering Path)

There is a second call site around line 2128 in the baseline. Locate it by searching for `calculate_highlight_stack(subs, sub_idx, j, t_pos)`.

- [x] 2.1 In `scripts/lls_core.lua`, find the following block (it uses `calculate_highlight_stack` with `sub_idx` and `t_pos`):
  ```lua
  local orange_stack, purple_stack, is_phrase = calculate_highlight_stack(subs, sub_idx, j, t_pos)
  
  if orange_stack > 0 and purple_stack > 0 then
      local mix_depth = math.min((orange_stack + purple_stack) - 1, 3)
      if mix_depth == 1 then h_color = Options.anki_mix_depth_1 or "4A4AD3"
      elseif mix_depth == 2 then h_color = Options.anki_mix_depth_2 or "3636A8"
      elseif mix_depth >= 3 then h_color = Options.anki_mix_depth_3 or "151578" end
  elseif orange_stack > 0 then
      if orange_stack == 1 then h_color = Options.anki_highlight_depth_1
      elseif orange_stack == 2 then h_color = Options.anki_highlight_depth_2
      elseif orange_stack >= 3 then h_color = Options.anki_highlight_depth_3 end
  elseif purple_stack > 0 then
      if purple_stack == 1 then h_color = Options.anki_split_depth_1 or Options.dw_split_select_color or "FF88B0"
      elseif purple_stack == 2 then h_color = Options.anki_split_depth_2 or "D97496"
      elseif purple_stack >= 3 then h_color = Options.anki_split_depth_3 or "B3607C" end
  end
  ```
  Note: this call only returns 3 values (no `purple_depth` in the destructuring).

- [x] 2.2 Replace the block found in 2.1 with:
  ```lua
  local orange_stack, purple_stack, is_phrase = calculate_highlight_stack(subs, sub_idx, j, t_pos)
  
  if orange_stack > 0 and purple_stack > 0 then
      h_color = Options.anki_mix_depth_1 or "4A4AD3"
  elseif orange_stack > 0 then
      if orange_stack == 1 then h_color = Options.anki_highlight_depth_1
      elseif orange_stack == 2 then h_color = Options.anki_highlight_depth_2
      elseif orange_stack >= 3 then h_color = Options.anki_highlight_depth_3 end
  elseif purple_stack > 0 then
      h_color = Options.anki_split_depth_1 or Options.dw_split_select_color or "FF88B0"
  end
  ```

- [x] 2.3 Verify no other lines around this block were changed.

## 3. Verify No Other `purple_depth` or `mix_depth` Color Selection Sites

- [x] 3.1 Search the entire file for `purple_depth` used in color assignment. Run a text search for `anki_split_depth_2` and `anki_split_depth_3` inside any `if`/`elseif` rendering logic. There should be ZERO remaining occurrences that select a color based on depth (the Options table declarations themselves are fine to keep).
- [x] 3.2 Search for `mix_depth` — there should be ZERO remaining occurrences after the changes in steps 1.2 and 2.2.

## 4. Acceptance Test

- [x] 4.1 **Single isolated purple group**: Save a split-match phrase (e.g., using Ctrl+click on non-adjacent words). Open Drum Window. Verify the matched words appear in the flat `anki_split_depth_1` shade (default pinkish-purple).
- [x] 4.2 **Two adjacent non-nesting purple groups**: Create two separate pink-pair groups that are near each other but do NOT contain each other. Verify that ALL words in both groups render in the SAME flat shade — no words are darker.
- [x] 4.3 **Orange words unchanged**: Verify that words matched by a contiguous (orange) Anki save still appear in the orange depth shading as before (depth 1 = lighter, depth 2 = darker, etc.). The orange depth gradient MUST be unaffected.
- [x] 4.4 **Mixed orange+purple**: Find or create a word covered by both an orange and a purple match. Verify it renders in `anki_mix_depth_1` (single flat blue-purple). No depth variation.
- [x] 4.5 **Playback mode**: Verify the same flat purple behavior in the subtitle overlay (playback mode), not just Drum Window mode.
