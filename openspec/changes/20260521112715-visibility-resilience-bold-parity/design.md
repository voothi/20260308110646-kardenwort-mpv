## Context

In the Kardenwort-mpv environment, users consume subtitles in dual tracks and interact with the video stream using static reading views like the Drum Window (DW). Three distinct friction points were identified in user workflows when subtitle components are toggled off:
1. **Interactive key suppression**: When the master subtitle track is toggled OFF (setting `FSM.native_sub_vis` to `false` via key `c`), keybindings like tooltip toggling (`e`), pink pairing (`f`), smart-adding to Anki (`g`), and global toggle (`h`) displayed "X" and failed inside the Drum Window due to subtitle visibility checks.
2. **Context copy failure**: When the secondary translation track is disabled (`Tracks.sec.path` is nil or empty), copy functions like dictionary lookup copy (`Shift+c`) and cycling copy modes (`Shift+q`) failed to parse translation context, even though cached secondary translations (`FSM.DW_TOOLTIP_SEC_SUBS`) were preloaded.
3. **Database phrase bold mismatch**: Phrase-only matches from the database did not respect the `anki_highlight_bold` configuration state, leading to inconsistent styling relative to word-level matches.

## Goals / Non-Goals

**Goals:**
- **DW Visibility Resilience**: Enable interactive keys (`e`, `f`, `g`, `h`, search, copy) to execute normally inside the Drum Window even when master subtitle visibility is toggled OFF.
- **Cache-Backed Harvesting**: Use `FSM.DW_TOOLTIP_SEC_SUBS` as a fallback in context-copy parsing and mode cycling when secondary subtitle track is visually disabled, allowing users to copy translation context in Subtitle Mode B.
- **Highlighting Parity**: Ensure that database phrase-only highlights dynamically respect the `anki_highlight_bold` configuration state (making them bold only if the config is set to "yes"), while keeping manual selections at standard font weight.

**Non-Goals:**
- Altering subtitle visibility checks during normal video playback (outside the Drum Window).
- Support for context fallback when both secondary track and translation cache are entirely absent.
- Modifying visual weights for manual selections.

## Decisions

### 1. DW-Aware Visibility Guards in `main.lua`
- **Decision**: Update subtitle visibility guards from `if not FSM.native_sub_vis then` to `if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then` for interactive actions.
- **Rationale**: Since the Drum Window is a static, standalone reading interface, it does not depend on the native subtitle rendering layer. Toggling subtitles OFF during standard playback should not restrict interactive features within DW.
- **Alternative considered**: Forcing native subtitle visibility to true when entering DW. Rejected because it would disrupt the user's preference when exiting DW.

### 2. Cache Fallback for Context Appending and Copy Modes
- **Decision**: Extend the internal helper `append()` inside `get_copy_context_text()` to accept a direct `provided_subs` table. If `Tracks.sec.path` is unavailable, fall back to parsing `FSM.DW_TOOLTIP_SEC_SUBS`. Similarly, cycle copy modes can proceed if either `Tracks.sec.subs` or `FSM.DW_TOOLTIP_SEC_SUBS` contains data.
- **Rationale**: Reuses the robust, existing context-building logic with an alternate in-memory source instead of a file path, ensuring zero regression.
- **Alternative considered**: Fully rebuilding subtitle loaders from scratch for copying. Rejected due to unnecessary code complexity and risk of regression.

### 3. Dynamic Phrase Bold Formatting
- **Decision**: Check `anki_highlight_bold` dynamically when styling phrase matches from the database, appending `{\b1}` or `{\b0}` as configured.
- **Rationale**: Achieves complete visual parity with word-level matches under the same configuration.

## Risks / Trade-offs

- **[Risk]** In-memory cache `FSM.DW_TOOLTIP_SEC_SUBS` might be empty or stale.
  - **[Mitigation]** Strictly verify that `FSM.DW_TOOLTIP_SEC_SUBS` is non-nil and has a length greater than 0 (`#FSM.DW_TOOLTIP_SEC_SUBS > 0`) before falling back. If not available, gracefully fall back to primary-only single track copy mode.
