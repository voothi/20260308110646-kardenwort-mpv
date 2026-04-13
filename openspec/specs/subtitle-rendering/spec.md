## ADDED Requirements

### Requirement: Unified Mode Styling (SRT & Drum)
The system SHALL provide explicit, synchronized configuration parameters for font selection and weight across standard SRT and Drum (c) rendering modes.

#### Scenario: Customizing Fonts
- **WHEN** the user configures `srt_font_name` or `drum_font_name`
- **THEN** the respective rendering mode SHALL apply that font family to the OSD output.

#### Scenario: Font Strength/Boldness
- **WHEN** the `srt_font_bold` or `drum_font_bold` options are toggled
- **THEN** THE OSD SHALL apply the corresponding `\b1` or `\b0` ASS tags to the rendered subtitle text.

### Requirement: Dynamic Visibility Suppression
The system SHALL periodically suppress native mpv subtitles whenever a custom OSD-based subtitle mode (SRT-OSD, Drum Mode, or Drum Window) is active to prevent visual overlap.

#### Scenario: Global Suppression Guard
- **WHEN** any OSD-based subtitle mode is active
- **THEN** the system SHALL force `sub-visibility` and `secondary-sub-visibility` to `false` in every master logic tick.
