# Proposal: Unify Drum Mode Wheel Scroll

## Problem
Currently, mouse wheel interaction in Drum Mode (on-screen subtitles) is either inactive or behaves inconsistently compared to the Drum Window (DW). The user reports that scrolling currently affects playback/seeking (or feels inverted) and lacks the "viewport-only" scrolling capability of the Drum Window. This creates a functional discrepancy between the minimalist Drum Mode and the full Drum Window interface.

## Proposed Change
Implement a unified wheel-scroll mechanism for Drum Mode that allows users to scroll through the subtitle context (viewport) without changing the current playback position. 

Key improvements:
1. **Viewport Scrolling**: In Drum Mode, the mouse wheel will now adjust a scroll offset, allowing the user to see earlier/later subtitles without seeking the video.
2. **Direction Alignment**: Ensure the scroll direction is "natural" (scrolling down moves to later subtitles), matching the Drum Window behavior.
3. **Follow-Player Logic**: Subtitles will automatically resume following the player once the user initiates a manual seek (a/d) or a double-click, mirroring the Drum Window's "Follow Player" state management.
4. **Interaction Separation**: Clear separation between "working with the track" (seeking via a/d) and "working with the text" (scrolling via wheel).

## Impact
- **Consistency**: Unified UX across all immersion modes.
- **Precision**: Users can review previous/upcoming text without disrupting their listening focus.
- **Ergonomics**: Natural scroll direction for better usability.
