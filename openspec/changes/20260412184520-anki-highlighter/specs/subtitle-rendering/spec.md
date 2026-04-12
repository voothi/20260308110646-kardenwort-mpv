## ADDED Requirements

### Requirement: Compound Intensity Rendering
The subtitle OSD formatting engine SHALL parse all active TSV highlight objects for the current context and apply depth-stacking BGR colors to the rendered words. 

#### Scenario: Rendering an overlapping highlight
- **WHEN** a subtitle sentence contains two highlighted words, but one of those words is also part of a larger, surrounding highlight quote
- **THEN** that specific word receives a darker/different configurable color tag (`lls-anki_highlight_depth_2`) compared to the un-overlapped highlighted word (`lls-anki_highlight_depth_1`).
