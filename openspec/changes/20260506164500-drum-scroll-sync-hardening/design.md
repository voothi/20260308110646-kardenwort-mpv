## Context
The current drum-scroll behavior uses shared viewport state (`DW_VIEW_CENTER`, `DW_FOLLOW_PLAYER`) and updated rendering signatures (`view_center`, `active_idx`). This improved parity with Drum Window but left unresolved policy boundaries and missing FSM-level contracts.

## Observed Gaps
1. Wheel policy ambiguity:
- Archived tasks claim default mpv wheel behavior is preserved outside subtitle hit zones.
- Current handler consumes events in some non-hit-zone contexts due forced bindings.

2. Secondary sync edge case:
- Secondary viewport offset is derived from primary active index space.
- Behavior is undefined when primary subtitles are unavailable but secondary remains active.

3. FSM coupling risk:
- No explicit contract states drum viewport scrolling must not alter autopause guard state (`ACTIVE_IDX`, `last_paused_sub_end`) except through normal time-based resolution.

## Design Decisions
1. Dual-track sync contract:
- Manual viewport scroll is primary-driven.
- Secondary viewport must mirror the same logical offset when both tracks are active.
- If primary is unavailable, scrolling falls back to active secondary without synthetic primary offset.

2. Highlight sync contract:
- Active-line emphasis and semantic highlight layers must stay aligned with each lane's active index while sharing the same viewport offset intent.
- Scrolling must not rebind semantic highlight ownership.

3. Wheel routing contract:
- Explicitly document whether outside-hit-zone wheel events are passed through or consumed, and require tests to match the chosen behavior.

4. FSM safety contract:
- Drum manual scroll updates only viewport state.
- Autopause mode behavior (`AUTOPAUSE ON/OFF`, `IMMERSION_MODE MOVIE/PHRASE`) remains invariant under scroll-only interactions.

## Validation Strategy
- Static audit of mode transitions and handlers touching wheel/seek/tick paths.
- Scenario-based regression matrix across:
  - `AUTOPAUSE: ON/OFF`
  - `IMMERSION_MODE: MOVIE/PHRASE`
  - subtitle topology: primary only, secondary only, dual-track
