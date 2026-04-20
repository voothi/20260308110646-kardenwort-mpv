## Context

The current `lls_core.lua` script (v1.44.2) implements a highly refined interaction and grounding engine. This design document formalizes the architectural decisions that govern Multi-Pivot Grounding, persistent selection sets, and hardware jitter resilience. These features have been iteratively developed to support professional-grade language immersion, particularly for remote-control and non-standard input environments.

## Goals / Non-Goals

**Goals:**
- Formalize the **Multi-Pivot Grounding** coordinate system (`LineOffset:WordIndex:TermPos`).
- Standardize the **Interaction Shield** logic for hardware-resilient input handling.
- Stabilize the **"Warm vs. Cool"** visual feedback loops.
- Ensure all inter-segment join logic remains high-recall via the **10.0s temporal window**.

**Non-Goals:**
- This is not a refactor of the existing code; the implementation is considered the ground truth.
- No new logical features are being introduced in this change cycle.

## Decisions

### 1. Multi-Pivot Grounding Coordinates
To eliminate "highlight bleed" (where identical words in the same segment share a highlight), the system generates a coordinate map for every word in a selection. 
- **Format**: `LineOffset:WordIndex:TermPos` (e.g., `0:4:1` means Line Offset 0, Word 4, 1st term component).
- **Rationale**: This allows the renderer to uniquely identify the exact word occurrence associated with a database record, even if the same word appears multiple times in the context.

### 2. Interaction Shielding (150ms)
To support remote controls (like the 8BitDo Zero 2) which often produce ghost clicks when mapped to keyboard keys, the system implements a temporal lock.
- **Mechanism**: Every keyboard/remote command sets `FSM.DW_MOUSE_LOCK_UNTIL = current_time + 150ms`.
- **Rationale**: 150ms is the "sweet spot" for filtering hardware jitter without introducing perceived input lag during legitimate mouse interaction.

### 3. Persistent Selection State
The system decouples the `FSM.DW_CTRL_PENDING_SET` (Pink selection) from the physical state of the `Ctrl` key.
- **Rationale**: Minimalist remotes cannot easily "hold" modifiers while searching or scrolling. Making the selection persistent ensures that users can curate complex non-contiguous phrases step-by-step regardless of their layout.

### 4. High-Recall Temporal Bridging
Inter-segment sequence verification is governed by `anki_local_fuzzy_window = 10.0`.
- **Rationale**: Fragmented subtitles (common in news reports) require a larger look-ahead buffer than the standard 1.5s to ensure phrases remain highlighted during natural speaker pauses.

## Risks / Trade-offs

- **Memory Overhead**: Tracking coordinates for every word in long phrases increases TSV field length, but modern storage and Lua string-handling make this impact negligible compared to the precision gained.
- **User Discovery**: Persistent selections require an explicit "Discard" (Ctrl+ESC), which may be unfamiliar to users used to standard browser selection behaviors. This is addressed through consistent "Cool Path" (Pink) visual cues.
