## REMOVED Requirements

### Requirement: Global Semantic Color Flow
**Reason**: This feature causes highlight "bleeding" where colors propagate to adjacent punctuation symbols that were not explicitly selected by the user. This creates ambiguity between the visual UI and the actual exported data.
**Migration**: Highlight colors SHALL strictly apply only to the selected tokens and database-matched terms. No color inheritance for adjacent non-selected tokens.

### Requirement: Atomic Line-Break Tokenization
**Reason**: Replaced by simpler token-based filtering in the navigation logic.
**Migration**: Line breaks remain as tokens but are filtered out by navigation landing logic rather than being handled by a complex semantic propagation engine.
