## ADDED Requirements

### Requirement: Opaque Highlight Outlines
All interactive highlights (manual selections) SHALL use opaque border (`\3a&H00&`) and shadow (`\4a&H00&`) alphas to eliminate visual blooming, regardless of the global background transparency setting.

#### Scenario: Rendering yellow selection
- **WHEN** a word is manually selected in any mode (SRT, Drum, DW, Tooltip)
- **THEN** the rendered token SHALL have a sharp black outline with 0% transparency.

### Requirement: Regular Weight for Manual Selections
Manual selection highlights SHALL always be rendered with regular font weight (`{\b0}`) to maintain a "Premium" aesthetic, decoupling them from the bold weight used for database matches.

#### Scenario: Selecting a word in an active line
- **WHEN** a word is selected within a bolded active playback line
- **THEN** the selection highlight SHALL be regular weight, while the rest of the line remains bold.
