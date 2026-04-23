# Proposal: Search Box Visibility Fix (OSD Styling) (v1.26.28)

## Problem
When the global mpv setting `osd-border-style=background-box` (Black Frame) is active, the `Ctrl+f` search box and the Drum Window become difficult to read. The OSD draws semi-transparent black boxes behind text that already has a custom beige background panel, causing visual clutter and overlapping artifacts.

## Proposed Change
Implement a dynamic OSD border override system that temporarily switches the border style to `outline-and-shadow` while custom UI components are active, and restores the user's original style when they are closed.

## Objectives
- Ensure high readability for Search Mode and Drum Window text regardless of global OSD settings.
- Implement reference-aware state management to prevent premature style restoration.
- Maintain the user's aesthetic preferences for standard OSD messages when custom UI is not visible.

## Key Features
- **Dynamic OSD Border Override**: On-the-fly adjustment of `osd-border-style`.
- **State-Aware UI Management**: `manage_ui_border_override` tracks the visibility of multiple UI components.
- **Reference Counting**: The original style is only restored when all custom UI panels are dismissed.
- **Improved Visual Clarity**: Standardized text rendering on top of custom UI backgrounds.
