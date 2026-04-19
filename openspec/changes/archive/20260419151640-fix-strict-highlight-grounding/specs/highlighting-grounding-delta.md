## MODIFIED Requirements

### Requirement: Multi-Pivot Grounding & Resiliency (Refinement)
The identifies engine MUST anchor mining records using a multi-pivot coordinate system. 

#### Scenario: Strict Grounding Enforcement
- **WHEN** a record contains a valid index anchor
- **AND** `anki_global_highlight` is disabled
- **THEN** the engine MUST bypass any fuzzy context fallbacks if the strict index check fails.
- **AND** it MUST NOT highlight alternative instances of the same word in the same segment.
