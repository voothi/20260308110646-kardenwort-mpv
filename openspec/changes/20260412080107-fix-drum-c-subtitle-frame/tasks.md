## 1. Core Logic Update

- [ ] 1.1 Add `FSM.DRUM == "OFF"` condition to `manage_ui_border_override` in `scripts/lls_core.lua`. This prevents the subtitle frame from being globally overridden when Drum Mode C is active.

## 2. Verification

- [ ] 2.1 Verify that subtitles in Drum Mode C retain their dark frame when `Ctrl+f` (Search) is activated.
- [ ] 2.2 Verify that the Search UI still functions correctly and its style restoration works as expected when Drum Mode is not active.
