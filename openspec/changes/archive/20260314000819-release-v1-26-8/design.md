## Context

As the suite added advanced features (Search, Drum Window), it relied heavily on having direct access to subtitle files on disk (`Tracks.pri.path`). Users opening videos with embedded tracks experienced "silent failures" where a feature seemed to turn ON but didn't function. This release focuses on "Feedback First" design.

## Goals / Non-Goals

**Goals:**
- Prevent activation of advanced features without external subtitle tracks.
- Provide descriptive labels for copy modes and track cycling.
- Ensure the system correctly identifies the behavior of merged ASS files.

## Decisions

- **Validation Logic**: A shared check for `Tracks.pri.path` is added to the entry points of `cmd_toggle_drum_window`, `cmd_toggle_drum`, and `cmd_toggle_search`. If the path is nil, the system displays "Requires external subtitle files" and aborts the toggle.
- **Semantic Labels**: The OSD messages in `cmd_cycle_copy_mode` are expanded from simple `A` and `B` to include the project's core terminology (Primary/Target vs Secondary/Translation).
- **Codec Detection**: `cmd_cycle_sec_sid` now inspects the codec of the available tracks. It specifically handles the "Internal ASS" scenario to prevent users from trying to toggle a translation track that is actually just a layer in a singular ASS stream.
- **State Transparency**: These changes prioritize informing the user *why* a state exists, rather than just reporting the state itself.

## Risks / Trade-offs

- **Risk**: Annoying users who know they are using embedded tracks.
- **Mitigation**: The messages are short (OSD) and only appear when a user explicitly tries to activate a feature that depends on external files.
