## ADDED Requirements

### Requirement: Compile-Safe Text Utility Introduction
Text-normalization utility additions to the primary Lua script MUST preserve startup compile viability under Lua chunk-local limits.

#### Scenario: Startup after text utility changes
- **WHEN** the script initializes after introducing or modifying text-normalization helpers
- **THEN** initialization SHALL complete without compile-time local-scope overflow errors
- **AND** the runtime log SHALL NOT report `main function has more than 200 local variables`.
