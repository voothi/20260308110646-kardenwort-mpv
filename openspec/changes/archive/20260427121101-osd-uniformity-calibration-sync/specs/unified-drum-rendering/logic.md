# Specification: Unified Drum Rendering Logic

## Context Synchronization
The "Drum" style (highlighting an active line with surrounding context) is shared between **Drum Mode (C)** and the **Drum Window (W)**.

### Rendering Components
1.  **Metadata Generation**: `calculate_osd_line_meta` must be used to pre-calculate the dimensions of every subtitle line to ensure hit-testing accuracy.
2.  **Highlighting Stack**: The `calculate_highlight_stack` and `format_highlighted_word` utilities must be used to ensure that word-level highlighting (Selections, Database hits) looks identical regardless of the overlay type.
3.  **Active Line Consistency**: Seek and navigation operations must always anchor the visual "Active Line" (White) to the current playback position or cursor position, maintaining a stable focal point.
