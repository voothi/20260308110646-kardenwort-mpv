# search-ui-styling Specification

## Purpose
TBD - created by archiving change 20260428015150-refine-search-ui-styling. Update Purpose after archive.
## Requirements
### Requirement: Search Window Layout Restoration
The search window SHALL use the positioning and sizing constants defined in version `0befa9923cae21c33f43c69875de438c9101cf66`. This includes a centered input box and a fixed-width dropdown menu for results.

#### Scenario: Layout Verification
- **WHEN** the search window is opened with `Ctrl+F`
- **THEN** the UI is rendered using the classic layout with `box_w = 1200` and `box_x = 960 - (box_w / 2)`

### Requirement: Independent Search Results Scaling
The system SHALL provide a configuration option `search_results_font_size` to scale the font of the dropdown results independently from the main search bar.
- If set to `0`, the size SHALL be 100% of the search bar.
- If set to `-1`, the size SHALL be 80% (legacy behavior).
- If set to a positive value, it SHALL be used as the fixed pixel size.

#### Scenario: Adjusting Dropdown Font Size
- **WHEN** `search_results_font_size` is set to `-1` in `mpv.conf`
- **THEN** the search results dropdown is rendered at 80% of the search bar's font size

### Requirement: High-Contrast Active Selection
The active search result SHALL be rendered in bright white (`FFFFFF`) to clearly distinguish it from surrounding context results, which SHALL be rendered in a dimmer grey (`search_text_color`, default `CCCCCC`).

#### Scenario: Active Selection Contrast
- **WHEN** navigating through search results
- **THEN** the currently selected line is rendered in pure white, while unselected lines remain grey

### Requirement: Selection Highlight Visibility
The active selection SHALL maintain visibility of colored match highlights (as defined by `search_hit_color` or `search_query_hit_color`) within the white base text.

#### Scenario: Colored Hits in Selected Line
- **WHEN** a search query matches multiple words in the selected result
- **THEN** those words are rendered in the configured hit color while the rest of the line remains white

### Requirement: Dynamic Vertical Adaptation to Wrapped Content
The search interface SHALL dynamically adjust the height of its background elements and the vertical positioning of its components to accommodate wrapped text content in both the search input field and the results dropdown items.

#### Scenario: Multi-line Search Input
- **WHEN** a search query is long enough to wrap onto multiple visual lines within the 1200px box width
- **THEN** the search input field's background box SHALL expand vertically to contain all visual lines, and the results dropdown SHALL shift downwards to prevent overlap.

#### Scenario: Multi-line Search Results
- **WHEN** a search result item wraps onto multiple visual lines
- **THEN** the results dropdown background SHALL expand to accommodate the additional lines, and subsequent items in the list SHALL be correctly offset to prevent vertical overlap.

### Requirement: Context-Aware Result Framing (Scrolling)
The search results dropdown SHALL maintain a centered visual "frame" around the selected item to provide consistent visual context. The system SHALL dynamically shift the results viewport to keep the selected index in the vertical center of the visible list whenever possible.

#### Scenario: Centered Result Navigation
- **WHEN** more than 8 results are available and the user navigates through them
- **THEN** the system SHALL display a sliding window of 8 results where the selected result is centered (e.g., if index 10 is selected, the window shows results 6 through 13).

