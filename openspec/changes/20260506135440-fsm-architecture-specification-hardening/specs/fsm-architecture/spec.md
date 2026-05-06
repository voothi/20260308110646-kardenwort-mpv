## MODIFIED Requirements

### Requirement: Autopause Coordination (AUTOPAUSE / SPACEBAR)
The system SHALL manage subtitle-boundary pausing autonomously based on FSM state flags. To ensure the audible tail is fully preserved, the autopause trigger MUST evaluate the end-of-subtitle threshold against the index resolved by the Deterministic Focus Sentinel.

#### Scenario: Autopause halts playback at subtitle boundaries
- **WHEN** `FSM.AUTOPAUSE == "ON"` and playback crosses the threshold of `FSM.last_paused_sub_end` 
- **THEN** it SHALL evaluate `FSM.SPACEBAR`. If `IDLE`, it pauses the player. If the user overrides via spacebar, the system yields until the next track boundary.

### Requirement: Deterministic Focus Sentinel
The system SHALL use a persistent sentinel (`FSM.ACTIVE_IDX`) to maintain focus on the current subtitle fragment, preventing \"Magnetic Snapping\" caused by temporal padding. To protect Jerk-Back logic in Phrase Mode and prevent audio clipping, the index resolution function (`get_center_index`) MUST follow a strict evaluation hierarchy:
1. **Sentinel (Early Return)**: If the playhead is within the `[Start-Pad, End+Pad]` window of the current `FSM.ACTIVE_IDX`, return the current index immediately.
2. **Standard Resolution**: Perform a binary search for the first subtitle starting at or before `time_pos`.
3. **Overlap Priority**: If a subsequent subtitle's padded start has begun, handover control only if the Sentinel has no claim.

#### Scenario: Subtitle Tail Protection
- **WHEN** playback continues past the technical duration of a subtitle
- **THEN** the sentinel SHALL remain locked until the playhead exits the `[Start-Pad, End+Pad]` window.
