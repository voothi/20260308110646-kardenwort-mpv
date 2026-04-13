# drum-window Specification

## Purpose
TBD - created by archiving change 20260412184520-anki-highlighter. Update Purpose after archive.
## Requirements
### Requirement: Drum Window Anki Export Activation
The Drum Window FSM mode SHALL listen to `MBTN_MID` to initiate the Anki TSV row export for the currently active Drag/Word selection.

#### Scenario: Triggering Export via Mouse
- **WHEN** the Drum Window mode is active and the user presses `MBTN_MID` over an active text selection
- **THEN** the core export mechanism is triggered with the indices of the selection passed to the exporter, and any active tooltips for that line are suppressed to prevent visual overlap.

### Requirement: Contextual Range Expansion
The Drum Window SHALL allow capturing context from a configurable number of surrounding lines (`anki_context_lines`) when mining.

#### Scenario: Multi-line mining
- **WHEN** the user exports a single word
- **THEN** the system gathers `N` subtitle lines before and after the active line to provide a rich context for the Anki card.

### Requirement: Drum Window Unified Styling
The Drum Window SHALL allow explicit control over its appearance (font size, weight, and background transparency) via script options, matching the parameters of other HUD components.

#### Scenario: Background Opacity Alignment
- **WHEN** the `dw_bg_opacity` and `dw_text_opacity` configurations are adjusted
- **THEN** the system SHALL apply the corresponding Alpha values (`\4a` and `\1a`) to the Window's localized background boxes and text respectively.

#### Scenario: Visual Normalization
- **WHEN** the user configures `dw_font_size`, `dw_border_size`, or `dw_shadow_offset`
- **THEN** the Drum Window SHALL apply these precisely to the rendering block, allowing the user to visually normalize the monospace interface to match the proportional Drum Mode interface.

