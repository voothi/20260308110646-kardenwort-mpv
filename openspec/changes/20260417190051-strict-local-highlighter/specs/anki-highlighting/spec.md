## MODIFIED Requirements

### Requirement: Highlight Toggle Keybinding
The application SHALL bind `h` (and `р` for RU layout) to toggle the visual re-rendering scope of the highlights. When toggled OFF (local mode), the temporal window MUST be restricted to prevent highlights from leaking across unrelated subtitles.

#### Scenario: Toggling Global Highlighting
- **WHEN** the user presses `h` to disable global highlighting
- **THEN** the rendering engine SHALL apply a strict temporal window (default 2.0s) to all terms
- **AND** the engine SHALL restrict the inter-segment scan range to ±3 subtitles for multi-word phrases.
