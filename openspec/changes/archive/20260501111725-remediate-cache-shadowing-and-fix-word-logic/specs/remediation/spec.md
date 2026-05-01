## ADDED Requirements

### Requirement: Module-Scope Cache Invariants
The `flush_rendering_caches` function MUST have write access to the actual table instances used by `draw_drum` and `draw_dw`.

#### Scenario: Live Configuration Refresh
- **WHEN** the user modifies a script option (e.g., font size) via `script-opts`
- **THEN** `flush_rendering_caches` must successfully increment the version and reset sentinels in the *live* cache tables, forcing an immediate OSD redraw.

### Requirement: Unified Optimized Word Logic
The script MUST use a single, O(1) optimized `is_word_char` implementation across all functions to maintain performance parity between subtitle loading and interactive navigation.

#### Scenario: Consistent Tokenization
- **WHEN** a user navigates between words in the Drum Window
- **THEN** the character lookup must use the `WORD_CHAR_MAP` to ensure O(1) efficiency and consistency with the initial subtitle loading phase.
