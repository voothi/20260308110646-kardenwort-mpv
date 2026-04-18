# Design: Finalize Drum Window Highlighting Stabilization

## Context
The Drum Window highlighting engine was recently hybridized to restore Lute v3 tokenization while maintaining multi-line selection. While core functionality is restored, the rendering loop still exhibits priority conflicts (e.g., hover color masking persistent selections) and lacks semantic punctuation coloring for phrases.

## Goals / Non-Goals

**Goals:**
- **Deterministic Priority Rendering**: Ensure Persistent Selections (Pale Yellow) always override Database Highlights and Hover states.
- **Phrase-Aware Punctuation Coloring**: Color punctuation tokens that belong to or terminate a highlighted phrase.
- **Robust Multi-Segment Stitching**: Ensure phrases that bridge segments are colored as a single unit without visual gaps or "flicker".
- **Final Palette Compliance**: Ensure the "Brick Color" intersection logic ( = \text{clamp}(O + S - 1, 1, 3)$) is strictly applied.

**Non-Goals:**
- No changes to the Lute v3 parsing engine itself.
- No changes to the Anki TSV file format (staying with the new source_index field).

## Decisions
### 1. Unified Priority Masking in Rendering Loops
We will refactor the internal word formatting loop in draw_dw and draw_drum to use a strict hierarchical if-block for color selection:
1.  **Level 1: Persistent Selection (Ctrl+LMB)**: Checked via FSM.DW_CTRL_PENDING_SET. Color: Options.dw_ctrl_select_color (Pale Yellow).
2.  **Level 2: Automated Database Highlights (Orange/Purple/Brick)**: Calculated via calculate_highlight_stack.
3.  **Level 3: Transient Hover Focus (LMB/MMB)**: Only applied if Level 1 and Level 2 result in the base text color. Color: Options.dw_highlight_color (Vibrant Yellow).

### 2. Phrase-Context Awareness for Punctuation
The rendering loop will be updated to look ahead/behind by 1 token. If a punctuation token (is_word=false) is bounded by tokens that share the same 	erm_key or logical_idx sequence from calculate_highlight_stack, the punctuation will inherit the phrase's color and "phrase" (orange box) styling.

### 3. Absolute Segment Anchoring
For Local matches, the engine will strictly enforce ecord.index == logical_idx verification, ensuring that highlights never bleed across subtitles with identical text but different visual timestamps.

## Risks / Trade-offs
- **Performance**: Look-ahead/behind logic in the rendering loop adds O(N) complexity to the OSD refresh. We will minimize this by only checking punctuation tokens.
- **Visual Density**: Highlighting punctuation in phrases may increase visual "noise" on screen. We will adhere to the spec to ensure phrases look like cohesive units.
