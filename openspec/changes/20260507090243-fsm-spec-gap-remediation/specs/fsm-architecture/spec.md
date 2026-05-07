## MODIFIED Requirements

### Requirement: Global Subtitle Quick Toggle (cmd_toggle_sub_vis)
The system SHALL ensure the "s" (global toggle) key updates the desired state uniformly, bypassing lower-level mode conflicts. `FSM.native_sub_vis` and `FSM.native_sec_sub_vis` MUST be toggled regardless of whether `FSM.DRUM_WINDOW` is active. When `FSM.DRUM_WINDOW` is active, the Drum Window OSD surface is independent of `FSM.native_sub_vis` and SHALL continue rendering; the toggle updates the FSM desired-state so that the correct visibility is applied when the Drum Window is later closed.

#### Scenario: User presses 's' to disable all subs
- **WHEN** user triggers `cmd_toggle_sub_vis()` when `FSM.native_sub_vis = true`
- **THEN** system SHALL set `FSM.native_sub_vis = false`, set native properties `sub-visibility` to false directly, and flush any `drum_osd` buffers.

#### Scenario: User presses 's' while Drum Window is open
- **WHEN** user triggers `cmd_toggle_sub_vis()` while `FSM.DRUM_WINDOW == "DOCKED"`
- **THEN** system SHALL toggle `FSM.native_sub_vis` and `FSM.native_sec_sub_vis` as normal
- **AND** the Drum Window OSD surface SHALL continue rendering without interruption
- **AND** when the Drum Window is subsequently closed, the restored visibility SHALL reflect the toggled FSM desired-state.

### Requirement: Deterministic Focus Sentinel
The system SHALL use a persistent sentinel (`FSM.ACTIVE_IDX`) to maintain focus on the current subtitle fragment, preventing "Magnetic Snapping" caused by temporal padding. The sentinel MUST only be applied when resolving indices against the primary subtitle track. When `get_center_index` is called with the secondary subtitle array, the sentinel SHALL NOT be applied (secondary track uses binary search resolution without a cross-track index assumption). To protect Jerk-Back logic in Phrase Mode and prevent audio clipping, the index resolution function (`get_center_index`) MUST follow a strict evaluation hierarchy:
1. **Sentinel (Early Return)**: If resolving the primary track and the playhead is within the `[Start-Pad, End+Pad]` window of the current `FSM.ACTIVE_IDX`, return the current index immediately.
2. **Natural Progression**: If resolving the primary track and `FSM.ACTIVE_IDX` is set and the consecutive next sub (`ACTIVE_IDX+1`) has a padded zone that contains `time_pos`, return `ACTIVE_IDX+1` immediately.
3. **Standard Resolution**: Perform a binary search for the first subtitle starting at or before `time_pos`.
4. **Overlap Priority**: If a subsequent subtitle's padded start has begun, handover control only if the Sentinel has no claim. (Cold-entry only — Natural Progression supersedes this during sequential playback.)

#### Scenario: Subtitle Tail Protection
- **WHEN** playback continues past the technical duration of a subtitle
- **THEN** the sentinel SHALL remain locked until the playhead exits the `[Start-Pad, End+Pad]` window.

#### Scenario: Secondary track resolution uses no cross-track sentinel
- **WHEN** `get_center_index` is called with the secondary subtitle array
- **THEN** it SHALL NOT use `FSM.ACTIVE_IDX` (a primary-track index) as a sentinel for secondary array lookup
- **AND** resolution SHALL fall through directly to standard binary search.

### Requirement: Secondary Position Bounds via Configuration
Secondary subtitle positioning transitions SHALL respect configured FSM bounds rather than hardcoded constants. `FSM.native_sec_sub_pos` SHALL be kept synchronized with the actual mpv `secondary-sub-pos` property at all times, including after delta-based position adjustments, so that direction-aware toggle operations always operate from correct state.

#### Scenario: Cycling secondary subtitle position
- **WHEN** `cycle-secondary-pos` is triggered
- **THEN** the system SHALL toggle `secondary-sub-pos` between `Options.sec_pos_top` and `Options.sec_pos_bottom`
- **AND** overlap avoidance SHALL be achieved by validated configuration defaults (for example `sec_pos_bottom = 90` relative to primary `95`), not by implicit runtime clamping.

#### Scenario: Delta position adjustment syncs FSM state
- **WHEN** `cmd_adjust_sec_sub_pos` is called with a delta value
- **THEN** the system SHALL compute the new position, apply it to the mpv property, and write the same value back to `FSM.native_sec_sub_pos`
- **AND** a subsequent call to `cmd_cycle_sec_pos` SHALL use the synchronized `FSM.native_sec_sub_pos` to determine correct toggle direction.
