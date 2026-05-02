# Proposal: Calibrate Drum Window Navigation and Visibility

## Objective
The objective of this change is to synchronize the Drum Window's navigation logic and highlighting visuals with established architectural standards (v1.54.12 and v1.58.18) while resolving critical UX regressions in viewport tracking and focus visibility. This ensures that character-level horizontal navigation remains precise and visible, while vertical navigation maintains its word-aware efficiency.

## Motivation
Recent updates to the "Premium" surgical highlighting logic inadvertently made the navigation focus (Gold) and manual selections (Pink) invisible when landing on punctuation tokens. Additionally, horizontal word-level navigation was missing viewport follow-logic, causing the Drum Window to lose focus when the cursor jumped across line boundaries. Formalizing these fixes within the OpenSpec framework ensures they are preserved against future regressions and align with the core project requirements.

## What Changes
- **Rendering Logic**: Refined `format_highlighted_word` to distinguish between automated database highlights (Surgical) and manual user actions (Full-Token).
- **Navigation Logic**: Integrated `dw_ensure_visible` into the `cmd_dw_word_move` loop to ensure the viewport follows the cursor across lines.
- **State Management**: Updated focus visibility to ensure punctuation tokens correctly display the Gold focus indicator when navigated to via the keyboard or mouse.

## Capabilities

### Modified Capabilities
- **drum-window-navigation**: Restored viewport scroll tracking for horizontal navigation and verified character-level precision compliance (ZID: 20260502103050).
- **window-highlighting-spec**: Calibrated focus visibility to ensure manual selections are always visible, even on punctuation tokens, while maintaining surgical aesthetics for database matches.

## Impact
- **lls_core.lua**: Modification of the rendering and navigation functions.
- **User Experience**: Restored visual feedback and reliable viewport following in the Drum Window.
- **Spec Compliance**: Aligned with character-level horizontal precision requirements defined in the architectural baseline.

---
**Anchors**:
- [20260502095036](file:///u:/voothi/20260308110646-kardenwort-mpv/docs/conversation.log#L1161): Initial navigation audit and comparison request.
- [20260502100149](file:///u:/voothi/20260308110646-kardenwort-mpv/docs/conversation.log#L1162): Identification of v1.54.12 parity requirements.
- [20260502101357](file:///u:/voothi/20260308110646-kardenwort-mpv/docs/conversation.log#L1163): Implementation notes for surgical focus and scrolling.
- [20260502103050](file:///u:/voothi/20260308110646-kardenwort-mpv/docs/conversation.log#L1164): Final verification and approval of refined navigation and visibility.
