# window-highlighting-spec

## Purpose
This specification provides a formal, exhaustive description of word highlighting behaviors within the "Window Mode" (Drum Window) of Kardenwort-mpv. It serves as a strict directive for the rendering engine to ensure consistent visual feedback during language study. This document represents the canonical source of truth for the High-Recall Highlighter as implemented in `lls_core.lua`.

## Requirements

### Requirement: Tri-Palette System
The rendering engine SHALL utilize three distinct color palettes, each with three levels of depth (intensity), specifically for SRT subtitle rendering in the Drum Window.

- **Palette 1: Contiguous (Standard)**: Used for exact string matches found in the user's database. Defined by `anki_depth_1`, `anki_depth_2`, `anki_depth_3`. Default hues: Orange.
- **Palette 2: Split (Non-Contiguous)**: Used for multi-word terms where constituent words are present in the same context but arranged non-contiguously. Defined by `anki_split_depth_1`, `anki_split_depth_2`, `anki_split_depth_3`. Default hues: Purple.
- **Palette 3: Brick Color (Intersection)**: Used when a single word is simultaneously a member of at least one Contiguous (Orange) term and at least one Split (Purple) term. Defined by `anki_mix_depth_1`, `anki_mix_depth_2`, `anki_mix_depth_3`. This represents a logical intersection.

### Requirement: Interaction and Selection Priority
The rendering engine SHALL resolve overlaps between manual user selections and automated highlighting according to a strict priority hierarchy.

- **Primary Priority**: Multi-word persistent selections (Ctrl + LMB). Rendered in **Pale Yellow** (`dw_ctrl_select_color`).
- **Secondary Priority**: Vocabulary database highlights (Anki Orange/Purple/Mixed).
- **Tertiary Priority**: Transient cursor-based hover highlighting. Rendered in **Vibrant Yellow** (`dw_highlight_color`).

#### Scenario: Selection vs. Hover
- **GIVEN** a word is currently part of a persistent multi-word selection (Pale Yellow)
- **WHEN** the user hovers the mouse cursor over that word
- **THEN** the word SHALL remain Pale Yellow to preserve the selection's visual integrity.

#### Scenario: Selection vs. Anki Highlight
- **GIVEN** a word is a saved Anki term (e.g., Orange)
- **WHEN** the user includes this word in a manual Ctrl+Selection (Pale Yellow)
- **THEN** the Pale Yellow SHALL override the Orange highlight.

### Requirement: Depth Calculation and Selection
The Intensity Level (1, 2, or 3) for any word SHALL be determined by its "stack depth" – the number of unique overlapping terms assigned to that word.

#### Scenario: Determining pure palette level
- **WHEN** a word is matched by 2 Contiguous terms and 0 Split terms
- **THEN** it SHALL be rendered using `anki_depth_2`.

#### Scenario: Determining mixed palette level
- **WHEN** a word is matched by $O$ Contiguous terms AND $S$ Split terms (where $O > 0$ and $S > 0$)
- **THEN** the index $L$ SHALL be calculated as $L = \text{clamp}(O + S, 1, 3)$
- **AND** the word SHALL be rendered using `anki_mix_depth_L`.

#### Scenario: Brick Color Identification (Orange + Purple)
- **WHEN** the highlighting engine calculates the status of a specific word token
- **AND** the token is identified as part of an active Contiguous phrase (Orange matching pass)
- **AND** the token is simultaneously identified as part of an active Split phrase (Purple matching pass)
- **THEN** it SHALL be designated as a "Brick Color" intersection match.
- **AND** the total intensity SHALL be the clamped sum of both types of matches, selecting from the `anki_mix_depth_X` palette.
- **AND** this Brick Color (Violet/Brown-Red) SHALL carry absolute priority over pure Orange or pure Purple rendering for that token.

### Requirement: Semantic Punctuation Coloring
The engine SHALL dynamically determine whether trailing or internal punctuation is colored based on the nature of the match.

#### Scenario: Single-word isolation
- **GIVEN** a word is only matched as a single-word term (e.g., "Haus" in "das Haus.")
- **THEN** the punctuation (the period) SHALL NOT be highlighted, maintaining a clean dictionary-style interface.

#### Scenario: Phrase continuity
- **GIVEN** a word is part of a multi-word phrase match (e.g., "Haus" in "im Haus.")
- **THEN** all internal and trailing punctuation within the phrase span SHALL inherit the highlight color to ensure visual blocks are contiguous.

#### Scenario: Phrase priority in mixed states
- **GIVEN** a word belongs to an intersection where one match is a single-word and another is a phrase
- **THEN** the Phrase Continuity logic SHALL take precedence, and punctuation SHALL be colored.

### Requirement: High-Recall Sequence Verification
To prevent false-positive coloration (bleed) of common words (e.g., "der", "die", "und"), the engine MUST verify the local neighborhood of any potential match.

