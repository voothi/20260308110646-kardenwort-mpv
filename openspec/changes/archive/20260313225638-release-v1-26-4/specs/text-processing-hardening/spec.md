## ADDED Requirements

### Requirement: Top-Level Utility Initialization
Core text utilities SHALL be defined at the top of the script to ensure they are fully initialized and in-scope for all parsing functions.

### Requirement: Defense-in-Depth Nil Guards
All base text processing functions SHALL include internal nil-guards to safely handle empty or malformed input strings.

#### Scenario: Processing empty subtitle
- **WHEN** a text utility receives an empty or nil string
- **THEN** it SHALL return a safe fallback value (e.g., `false` or empty list) rather than throwing a runtime error.
