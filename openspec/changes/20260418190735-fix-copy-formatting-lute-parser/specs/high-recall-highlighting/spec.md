## ADDED Requirements

### Requirement: High-Fidelity Range Reconstruction
The reconstruction engine (Copy/Anki Export) MUST preserve the exact character sequence, including internal punctuation and original whitespace tokens, when a range of contiguous words is selected from a subtitle segment.
- This ensures that selections accurately reflect the source media's punctuation and formatting.
- This requirement supersedes simple word-joining heuristics that only join words with single spaces.

#### Scenario: Copying a phrase with internal punctuation
- **WHEN** the user selects a range of words in the Drum Window
- **AND** the source segment contains "Hören, ob" within that range
- **THEN** the reconstructed text SHALL contain "Hören, ob" (comma and space preserved)

#### Scenario: Multi-word selection across segments
- **WHEN** the user selects a range spanning Subtitle 1 and Subtitle 2
- **THEN** each segment SHALL be reconstructed with high fidelity
- **AND** the segments SHALL be joined by a single space in the final output
