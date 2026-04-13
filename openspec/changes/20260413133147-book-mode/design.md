## Context

The Drum Window subtitle UI ("w" mode) offers a stationary viewing port that presents subtitles at fixed bounds, similar to a physical flashcard. Normal Drum mode functions like a moving "reel," shifting subtitle line positions over time. Currently, invoking manual navigation (`a`/`d`) or selecting a word by double-clicking the Left Mouse Button (LMB) causes the Drum Window state to instantly revert or drop back into the moving reel behavior. This is jarring and prevents a fluid, "static reading" style flow. Users desire a "Book Mode" that hard-locks the UI in Drum Window framing, preventing the interface from collapsing back to normal Drum mode upon interaction.

## Goals / Non-Goals

**Goals:**
- Implement a discrete toggleable "Book Mode" variable, managed via `FSM.BOOK_MODE`.
- Make the Book Mode permanently engangeable via `mpv.conf`.
- Intercept and suppress the exact conditional logic blocks that collapse the `w` mode during `a`, `d` inputs and `mbtn_left_dbl` clicks.
- **New Feature**: "Freeze" the viewport center in Book Mode, ensuring the list stays stationary during playback and navigation unless explicitly moved by the user.

**Non-Goals:**
- Removing or altering the normal, dynamic reel behavior when `w` (Drum Window) mode is genuinely toggled off.
- Creating a completely new UI rendering stack; rather, this is an orchestration/state management change.

## Decisions

- **State Management**: Integrated into the central state machine as `FSM.BOOK_MODE`. Initialized from `Options.book_mode`.
- **Keybinding Setup**: Bind both `b` and `и` to `toggle_book_mode()`. This function toggles the lock and ensures the Drum Window is active if Book Mode is turned ON.
- **Viewport Freezing**: Modify `tick_dw` to skip `FSM.DW_VIEW_CENTER` updates when `FSM.BOOK_MODE` is active.
- **Navigation Suppression**: Modify `cmd_dw_seek_delta` and `cmd_dw_double_click` to bypass `FSM.DW_VIEW_CENTER` updates when `FSM.BOOK_MODE` is active, allowing the video to seek while keeping the list stationary.

## Risks / Trade-offs

- **Risk**: State desynchronization if `b` is pressed while standard Drum mode is completely inactive, optionally trapping the user in a quasi-state.
  - *Mitigation*: Ensure `toggle_book_mode()` explicitly enables `state.drum_window` along with the lock, guaranteeing logical consistency. If Book Mode is turned ON, it automatically implies Drum Window should be ON.

- **Risk**: Potential conflicting keybindings on `b` across other utility scripts.
  - *Mitigation*: Instruct the user in tasks/release notes to ensure `b` is cleared from default or script mappings.
