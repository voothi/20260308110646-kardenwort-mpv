# Proposal: Drum Mode Rendering and OSD Refinement (v1.26.12)

## Problem
Drum Mode suffered from visual artifacts including background box overlaps, inconsistent vertical gaps between lines, and a lack of synchronization with live subtitle position properties. Additionally, default mpv OSD elements (like the progress bar) cluttered the screen during navigation.

## Proposed Change
Refactor the Drum Mode rendering logic to use unified ASS tagging and anchors, synchronize visual coordinates with live properties, and refine the OSD configuration for a cleaner user experience.

## Objectives
- Eliminate background box bleeding in Drum Mode by grouping lines.
- Remove artificial vertical gaps caused by double newlines and split anchors.
- Enable live adjustment of Drum Mode subtitle positions via standard property updates.
- Streamline the OSD by disabling redundant bars and standardizing border styles.

## Key Features
- **Unified Drum Rendering**: Grouped previous, active, and future contexts into a single ASS block.
- **Vertical Gap Elimination**: Fixed newline concatenation and standardized on `\an8`/`\an2` anchors.
- **Live Positioning Sync**: `tick_drum()` now respects and reflects changes to `secondary-sub-pos`.
- **OSD Cleanup**: Disabled `osd-bar` and forced `outline-and-shadow` border style for Drum Mode.
