## MODIFIED Requirements

### Requirement: Paged Viewport (Auto-Scrolling) in Book Mode
When in Book Mode, the system SHALL keep active subtitle visible using paged viewport behavior.

#### Scenario: Playback progression parity in DW and DM
- **WHEN** Book Mode is ON and playback advances
- **THEN** active highlight SHALL move
- **AND** viewport SHALL page when active line reaches configured margin
- **AND** this behavior SHALL apply in both Drum Window (W) and Drum Mode mini viewport (C with W closed).

#### Scenario: Enabling Book Mode while DM is active
- **WHEN** Drum Mode (C) is active and Drum Window (W) is closed
- **AND** user enables Book Mode
- **THEN** system SHALL keep user in DM (no forced transition to DW)
- **AND** DM viewport SHALL adopt Book Mode paged follow behavior equivalent to DW.
