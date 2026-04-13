## Context

The `kardenwort-mpv` subtitle engine has evolved into a robust multi-mode interface (Regular SRT, Drum Mode, Drum Window, Tooltips). These modes often require hiding/showing native subtitles, overriding inputs, or drawing custom OSD backgrounds. Over time, state interaction logic (e.g., transitions between `DRUM="ON"` and `DRUM_WINDOW="DOCKED"`) has become complex, leading to brief regressions such as "flickering subtitles" or "failed state cycle restorations". 

While `lls_core.lua` already defines a central `FSM` table, its interactions are documented implicitly through the logic handling it. We need a permanent, explicit architectural specification containing a state matrix map to act as a single source of truth for AI models and external contributors.

## Goals / Non-Goals

**Goals:**
- Provide a clear, persistent specification of the `FSM` table that dictates the `kardenwort-mpv` subtitle states.
- Document how specific subsystems (`master_tick`, `cmd_toggle_drum_window`, `cmd_toggle_sub_vis`) consume and mutate these states.
- Serve as a reference guide for future development to avoid fighting over `mp.set_property("sub-visibility")`.

**Non-Goals:**
- We will not refactor the existing state logic; this change focuses on capturing the architecture as it operates correctly right now (from baseline `4d71703` through recent bug fixes).
- We will not add new features to the subsystem itself.

## Decisions

- **Single Specification File (`openspec/specs/fsm-architecture/spec.md`)**: The FSM states are critical to the engine's core. We will maintain a single spec mapping out:
  1. The Global Visibility State (`FSM.native_sub_vis` & `FSM.native_sec_sub_vis`).
  2. The Subtitle OSD Matrix Context (`DRUM`, `DRUM_WINDOW`, `Regular Mode`).
  3. The Interaction Overrides (`TOOLTIP_MODE`, `SEARCH_MODE`, `MOUSE_DRAGGING`).
- **Hardening `master_tick` Suppression Logic**: To prevent overlap bugs (where MPV natively draws subtitles underneath the OSD), `master_tick` must evaluate both `mp.get_property_bool("sub-visibility")` AND `mp.get_property_bool("secondary-sub-visibility")`. Additionally, `master_tick`'s continuous suppression loop will explicitly yield when `FSM.DRUM_WINDOW ~= "OFF"`, allowing `cmd_toggle_drum_window` to manage window-mode visibility safely without fighting.

## Risks / Trade-offs

- [Risk] The documented FSM spec may become outdated if minor fixes alter logic implicitly. → Mitigation: By keeping this as a top-level architectural OpenSpec artifact, future workflows (like `opsx-apply` and `opsx-explore`) will ingest it automatically to maintain up-to-date compliance in subsequent changes.
