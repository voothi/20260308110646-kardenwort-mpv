## Purpose
Ensure script startup and parser behavior remain robust when introducing low-level runtime and text-processing fixes.
## Requirements
### Requirement: Pre-Binding Function Availability
The system SHALL ensure that all command functions are fully defined within the script's scope before any keybindings are registered to prevent `nil` reference crashes.

#### Scenario: Registering a DW binding
- **WHEN** the script initializes
- **THEN** it SHALL define `cmd_dw_*` functions in the global/top-level scope prior to executing `mp.add_forced_key_binding`.

### Requirement: Accurate ASS Centisecond Parsing
The subtitle parsing system SHALL correctly handle 2-digit centisecond fields in ASS/SSA files by normalizing them to 3-digit milliseconds.

#### Scenario: Parsing an ASS timestamp
- **WHEN** the system encounters a timestamp like `00:00:01.50` (50 centiseconds)
- **THEN** it SHALL parse this as 1500 milliseconds.

### Requirement: Compile-Safe Text Utility Introduction
Text-normalization utility additions to the primary Lua script MUST preserve startup compile viability under Lua chunk-local limits.

#### Scenario: Startup after text utility changes
- **WHEN** the script initializes after introducing or modifying text-normalization helpers
- **THEN** initialization SHALL complete without compile-time local-scope overflow errors
- **AND** the runtime log SHALL NOT report `main function has more than 200 local variables`.

