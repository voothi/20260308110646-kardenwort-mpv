## Why

The current highlighting rules for "Window Mode" (Drum Window) are fragmented across multiple source files and historical archived changes. To ensure consistent development and AI-agent alignment during the evolution of the utility, a single, formal source of truth is required that describes all highlighting cases, color overlays, and palette interactions specifically for SRT subtitles.

## What Changes

- Creation of a formal specification document for Window Mode highlighting.
- Consolidation of highlighting rules involving the three core palettes (Standard, Split, Mixed).
- Explicit documentation of color overlay precedence and depth-stacking logic for word-level highlights.
- Removal of implementation ambiguity for AI agents working on subtitle rendering.

## Capabilities

### New Capabilities
- `window-highlighting-spec`: A comprehensive formal description of all word highlighting behaviors, color schemes, and overlay rules in the Drum Window (Mode W) for SRT subtitles.

### Modified Capabilities
- `anki-highlighting`: Will be referenced as the source for backend database logic, but requirements for visual rendering in window mode will be centralized in the new specification.

## Impact

This is a documentation-centric change. It impacts how future features (like ASS support or rendering optimizations) are planned but does not immediately alter the runtime code. It serves as the "Ground Truth" for the high-recall highlighting engine's visual output.
