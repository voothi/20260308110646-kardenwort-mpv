## Context

Drum window mode currently lacks a feature to display secondary subtitles contextually. The goal is to show a translation tooltip while preserving the exact layout structure defined in `dw_build_layout` and `dw_hit_test`. The current logic tightly coordinates the display based on text index, wrapping, and absolute positioning on screen.

## Goals / Non-Goals

**Goals:**
- Present a right-floating, text-wrapping translation tooltip upon Right Mouse Button click.
- Prevent modifying the core structure of `dw_build_layout` to ensure zero impact on existing window calibration.
- Allow simple, immediate dismissal of the tooltip by moving the mouse to a different subtitle line.
- Be structurally prepared for a phase 2 "Hover Mode" config easily configurable via `mpv.conf`.

**Non-Goals:**
- Completely rewriting the window rendering logic.
- Aligning translations per-word (aligns per phrase/subtitle line).
- Adding interactive elements (buttons, clicking links) inside the tooltip.

## Decisions

- **Segregated OSD:** The tooltip will be rendered using a dedicated new OSD object `dw_tooltip_osd` at `z=25`. This avoids layout-breaking interactions with `dw_osd` (z=20) and `search_osd` (z=30).
- **Hit-Test Reuse:** The system will repurpose `dw_hit_test(osd_x, osd_y)` to fetch `line_idx` during mouse move events, avoiding duplicating coordinate calculation logic.
- **State Properties:** Introduce `FSM.DW_TOOLTIP_LINE` and `FSM.DW_TOOLTIP_MODE` ("CLICK" vs "HOVER") to track the tooltip lifecycle smoothly. Pinning on click vs pinning constantly on move.
- **Fixed Wrapping Constraints:** The tooltip will use a fixed anchor layout on the right side `{\pos(1850, y)}{\an6}`, employing soft-wrapping tags (`\N`) where needed, and a semi-transparent box `{\1a&H77&}` to layer harmlessly over long English content.

## Risks / Trade-offs

- **Overlap on Small Windows:** An absolute positioned tag near `x=1850` might overflow on non-standard aspect ratios.
  - *Mitigation:* We will hook the scaling accurately via the existing `scale_isotropic` logic or enforce safe margin padding natively in ASS rendering.
- **Excessive Event Firing:** Polling mouse positions might occur faster than UI renders.
  - *Mitigation:* Ensure hitting the same `line_idx` does not trigger redundant redraws or text collation. Only update `dw_tooltip_osd` when the target line actually changes.
- **Hit Test Clamping UI Issue:** `dw_hit_test` currently snaps coordinates to the nearest word/line even if the cursor is in the empty margins. Thus, moving the pointer off the line horizontally won't change the `line_idx` and won't dismiss the tooltip. 
  - *Mitigation:* This actually acts as a feature, allowing users to hover the mouse *over the tooltip itself* without it dismissing. No change required; we let it snap.
- **Scrolling Dynamics:** If the user scrolls using the keyboard (`a`, `d`) while the mouse remains stationary, the window grid shifts independently of the cursor.
  - *Mitigation:* `dw_hit_test` recalculates natively based on the new layout. A stationary mouse over scrolling text inherently triggers a line departure, so the tooltip elegantly and correctly auto-dismisses (in click mode) or updates to the new line (in hover mode).
- **ASS Tag Bleed:** Pulling raw `Tracks.sec.subs` text might inject unescaped ASS tags into the tooltip macro causing massive visual breakage.
  - *Mitigation:* We will enforce using `sub.raw_text` or stripping `{}` in `draw_dw_tooltip()` to guarantee payload safety.
