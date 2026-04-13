## Why

The Drum Window (`w`) default theme was a nearly solid beige canvas (`A9C5D4`, `alpha=10`), which caused standard Anki green highlights (`71CC2E`) to contrast poorly and wash out due to extreme color mixing. The standard Drum Mode (`c`) does not have this issue because it sits atop MPV's native dark translucent background box (`#C0000000`). This change unifies the "w" mode aesthetic with the "c" mode translucent dark theme to radically improve contrast and readability for saved vocabulary. 

Furthermore, the Search HUD styling requires refinement to match this dark theme, specifically fixing the blue selection highlight which is now unreadable, and transitioning the Anki vocabulary highlights from Green to a more thematic Orange/Gold palette.

## What Changes

- Change Drum Window background to a translucent black pane (`000000`, `alpha=60`) replacing the beige theme.
- Update inactive Drum Window text to light gray (`CCCCCC`) while keeping the active line pure white (`FFFFFF`).
- Update hover cursor highlight to bright cyan (`00FFFF`) to clearly pop on dark mode.
- Update Search rendering selection highlight from Blue to warm White/Gold for visibility over dark background.
- Transition Anki highlights from Green shades to the project's signature Orange/Gold palette (`0075D1`, `005DAE`, `003A70`).
- Change tooltip default background to opaque dark gray (`222222`, `alpha=11`) to float above the translucent window rather than blending in.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `drum-window`: Modifies the core aesthetic requirement from "beige/readable canvas" to "translucent dark mode interface" to structurally support standard Anki highlight visibility and color contrast.

## Impact

- `lls_core.lua`: Default `dw_*` configurations, default search hit configurations, and default tooltip configurations.
- `mpv.conf`: User-level script options for `lls-dw_*`, `lls-search_*`, and `lls-dw_tooltip_*`.
