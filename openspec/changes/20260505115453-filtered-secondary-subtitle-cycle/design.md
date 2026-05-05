## Context
The Kardenwort immersion suite uses a custom script binding `cycle-sec-sid` to rotate through secondary subtitle tracks. Currently, this cycling logic is inclusive of all tracks detected by mpv, including internal/embedded ones that the suite cannot parse for its advanced features (Autopause, Drum Mode).

## Goals / Non-Goals

**Goals:**
- Implement a surgical filter that only permits external subtitle files in the secondary cycle.
- Dynamically exclude the active primary subtitle track to avoid mpv state conflicts.
- Enhance user feedback via OSD to explain why certain tracks are hidden.

**Non-Goals:**
- Adding support for parsing internal/embedded subtitle streams.
- Changing the primary subtitle cycling logic (`Shift+v`).

## Decisions
- **Manual State Management**: Instead of using mpv's native `cycle` command, the script will manually iterate through the `track-list` to identify "supported" tracks (`t.external == true`).
- **Primary Exclusion Filter**: Before populating the supported track list, the script will retrieve the current `sid` and skip it if encountered. This ensures that `Shift+c` always results in a track change or toggling to `OFF`.
- **Informative Suffix**: The OSD message will include a `[X built-in hidden]` suffix to provide transparency about the filtering logic without cluttering the main display.

## Risks / Trade-offs
- **User Preference**: A user might *want* to select an internal track for secondary display even if it doesn't support advanced features. However, the decision (based on ZID 20260505113409) is to prioritize "supported" tracks to maintain immersion suite integrity.
