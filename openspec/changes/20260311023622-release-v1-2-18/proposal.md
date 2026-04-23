## Why

This change formalizes the Advanced Mouse Selection & Navigation introduced in Release v1.2.18. To make the Drum Window feel like a professional text editor, it was necessary to move beyond simple keyboard navigation and implement high-precision mouse interaction. This required an architectural shift in how subtitle layouts are calculated and how the player handles native OS events like window dragging.

## What Changes

- Implementation of a **Unified Layout Engine**: The `dw_build_layout` function now calculates hard visual line breaks using proportional font-width estimation, ensuring that mouse click coordinates always match the rendered words.
- Implementation of **Hardware-Accelerated Dragging**: Text selection now binds to the `mouse_move` event, providing a fluid, high-frame-rate dragging experience.
- Implementation of **OS Conflict Resolutions**: The script now manages native player properties (e.g., setting `window-dragging=no`) to prevent the OS from intercepting clicks meant for text selection.
- Implementation of **Advanced Mouse Workflows**:
    - **Double-Click to Seek**: Instant playback synchronization by double-clicking any subtitle in the Drum Window.
    - **Point-to-Point Selection**: Refined `Shift+MBTN_LEFT` logic for extending selections without dragging.
- Refinement of **Scroll Synchronization**: Logic to snap the viewport back to the cursor if the user navigates after scrolling away.

## Capabilities

### New Capabilities
- `dw-mouse-selection-engine`: A high-precision UI system that bridges the gap between ASS-rendered text and pixel-perfect mouse interaction.
- `native-conflict-management`: Mechanisms for temporarily suppressing native player or OS behaviors to protect the integrity of the script's interactive environment.

### Modified Capabilities
- None (Major interaction overhaul).

## Impact

- **Ergonomics**: A more intuitive, mouse-centric workflow for selection and navigation.
- **Precision**: Elimination of "missed clicks" through hard layout calculation and bounding-box snapping.
- **Reliability**: Seamless operation in dual-track environments without Clashing with native subtitle layers or OS-level window management.
