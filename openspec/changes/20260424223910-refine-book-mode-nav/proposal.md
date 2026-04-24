# Refine Book Mode Navigation and Scrolling

## Problem Statement
The current Book Mode navigation in the Drum Window has several regressions. Manual navigation using `a`/`d` keys (seeking) fails to correctly update the viewport or maintain a consistent "white pointer" (active subtitle) focus. Furthermore, the scrolling behavior during playback does not correctly handle viewport edges, causing the active subtitle to go off-screen. The user requires a stable, text-editor-like experience where manual movement "pushes" the view line-by-line, and playback "flips" the page when reaching configurable margins.

## Success Criteria
- Manual navigation (`a`/`d`) correctly updates both active subtitle and cursor, ensuring visibility via line-by-line "push" scrolling.
- Automatic playback triggers "page-by-page" (viewport jump) scrolling when the active subtitle hits configurable margins.
- Viewport margins (header/footer) are configurable via `mpv.conf`.
- Consistent behavior in Book Mode ON that mimics a professional text editor.

## What Changes
- Restore the `paged` logic in `dw_ensure_visible` to support both "push" and "jump" scrolling modes.
- Update `tick_dw` to use paged scrolling for the active line during playback.
- Update `cmd_dw_seek_delta` to use pushed scrolling for manual navigation.
- Ensure `a`/`d` keys are repeatable and correctly update the yellow cursor focus.
- Externalize margin settings to `Options.dw_scrolloff`.

## Capabilities

### New Capabilities
- `dw-configurable-margins`: Allows users to set the number of lines of context maintained at the top/bottom of the Drum Window.

### Modified Capabilities
- `drum-window-navigation`: Updates manual and automatic navigation logic in Book Mode to handle viewport boundaries correctly.

## Impact
- `scripts/lls_core.lua`: Significant logic refactor in navigation and scrolling handlers.
- `mpv.conf`: New/updated configuration options for scrolling margins.
