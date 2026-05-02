## ADDED Requirements

### Requirement: Context-Aware Token Formatting
The `format_highlighted_word` utility SHALL accept and utilize background color and alpha parameters to guarantee absolute visual parity and prevent "lost tags" regressions during surgical injection.

#### Scenario: Rendering highlighted tokens
- **WHEN** a token is processed for highlighting
- **THEN** the formatter SHALL inject explicit `\3c`, `\4c`, `\3a`, and `\4a` tags to lock the aesthetic and restore them to the passed context immediately afterward.
