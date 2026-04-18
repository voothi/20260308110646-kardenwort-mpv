## ADDED Requirements

### Requirement: Manual Selection Precedence
To ensure responsive and predictable interaction, manual user selections (Transient Focus, Drag Selection, and Persistent Selection) MUST always override automated database-driven highlights in the Drum Window.

#### Scenario: Focus Overwhelming Database Highlight
- **GIVEN** a word is rendered in the Orange or Purple palette due to a database match.
- **WHEN** the user hovers the cursor over that word (Transient Focus).
- **THEN** the word SHALL immediately transition to **Vibrant Yellow**.
- **AND** the automated highlight SHALL be restored when the cursor moves away.

#### Scenario: Selection Range Overwhelming Database Highlight
- **GIVEN** a range of words includes automated Orange highlights.
- **WHEN** the user defines a selection range (LMB Drag) covering those words.
- **THEN** all words within the range SHALL transition to **Vibrant Yellow**.
- **AND** the automated highlights SHALL be unmasked only when the selection range is cleared or moved.

#### Scenario: Persistent Selection vs. Automated Highlight
- **GIVEN** a word is an automated Orange highlight.
- **WHEN** the word is included in a persistent Multi-Word Selection (Ctrl + LMB).
- **THEN** the selection color (**Pale Yellow**) SHALL be rendered, completely masking the automated highlight.
