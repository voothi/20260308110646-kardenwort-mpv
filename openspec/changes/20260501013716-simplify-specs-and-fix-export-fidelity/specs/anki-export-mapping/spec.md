## MODIFIED Requirements

### Requirement: Unified High-Fidelity Export Joining (Req 112)
**UPDATED**: Export paths SHALL use the original subtitle spacing and punctuation. The system SHALL NOT perform any whitespace normalization (e.g., collapsing multiple spaces).

### Requirement: Selection Punctuation Preservation (Req 124)
**UPDATED**: Export logic SHALL NOT perform any automatic filtering, stripping, or cleaning of leading/trailing symbols, including balanced brackets. Metadata stripping is restricted strictly to ASS tags `{...}` when `options.clean` is explicitly requested.
