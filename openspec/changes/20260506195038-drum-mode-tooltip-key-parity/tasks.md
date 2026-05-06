## 1. FSM and Ownership Wiring

- [x] 1.1 Add Drum-tooltip eligibility gate in `scripts/lls_core.lua` requiring `FSM.DRUM == "ON"` and `FSM.DRUM_WINDOW == "OFF"` before tooltip render dispatch.
- [x] 1.2 Add transition-edge cleanup hooks that clear tooltip OSD buffers and invalidate tooltip hit-zones whenever ownership switches between Drum and Drum Window.
- [x] 1.3 Ensure ASS/media gatekeeping paths keep Drum tooltip unavailable when Drum rendering is disabled by context.

## 2. Coordinated Key Routing

- [x] 2.1 Refactor tooltip key dispatch to route by active mode while keeping a single logical key configuration surface.
- [x] 2.2 Preserve multi-key layout parity (EN/RU variants) for tooltip triggers in Drum Mode.
- [x] 2.3 Verify no key collision regressions with existing Drum navigation and DW tooltip bindings.

## 3. Drum Rendering and Hit-Zones

- [x] 3.1 Extend Drum primary subtitle hit-zone mapping so tooltip actions can resolve a focused token on the bottom main subtitle stream.
- [x] 3.2 Implement Drum-mode tooltip draw path using shared tooltip formatter/pipeline semantics.
- [x] 3.3 Enforce visibility-safe behavior: clear and suppress tooltip overlay when global subtitle visibility is effectively OFF.

## 4. Lifecycle Safety and Regression Verification

- [x] 4.1 Extend tooltip lifecycle guards to include Drum-mode logical activation checks before hit-test acceptance.
- [x] 4.2 Add targeted diagnostics or debug traces for mode-routed tooltip dispatch and cleanup events.
- [ ] 4.3 Run manual regression matrix across Regular SRT, Drum Mode, Drum Window, and rapid mode switching; confirm Book Mode behavior is unchanged.
