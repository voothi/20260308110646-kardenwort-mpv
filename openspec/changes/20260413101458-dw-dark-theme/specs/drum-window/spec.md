## ADDED Requirements

### Requirement: Drum Window Localized Aesthetic styling
The Drum Window SHALL render using localized background boxes for each line of text—replacing global panel darkening—to ensure visual parity with the primary Drum mode and optimize contrast for vocabulary highlights against the video.

#### Scenario: Rendering Individual Boxes
- **WHEN** the user opens the Drum Window
- **THEN** the textual content renders as an centered list where each line is individually backed by a translucent high-contrast box (`background-box`), while the rest of the video remains undarkened.

#### Scenario: Vocabulary Visibility
- **WHEN** the user views highlighted Anki terms within these boxes
- **THEN** the system applies vibrant Orange/Gold overlays which pop against the localized dark background, maintaining consistent legibility across all subtitle interfaces.
