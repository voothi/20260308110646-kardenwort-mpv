## ADDED Requirements

### Requirement: Semantic Punctuation Post-Processing Integration Point
The `draw_drum` and `draw_dw` rendering functions SHALL call the semantic punctuation coloring engine as a post-processing step AFTER `calculate_highlight_stack` returns the color array and BEFORE the ASS string is assembled. This integration point SHALL be the ONLY location where semantic coloring is applied.

#### Scenario: Post-processing in Drum Mode C
- **WHEN** `draw_drum` computes the highlight stack for a subtitle line
- **THEN** it SHALL pass the resulting color array to `apply_semantic_punctuation_colors` before constructing the ASS tag string.
- **AND** the `calculate_highlight_stack` function SHALL remain unmodified.

#### Scenario: Post-processing in Window Mode W
- **WHEN** `draw_dw` computes the highlight stack for a subtitle line
- **THEN** it SHALL pass the resulting color array to `apply_semantic_punctuation_colors` before constructing the ASS tag string.
- **AND** the rendering output SHALL be visually identical to Drum Mode C for the same subtitle content and highlight state.

### Requirement: Rendering Pipeline Immutability Guard
The following functions SHALL NOT be modified as part of this change:
- `calculate_highlight_stack` (depth counting, intersection logic)
- FSM state transition handlers (`toggle_drum_mode`, `toggle_drum_window`, etc.)
- Hit-zone geometry calculations (`FSM.DRUM_HIT_ZONES` population)
- `calculate_osd_line_meta` (line dimension computation)

#### Scenario: FSM activation preserved
- **WHEN** the user presses the drum mode toggle key (default: `c`)
- **THEN** the FSM SHALL transition to the Drum Mode state identically to the behavior at commit `131f530` (`20260429210156`).
- **AND** all hit-zones SHALL align with the rendered text positions.
