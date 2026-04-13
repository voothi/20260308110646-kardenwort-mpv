## Context

The Drum Window subtitle UI ("w" mode) offers a stationary viewing port that presents subtitles at fixed bounds, similar to a physical flashcard. Normal Drum mode functions like a moving "reel," shifting subtitle line positions over time. Currently, invoking manual navigation (`a`/`d`) or selecting a word by double-clicking the Left Mouse Button (LMB) causes the Drum Window state to instantly revert or drop back into the moving reel behavior. This is jarring and prevents a fluid, "static reading" style flow. Users desire a "Book Mode" that hard-locks the UI in Drum Window framing, preventing the interface from collapsing back to normal Drum mode upon interaction.

## Goals / Non-Goals

**Goals:**
- Implement a discrete toggleable "Book Mode" variable, manageable via hotkey `b` (or `и`).
- Make the Book Mode permanently engangeable via `mpv.conf`.
- Intercept and suppress the exact conditional logic blocks that collapse the `w` mode during `a`, `d` inputs, and `mbtn_left_dbl` clicks, specifically ensuring the UI maintains the centered block presentation.

**Non-Goals:**
- Removing or altering the normal, dynamic reel behavior when `w` (Drum Window) mode is genuinely toggled off.
- Creating a completely new UI rendering stack; rather, this is an orchestration/state management change.

## Decisions

- **State Management**: Introduce `local is_book_mode = false` at script initialization, mapped early to read configuration keys. This ensures the design seamlessly inherits from a central source of truth.
- **Keybinding Setup**: Bind both `b` and `и` (Russian layout equivalent) to an observed function `toggle_book_mode()`. This function toggles `is_book_mode` and updates `state.drum_window` if needed, optionally throwing an On-Screen Display (OSD) feedback message like "Book Mode: ON".
- **Interaction Supression**: Locate handlers for `a` (prev_sub), `d` (next_sub), and `mbtn_left_dbl` (vocab selection). Wrap the mode-switch downcast logic in conditional blocks: e.g., `if state.drum_window and not is_book_mode then state.drum_window = false end`.

## Risks / Trade-offs

- **Risk**: State desynchronization if `b` is pressed while standard Drum mode is completely inactive, optionally trapping the user in a quasi-state.
  - *Mitigation*: Ensure `toggle_book_mode()` explicitly enables `state.drum_window` along with the lock, guaranteeing logical consistency. If Book Mode is turned ON, it automatically implies Drum Window should be ON.

- **Risk**: Potential conflicting keybindings on `b` across other utility scripts.
  - *Mitigation*: Instruct the user in tasks/release notes to ensure `b` is cleared from default or script mappings.
