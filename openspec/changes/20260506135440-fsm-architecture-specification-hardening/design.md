## Context

The immersion engine's Finite State Machine (FSM) governs all navigation and OSD rendering. The `get_center_index` function is the critical link between the media timeline and the state machine. Recent failures demonstrated that minor reorderings of logic in this function can break high-level features like \"Autopause ON PHRASE\" by causing early handover between subtitles (The Padding Trap).

## Goals / Non-Goals

**Goals:**
- Codify the stable \"mainline\" logic for index resolution.
- Enforce the priority hierarchy to protect audible tails.
- Fix broken architectural diagrams to maintain the \"Source of Truth.\"

**Non-Goals:**
- Changing the actual Autopause or Jerk-Back logic (only the detection mechanism).
- Introducing new FSM states.

## Decisions

- **Deterministic Evaluation Order**: The `get_center_index` function must follow a strict hierarchy:
  1. **Sticky Focus Sentinel**: Check if the playhead is still within the padded boundaries of `FSM.ACTIVE_IDX`. If yes, return immediately.
  2. **Binary Search**: If the sentinel loses claim, find the first subtitle whose `start_time` is less than or equal to `time_pos`.
  3. **Overlap Priority**: Check if the *next* subtitle's padded start has already begun.
  - *Rationale*: This order prevents \"Early Handover\" where the next sub's padding triggers a Jerk-Back before the current sub's audio tail (padding end) has finished playing.

- **Loop Protection (JUST_JERKED_TO)**:
  - When the Jerk-Back logic fires, it sets `FSM.JUST_JERKED_TO`.
  - The Sentinel must use this flag to suppress jumping back to the previous sub if the playhead lands in an overlap gap after the seek.

- **Diagram Flattening**:
  - The `state-diagram.md` will be updated to remove nested state definitions that cause Mermaid syntax errors.
  - Typographic errors (e.g., `DR_MODE`) will be corrected to match the code's `DRUM_MODE`.

## Risks / Trade-offs

- **[Risk]** Over-prioritizing the Sentinel could delay Jerk-Back if padding is extremely large.
  - **Mitigation**: The system relies on `nav_tolerance` and `nav_cooldown` to allow for manual overrides.
