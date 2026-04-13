## MODIFIED Requirements

### Requirement: Sentence-Aware Context Extraction
The context extraction algorithm SHALL prioritize isolating complete sentences within the sliding subtitle window before applying any word-limit truncation. **The algorithm MUST identify sentence boundaries (punctuation) relative to the END of the selected term to ensure multi-sentence selections are fully encompassed.**

#### Scenario: Capturing context for multi-sentence terms
- **WHEN** a term containing punctuation (e.g., "Umbruch. Während") is exported
- **THEN** the system searches for the preceding punctuation starting from the term's start, and the following punctuation starting from the term's end, ensuring both sentences are included in the result.
