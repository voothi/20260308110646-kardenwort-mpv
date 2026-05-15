## ADDED Requirements

### Requirement: Dynamic Help Display
The help system must display a list of current keyboard shortcuts by querying the active mpv input state and script options.

#### Scenario: Pressing F1 to open help
- **WHEN** the user presses F1
- **THEN** a semi-transparent HUD overlay appears covering the center of the screen
- **AND** it displays categorized shortcuts (Global, Navigation, Drum Mode, Search, Mining)
- **AND** it shows the *actual* keys bound to these actions (e.g., if Autopause is remapped to 'P', it shows 'P')

#### Scenario: Pressing F1 to close help
- **WHEN** the Help HUD is open and the user presses F1 (or ESC)
- **THEN** the Help HUD is immediately hidden

### Requirement: Multi-Layout Key Support
The help system must correctly identify and display both English and Russian layout variants of a key if they are bound to the same action.

#### Scenario: Displaying Dual-Layout Keys
- **WHEN** an action is bound to both 's' and 'ы'
- **THEN** the help entry should show "s / ы" or "s (ы)" for that action.

### Requirement: Visual Consistency
The Help HUD must match the visual language of Kardenwort (monospaced fonts, semi-transparent backgrounds, specific highlight colors).

#### Scenario: Theming the HUD
- **WHEN** the Help HUD is rendered
- **THEN** it uses `Consolas` font (or configured `dw_font_name`)
- **AND** it uses `Options.dw_bg_color` and `Options.dw_bg_opacity` for the background
- **AND** headers are highlighted using `Options.dw_highlight_color`.
