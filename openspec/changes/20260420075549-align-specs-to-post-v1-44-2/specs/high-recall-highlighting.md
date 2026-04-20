## ADDED Requirements

### Requirement: Generous Inter-Segment Bridging
The temporal gap tolerance for joining adjacent subtitle segments into a single phrase match SHALL be expanded to support slow media speech.
- **Tolerance**: **10.0 seconds**.
- **Behavior**: If the gap between sequential match components is <= 10s, they SHALL be rendered as a unified phrase.

### Requirement: Precision Neighborhood Verification (Token Intersection)
When Global Highlighting is active, the engine SHALL verify the contextual "neighbor" tokens to prevent spurious matches on common words.
- **Anchor Requirement**: A highlight is ONLY rendered if at least one meaningful word (length >= 2, stripped of punctuation) from the neighboring +/- 5 segments exists in the record's stored context.

### Requirement: Deep Segment Peeking & Adaptive Window
- **Peeking**: The engine SHALL scan up to 5 adjacent segments to verify long phrase continuity.
- **Adaptive Window**: The fuzzy matching window SHALL grow by +0.5s for every word beyond the 10th word in a saved term to accommodate long paragraph segments.
