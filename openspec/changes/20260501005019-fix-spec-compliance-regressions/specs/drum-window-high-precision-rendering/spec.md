## REMOVED Requirements

### Requirement: Global Stream-Based Punctuation Rendering
**Reason**: To reduce architectural complexity and focus on word-level language acquisition, the requirement to propagate highlights to punctuation tokens is removed.
**Migration**: Punctuation will remain uncolored (base context color) unless it is part of a contiguous phrase highlight.

### Requirement: Disciplined Punctuation Stacks
**Reason**: Obsolete following the removal of punctuation highlighting.
