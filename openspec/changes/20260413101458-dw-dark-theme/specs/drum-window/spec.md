## ADDED Requirements

### Requirement: Drum Window Dark Theme Styling
The Drum Window SHALL render a translucent dark background box with light-gray default text to provide high contrast separation from the underlying video and to optimize color contrast for Anki highlighting.

#### Scenario: Rendering Standard Context
- **WHEN** the user opens the Drum Window
- **THEN** the panel renders with a translucent dark background, with non-active textual context displayed in a dimmer grey.

#### Scenario: Applying Interactive Highlights
- **WHEN** the user hovers over text or views highlighted Anki terms in the Drum Window
- **THEN** the system applies vibrant neon and warm orange overlays (Cyan/Orange/Gold) which maintain accessible contrast against the translucent dark canvas.
