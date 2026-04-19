## MODIFIED Requirements

### Requirement: Split-Phrase Temporal Tolerance
The identification engine must support split-term matching across subtitle segments with a temporal gap of at least 10 seconds.

#### Scenario: Multi-Subtitle Elliptical Wrap
- **WHEN** A split-term card (e.g., "Hören ... sind") spans across three separate subtitle lines.
- **THEN** Both constituents MUST be highlighted with the split-term (purple) color if the total gap is under 12s.

### Requirement: Index-Independent Fallback grounding
The highlight engine must prioritize correct coordinate grounding when an index is present, but fall back to the most likely occurrence (shortest span) if the index doesn't match a candidate in the local context.

#### Scenario: Inaccurate TSV Index
- **WHEN** A TSV record has an incorrect `SentenceSourceIndex` but the words are found in the local context.
- **THEN** The words SHOULD still be highlighted using the "Best Effort" shortest-span match.
