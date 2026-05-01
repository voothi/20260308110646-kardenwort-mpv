# Design: Tooltip Selection Synchronization

## Overview
This change implements high-fidelity interactive selection within the translation tooltip and synchronizes its highlight state with the primary Drum Window. It also introduces a flattened, track-aware hit-testing architecture and granular per-screen interaction controls.

## Interaction Model

### Architectural Pattern: Two-Screen (Pri/Sec) Granularity
The system treats all viewing modes as a "Two-Screen" composition:
- **Screen 1 (Primary)**: The target language track (Lower track in C/SRT, Main block in W).
- **Screen 2 (Secondary)**: The translation track (Upper track in C/SRT, Tooltip in W).

Configuration provides independent toggles for **Interactivity** and **Highlighting** (Backlight) for each screen in each mode, allowing users to isolate study focus.

### Refactored Interaction: Flattened Hit-Testing
To eliminate nested complexity and improve performance, the hit-testing pipeline follows a "Track-Aware" model:
- OSD renderers tag every hit-zone with an `is_pri` flag during generation.
- Hit-testers return this flag as part of the match result.
- The global dispatcher (`lls_hit_test_all`) performs flat, O(1) filtering against the `pri/sec` interactivity flags, avoiding expensive post-hit investigation loops.

### Aesthetic Parity Standard
Secondary subtitle text in all modes (Tooltip or Track 2) maintains a synchronized visual weight:
- **Background**: `000000` (Pure Black) for maximum contrast parity with primary text.
- **Border Weight**: Calibrated to `1.2` for mono-spaced Cyrillic to avoid perceived "boldness" in centered layouts.

### Surgical Hit-Zone Pipeline
Interaction follows a **Surgical Model**. Hit zones are populated during the rendering phase and cached in mode-specific draw caches.
- **Granularity**: Hit zones are created at the word level within visual lines.
- **Occlusion**: The tooltip (`z=25`) has priority over the Drum Window (`z=20`). Clicks land on tooltip words first.
- **Pass-Through**: Clicks in "gaps" (between words or lines) pass through to the background elements, maintaining high-precision background interaction.

## Stability and Flicker Prevention
To ensure a premium UX, the rendering pipeline implements two suppression mechanisms:
- **Sticky Quick-View**: During RMB-hold, the tooltip maintains its last valid state even if the cursor passes through empty gaps between subtitle lines.
- **Click-Blink Suppression**: The `is_tooltip_hit` check prevents OSD dismissal when the user clicks a valid word inside the tooltip.

## Cache Integrity
- **O(1) Rendering**: All tooltip layout and hit-zone calculations are memoized in `DW_TOOLTIP_DRAW_CACHE`.
- **Invalidation**: The tooltip cache is strictly invalidated by the global `flush_rendering_caches()` signal.
