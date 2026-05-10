## Context

The current autopause implementation in `scripts/lls_core.lua` has complex state management for handling rewind operations. When users press `s` (replay-subtitle) or `Shift+a/d` (seek time backward/forward), the system tracks multiple states to determine when to restore autopause behavior. This complexity makes the code harder to maintain and understand.

The project uses Lua scripts for mpv with a focus on language acquisition and dual-subtitle consumption. The autopause feature is critical for this use case, allowing users to pause at phrase/word boundaries for study purposes.

## Goals / Non-Goals

**Goals:**
- Simplify autopause logic during rewind operations by using a time-based suppression approach
- Temporarily disable autopause for the exact duration of the rewind when `s`, `Shift+a`, or `Shift+d` is pressed
- Automatically restore autopause state after the rewound duration elapses
- Maintain existing autopause behavior for normal playback (pause at phrase/word boundaries)

**Non-Goals:**
- Changing the core autopause behavior (pause at phrase/word boundaries)
- Modifying other keybindings or features
- Adding configuration options for this behavior

## Decisions

### Time-based suppression instead of state tracking

**Decision**: Use a simple timer-based approach where autopause is suppressed for `current_time - previous_time` seconds when a rewind occurs.

**Rationale**: 
- Eliminates complex state machine logic
- Directly maps to user intent: "I rewound X seconds, don't pause for X seconds"
- Easier to understand and maintain
- No edge cases from state transitions

**Alternatives considered**:
1. **State machine with pause count**: Track number of pauses skipped. Rejected because it requires maintaining counter state and handling edge cases.
2. **Event-based suppression**: Suppress until next subtitle boundary. Rejected because it doesn't align with user's mental model of "rewound duration."

### Single suppression timer

**Decision**: Use a single timer for all rewind operations rather than per-operation timers.

**Rationale**:
- Simpler implementation
- If user performs multiple rewinds quickly, the longest duration wins (most conservative)
- No need to manage multiple timers

**Alternatives considered**:
1. **Per-operation timer**: Track each rewind separately. Rejected because it adds complexity without clear user benefit.

### Modification of existing autopause system

**Decision**: Extend the existing `karaoke-autopause` system rather than creating a separate system.

**Rationale**:
- Reuses existing autopause infrastructure
- Single source of truth for pause behavior
- Minimal code changes

**Alternatives considered**:
1. **Separate rewind-specific pause system**: Rejected because it would duplicate logic and create inconsistency.

## Risks / Trade-offs

**Risk**: Timer-based approach may not align perfectly with subtitle boundaries
**Mitigation**: The suppression duration is based on actual time rewound, which is what users expect. If the timer expires mid-subtitle, autopause will trigger at the next boundary as normal.

**Risk**: Multiple rapid rewinds could extend suppression longer than intended
**Mitigation**: This is acceptable behavior - if user keeps rewinding, they likely want continuous playback without interruptions.

**Trade-off**: Simpler code vs. more granular control
**Analysis**: We prioritize simplicity and maintainability over edge-case precision. The time-based approach covers the 99% use case.

## Migration Plan

1. Add `suppression_end_time` variable to track when autopause suppression should end
2. Modify `replay-subtitle`, `lls-seek_time_backward`, and `lls-seek_time_backward` bindings to set suppression timer
3. Add check in autopause logic to skip pause if `current_time < suppression_end_time`
4. Test with various rewind scenarios
5. Remove old complex state management code

**Rollback strategy**: Git revert if issues arise. The change is localized to `lls_core.lua`.

## Open Questions

None - the design is straightforward with clear implementation path.
