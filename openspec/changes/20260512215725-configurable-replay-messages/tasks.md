## 1. Configuration Setup

- [x] 1.1 Add `replay_msg_format` to `Options` in `main.lua` with default `"Replay: %mms%x"`
- [x] 1.2 Add `replay_on_msg_format` to `Options` in `main.lua` with default `"Replaying segment: %mms%x"`
- [x] 1.3 Add documentation and default values for new replay message options to `mpv.conf`

## 2. Core Implementation

- [x] 2.1 Update `cmd_replay_sub` to calculate the `%x` placeholder string based on current mode and `replay_count`
- [x] 2.2 Implement template substitution logic using `string.gsub` for `%m`, `%c`, and `%x` within `cmd_replay_sub`
- [x] 2.3 Replace hardcoded strings in `show_osd` calls with the dynamically formatted messages

## 3. Verification

- [x] 3.1 Verify Autopause OFF mode feedback matches expected format for single iteration
- [x] 3.2 Verify Autopause OFF mode feedback matches expected format for multiple iterations (verify `%x`)
- [x] 3.3 Verify Autopause ON mode feedback matches expected format for single iteration
- [x] 3.4 Verify Autopause ON mode feedback matches expected format for multiple iterations (verify `%x`)
- [x] 3.5 Confirm that overriding templates in `mpv.conf` successfully changes the OSD output
