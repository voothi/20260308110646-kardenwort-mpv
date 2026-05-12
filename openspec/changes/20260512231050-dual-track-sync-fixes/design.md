## Context

Kardenwort-mpv is a Lua-based mpv configuration focused on language acquisition through dual-subtitle consumption. The system uses a Finite State Machine (FSM) to track active subtitle indices for both primary (lower) and secondary (upper) tracks.

**Current State:**
- Navigation operations (a, d, Shift+a/d) trigger a cooldown period (`kardenwort-nav_cooldown`) before the FSM sentinel scan updates indices
- Replay operations seek back in time and repeat segments, but only anchored the primary track
- Secondary track anchoring relied on natural sentinel scan after cooldown, causing visual lag when primary/secondary timings are misaligned

**Problem:**
When primary and secondary subtitle timings are not perfectly aligned (common in real-world content), the upper secondary track visually lags behind during:
1. Fast Shift+a/d scrubbing in DM mode
2. Repeated Replay (`s`) presses

This creates a jarring user experience where the upper text appears delayed even though the scroll/replay logic is working correctly.

## Goals / Non-Goals

**Goals:**
- Eliminate visual lag of secondary subtitles during Shift+a/d time seeks
- Prevent dual-track desynchronization during repeated Replay operations
- Maintain backward compatibility with existing configuration and behavior
- Provide test coverage for dual-track synchronization scenarios

**Non-Goals:**
- Changing the underlying subtitle timing alignment (that's a content issue)
- Modifying the sentinel scan logic (only adding immediate anchors)
- Changing replay duration or count behavior

## Decisions

### 1. Immediate Dual-Track Anchoring in `cmd_seek_time()`

**Decision:** Anchor both `FSM.ACTIVE_IDX` and `FSM.SEC_ACTIVE_IDX` immediately before issuing the seek command in `cmd_seek_time()`.

**Rationale:**
- The cooldown period (0.5s → 0.2s) is still necessary to prevent index thrashing
- However, we can bypass the visual lag by immediately anchoring both tracks to their target indices
- The sentinel scan will naturally update after cooldown, but the user sees correct positioning immediately
- This is a minimal change that doesn't alter the core FSM logic

**Alternatives Considered:**
- *Eliminate cooldown entirely*: Would cause index thrashing and instability
- *Separate cooldown for secondary track*: Adds complexity without clear benefit
- *Delay secondary track display*: Would increase visual lag

### 2. Dual-Track Anchoring in All Replay Paths

**Decision:** Anchor both tracks at replay start in three replay functions:
- `cmd_replay_sub()`: Initial replay trigger (both Autopause ON/OFF)
- `tick_loop()`: Each loop iteration (Autopause OFF)
- `tick_scheduled_replay()`: Each scheduled replay iteration (Autopause ON)

**Rationale:**
- Repeated Replay presses can cause drift if only the primary track is anchored
- Each seek operation needs dual-track anchoring to maintain synchronization
- The same pattern applies across all replay modes for consistency

**Alternatives Considered:**
- *Only anchor in cmd_replay_sub()*: Would not prevent drift during loop iterations
- *Use a single replay anchor function*: Would require refactoring existing code structure

### 3. Reduced Navigation Cooldown

**Decision:** Reduce `kardenwort-nav_cooldown` from 0.5s to 0.2s.

**Rationale:**
- The immediate anchoring reduces the need for a long cooldown period
- 0.2s provides sufficient stability while reducing perceived lag
- This is a conservative reduction that maintains system stability

**Alternatives Considered:**
- *Keep at 0.5s*: Would maintain longer visual lag
- *Reduce to 0.1s*: Could introduce instability in edge cases

### 4. Restore Diagnostics Property

**Decision:** Restore `user-data/kardenwort/last_osd` property initialization and updates in `show_osd()`.

**Rationale:**
- This property was previously used by acceptance tests for OSD verification
- The configurable replay messages feature depends on this IPC contract
- Adding it back is a minimal change with high test value

**Alternatives Considered:**
- *Rewrite tests to not depend on OSD property*: Would require significant test refactoring
- *Use a different diagnostics mechanism*: Would break existing test patterns

## Risks / Trade-offs

**Risk:** Immediate anchoring could potentially mask timing misalignments that are actually content issues.

**Mitigation:** The sentinel scan still runs after cooldown, so any genuine timing issues will still be detected. Immediate anchoring only affects visual presentation, not the underlying logic.

**Risk:** Reduced cooldown could increase index thrashing in edge cases with rapidly changing subtitles.

**Mitigation:** 0.2s is still a reasonable cooldown period. Testing should validate stability with various subtitle content.

**Trade-off:** Adding dual-track anchoring increases code complexity in multiple functions.

**Mitigation:** The pattern is consistent across all functions, making it maintainable. The complexity is justified by the significant UX improvement.

## Migration Plan

This change is implemented as a direct code update with no migration steps required:

1. Configuration change: Users with custom `kardenwort-nav_cooldown` values may want to adopt the new 0.2s default
2. No data migration needed (no persistent state changes)
3. No API changes (internal implementation only)
4. Tests validate the new behavior before deployment

**Rollback Strategy:**
- Revert to previous commit if issues arise
- Restore `kardenwort-nav_cooldown=0.5` if reduced cooldown causes instability

## Open Questions

None. The implementation is straightforward and well-tested.
