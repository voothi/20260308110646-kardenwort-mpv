## MODIFIED Requirements

### Requirement: Tri-Palette System
The rendering engine SHALL utilize three distinct color palettes, each with three levels of depth (intensity), to indicate match complexity. **The intensity levels SHALL be calibrated to maintain high visual contrast between palettes even at the highest depth (Level 3).**

#### Scenario: Palette Assignment
- **WHEN** the engine identifies a database match
- **THEN** it SHALL assign Orange for contiguous, Purple for split, or Brick for intersection according to the match type.

- **Palette 1: Contiguous (Orange)**: Used for exact word sequence matches found in the user's database. **Level 3 (High Intensity) MUST be rendered in a rich, warm dark orange (e.g., #003C88) to distinguish from Brick.**
- **Palette 2: Split (Purple)**: Used for multi-word terms where constituent words are present in the same context but arranged non-contiguously.
- **Palette 3: Brick Color (Intersection)**: Used when a single word is simultaneously a member of at least one Contiguous term and at least one Split term. **Level 3 (High Intensity) MUST be rendered in a deep, pure red/brick (e.g., #151578) to distinguish from Orange.**

### Requirement: Interaction and Selection Priority
Manual user selections SHALL always carry higher visual priority than automated database highlights.

- **Primary Priority**: Multi-word persistent selections (e.g., Ctrl + LMB). Rendered in **Neon Pink**.
- **Secondary Priority**: Transient cursor-based hover / focus range. Rendered in **Gold**.
- **Tertiary Priority**: Vocabulary database highlights (Orange/Purple/Brick Color).

#### Scenario: Selection vs. Hover
- **GIVEN** a word is currently part of a persistent multi-word selection (Neon Pink).
- **WHEN** the user hovers the cursor over that word.
- **THEN** the word SHALL remain Neon Pink.

#### Scenario: Selection vs. Automated Highlight
- **GIVEN** a word is a saved vocabulary term (e.g., Orange).
- **WHEN** the user includes it in a manual persistent selection.
- **THEN** the selection color (Neon Pink) SHALL override the automated highlight.

#### Scenario: Focus Overwhelming Database Highlight
- **GIVEN** a word is rendered in the Orange or Purple palette due to a database match.
- **WHEN** the user hovers the cursor over that word (Transient Focus).
- **THEN** the word SHALL immediately transition to **Gold**.
- **AND** the automated highlight SHALL be restored when the cursor moves away.

#### Scenario: Selection Range Overwhelming Database Highlight
- **GIVEN** a range of words includes automated Orange highlights.
- **WHEN** the user defines a selection range (LMB Drag) covering those words.
- **THEN** all words within the range SHALL transition to **Gold**.
- **AND** the automated highlights SHALL be unmasked only when the selection range is cleared or moved.

### Requirement: Split-Pair Selection (Ctrl+LMB)
The system SHALL support manual selection of non-contiguous word pairs. **This selection SHALL utilize a "Neon Pink" theme to indicate the cool-path (split match) intent.**

#### Scenario: Split-Pair Selection (Ctrl + LMB)
- **WHEN** a user holds Ctrl and clicks words.
- **THEN** they SHALL be highlighted in **Neon Pink** (Split candidates).
- **AND** these selections SHALL carry higher visual priority than automated highlights but lower than the Gold Focus point.
- **AND** if a word already has Gold focus, the Pink color MUST visually overlap/indicator the "paired" state.
- **AND** if the user clicks a Pink word with Ctrl again (Deselection), the engine MUST **unmask and restore** the word's precise underlying state (e.g., reverting to its database color, active white, or drag yellow).
- **AND** if two *adjacent* words are saved via this mode, the engine SHALL automatically transition them to **Orange** palette rendering (Adjacent-Split Fallback).
