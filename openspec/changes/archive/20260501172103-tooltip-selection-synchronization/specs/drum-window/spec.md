## ADDED Requirements

### Requirement: Interactive Translation Tooltip
The Drum Window translation tooltip (E) SHALL support word-level mouse interaction, allowing users to select or move the focus cursor directly from the secondary subtitle display.

#### Scenario: Tooltip Word Selection
- **GIVEN** the translation tooltip is visible in Window Mode (W)
- **WHEN** the user clicks on a word in the tooltip
- **THEN** the system SHALL update the global focus cursor (`FSM.DW_CURSOR_WORD`) to match the clicked word's logical index.
- **AND** the primary Drum Window SHALL immediately update its highlight position to reflect the new selection.
- **AND** the system SHALL NOT blink or dismiss the tooltip during a valid internal word selection.

### Requirement: Surgical Interaction (Gap Pass-Through)
The translation tooltip SHALL follow a "Surgical" interaction model, where mouse hits are only registered on actual text elements.
- **GIVEN** the tooltip is visible
- **WHEN** the user clicks on a transparent "gap" between words or lines in the tooltip
- **THEN** the click SHALL pass through to the underlying Drum Window elements.

### Requirement: Two-Screen Interaction Controls
The system SHALL provide granular toggles in `mpv.conf` to independently control the Primary (Screen 1) and Secondary (Screen 2) tracks for both **Interactivity** and **Highlighting**.
- **Mode DW (W)**: `dw_pri_interactivity`, `dw_pri_highlighting`, `dw_sec_interactivity`, `dw_sec_highlighting`.
- **Mode Drum (C)**: `drum_pri_interactivity`, `drum_pri_highlighting`, `drum_sec_interactivity`, `drum_sec_highlighting`.
- **Mode SRT**: `srt_pri_interactivity`, `srt_pri_highlighting`, `srt_sec_interactivity`, `srt_sec_highlighting`.
- **Global**: `osd_interactivity` SHALL act as the master toggle.

### Requirement: Aesthetic Parity
Secondary subtitles (including the Tooltip) SHALL be visually consistent with the primary track while maintaining specialized readability:
- **Background Color**: SHALL be `000000` (Black) unless overridden.
- **Border size**: SHALL be default to `1.2` for secondary tracks to normalize Cyrillic mono-spaced weight.

### Requirement: No-Stub Verification
Every parameter exposed in `mpv.conf` SHALL be fully wired to its respective logic in `lls_core.lua`. Hardcoded values in place of configured options are prohibited.

#### Scenario: Tooltip Persistent Selection
- **GIVEN** the translation tooltip is visible
- **WHEN** the user Ctrl+Clicks a word in the tooltip
- **THEN** that word SHALL be added to the persistent paired selection set (Pink).
- **AND** the primary Drum Window SHALL show the corresponding primary word as part of the paired set.

#### Scenario: Hit Zone Parity
- **WHEN** the tooltip is rendered or updated
- **THEN** the system SHALL calculate and store bounding box metadata (Hit Zones) for every word in the tooltip.
- **AND** these zones SHALL be correctly mapped to the screen coordinates of the tooltip's right-aligned (`an6`) layout.
