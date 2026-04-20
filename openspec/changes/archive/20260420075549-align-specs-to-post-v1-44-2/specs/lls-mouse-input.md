# lls-mouse-input Specification

## Purpose
Provide a robust, high-precision mouse interaction model for the Drum Window that accommodates hardware jitter (ghost clicks), minimalist input devices (remote controls), and variable viewport scrolling.

## Requirements

### Requirement: Global Interaction Shield
To support remote control mappers (e.g., JoyToKey/8BitDo) that produce hardware-level jitter, the system SHALL implement a temporal suppression layer for mouse events.
- **Suppression Window**: 50ms.
- **Trigger**: Any keyboard or remote navigation command (Seek, Add, Pair, Arrows, ESC).
- **Behavior**: All incoming mouse events (down/up/move/scroll) SHALL be discarded while the lock is active.
- **Exemption**: Standalone modifier key presses (Ctrl/Shift) SHALL NOT trigger the shield.

### Requirement: Coordinate-Precise Sync (Pointer Jump Sync)
The system SHALL ensure the logical focus and highlight anchor are synchronized to the exact pixel-perfect word under the mouse pointer immediately *before* any action is dispatched.
- **Rationale**: Prevents actions from being applied to a previously "hovered" word if the pointer has jumped due to hardware latency.

### Requirement: Zero-Collapse Clamping
The hit-testing engine SHALL implement logical index clamping for all margin and whitespace areas.
- **Boundary Behavior**: Dragging outside the text block, into line gaps, or past line ends SHALL snap the selection to the nearest boundary word's logical index.
- **Goal**: Prevent selection "collapse" or "breakage" caused by returning non-selectable visual token indices.

### Requirement: Selection Refresh Polling
During active dragging operations, the system SHALL poll the selection state at 20FPS (50ms interval).
- **Behavior**: The selection boundary SHALL be re-evaluated on a timer to ensure smooth tracking even if OS-level mouse movement events are dropped or delayed by system load.

### Requirement: Persistent Ctrl Modifier Tracking
The system SHALL track the state of the `Ctrl` key to route gestures between contiguous (Warm) and paired (Cool) selection paths.
- **Persistence**: While `ctrl_held` is tracked, the release of the key MUST NOT automatically trigger a "discard" of any existing selection sets (Pink set remains persistent).

### Requirement: RMB Interaction & Tooltip Pinning
The system SHALL bind `MBTN_RIGHT` dynamically within the Drum Window to manage informational tooltips.
- **Interaction**: Single-click on a word SHALL pin/unpin the tooltip.
- **Isolation**: RMB interactions MUST be isolated from the highlighting engine to prevent unwanted cursor changes during informational lookups.

### Requirement: State-Aware Scroll Synchronization
The mouse input system SHALL ensure that viewport-altering events (scrolling) only synchronize the logical cursor state when an active user-initiated interaction (dragging) is in progress.
- **Passive Scroll Stability**: Passive scrolling SHALL NOT update highlight coordinates based on mouse position.
- **Active Drag Sync**: Scrolling while holding a button SHALL continuously update hit-test coordinates.

### Requirement: Stream-Agnostic Initialization
Drum Window activation SHALL support internal and embedded subtitle streams that lack local file paths, provided subtitle segments are loaded in the engine's memory.

### Requirement: Gesture Routing (Warm vs. Cool)
- **Warm Path (Contiguous)**: LMB/MMB without `Ctrl` -> Contiguous Drag/Selection.
- **Cool Path (Paired)**: Interactions with `Ctrl` (or specific Pairing keys) -> Addition to `ctrl_pending_set`.