#### Scenario: Neighborhood check
- **WHEN** evaluating a match candidate in Global Mode
- **THEN** the engine MUST verify that at least one neighboring word (within a ±3 word window) matches the original recorded context from the database.
- **AND** symbol-only tokens (dashes, slashes, brackets) SHALL be skipped/ignored during this check.

### Requirement: Inter-Segment Continuity
Highlighting SHALL persist across subtitle segment boundaries if strict temporal and sequential constraints are met.

#### Scenario: Bridging segments
- **WHEN** a multi-word term is split between Subtitle A and Subtitle B
- **AND** the gap between Subtitle A's end and Subtitle B's start is ≤ 1.5 seconds
- **THEN** the engine SHALL highlight the respective parts in both segments.
- **AND** the engine SHALL recursively check up to 5 adjacent segments to find the full term.

### Requirement: Window Mode Visual Modifiers
Window Mode rendering SHALL support additional visual emphasized states.

#### Scenario: Bold highlighting
- **WHEN** `anki_highlight_bold` is enabled
- **THEN** all highlighted spans in the Drum Window SHALL be wrapped in ASS bold tags `{\b1}` and `{\b0}`.

#### Scenario: Compound Word Partial Highlighting
- **WHEN** a subtitle word contains separators like slashes, hyphens, or dashes (e.g., "Netto/Globus" or "20–25")
- **AND** a saved term matches only one constituent part (e.g., "Netto")
- **THEN** the engine SHALL successfully identify the match.
- **AND** it SHALL highlight strictly that word token while treating the separator and other parts as distinct for logic purposes.

### Requirement: Long-Term Adaptive Fuzzy Window
To accommodate long paragraphs that may take significant time to read, the temporal fuzzy window SHALL grow dynamically.

#### Scenario: Long paragraph temporal growth
- **GIVEN** a saved term longer than 10 words
- **THEN** the base `anki_local_fuzzy_window` (typically 1s) SHALL be extended by **0.5 seconds** for every word in the term.
- **Example**: A 20-word term gets a $1 + (20 \times 0.5) = 11$ second validity window.

### Requirement: Context Search Radius
For multi-word split (non-contiguous) terms, the engine SHALL scan a widened neighborhood of subtitle segments.

#### Scenario: Subtitle segment scan cluster
- **GIVEN** the engine is evaluating a potential split match
- **THEN** it SHALL scan up to **±15 subtitle segments** (approximately 30 seconds of dialogue) surrounding the current segment to locate all constituent words.

### Requirement: Strict Context Neighbor Verification
When `anki_context_strict` is enabled, matches MUST be anchored by their recorded neighbors to prevent false coloration of common words.

#### Scenario: Symbol-Agnostic Neighbor Detection
- **WHEN** searching for neighbors to verify context
- **THEN** the engine SHALL look past up to **4 consecutive symbols/separators** (punctuation, slashes, brackets) to find the nearest word token.

#### Scenario: Highlighting Exemptions
- **GIVEN** a potential match is a bracketed label (e.g., `[musik]`) or a common unit/adjective (e.g., `ca`, `km`, `cm`, `mm`, `kg`, `m`, `große`, `zb`)
- **THEN** the engine SHALL exempt these tokens from strict neighbor verification to ensure important markers remain highlighted even if their context varies.

### Requirement: Split Term Shortest Span
The engine SHALL strictly control which instances of common words are colored when they form part of a split term.

#### Scenario: Minimizing phrase span
- **WHEN** multiple instances of a term's words exist within the 15-segment scan radius
- **THEN** the engine SHALL calculate the **shortest sequential span** that contains all words in their original order.
- **AND** only the word instances within that optimal shortest span SHALL be highlighted.


### Requirement: ASS Mode Restrictions
The "Window Mode" high-recall highlighting engine is strictly optimized for linear, plain-text subtitle formats (SRT). Advanced ASS styling (Advanced Substation Alpha) is subject to the following formal restrictions:

#### Scenario: ASS Tag Interference
- **GIVEN** a subtitle segment contains internal ASS override tags (e.g., `{\i1}word{\i0}`)
- **THEN** the tokenization engine SHALL treat symbols inside the curly braces as metadata.
- **AND** highlighting MAY fail to apply if the tag splits a multi-word sequence logically.

#### Scenario: Complex Positioning and Draw Commands
- **GIVEN** an ASS segment uses complex positioning (`\pos`, `\move`) or vector drawing commands (`\p1`)
- **THEN** highlighting SHALL be automatically disabled for that segment to prevent visual artifacts and OSD positioning corruption in the Drum Window.

#### Scenario: Pre-colored ASS text
- **GIVEN** an ASS segment has hardcoded colors (e.g., `\c&H0000FF&`)
- **THEN** the high-recall highlighter SHALL prioritize its own palette colors (Orange/Purple/Mixed), which MAY result in a loss of the original subtitle styling.
