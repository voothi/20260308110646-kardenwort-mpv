## MODIFIED Requirements

### Requirement: Highlighting Stack
The `calculate_highlight_stack` and `format_highlighted_word` utilities MUST be used in conjunction with a **Global Semantic Pass** to ensure that word-level highlighting (Selections, Database hits) and associated punctuation look identical regardless of the overlay type (C or W mode).

#### Scenario: Unified Highlighting Flow
- **WHEN** any text is highlighted in either Drum Mode or Drum Window
- **THEN** the same semantic coloring rules SHALL apply, ensuring that brackets and punctuation are colored consistently across all view modes and line breaks.
