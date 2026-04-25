## ADDED Requirements

### Requirement: Stage 2 Sequential Processing
The migration process SHALL support a "Stage 2" phase for processing the second batch of 28 legacy releases (v1.2.16 to v1.26.34) sequentially, one at a time.

#### Scenario: Processing releases in order
- **WHEN** the Stage 2 migration is active
- **THEN** changes SHALL be processed in the specific order defined in the Stage 2 task list.

### Requirement: Pre-Implementation Validation Gate
Before modifying any source code for a legacy release migration, the system SHALL parse the legacy documentation and generate a "Suggestion Report" outlining the proposed changes.

#### Scenario: Manual validation of suggestions
- **WHEN** a Suggestion Report is generated
- **THEN** the system SHALL wait for manual user approval/validation before applying code changes.

### Requirement: Three-Way Synchronization
The migration SHALL align three sources of truth for each release: the legacy specification, the current master specification, and the live codebase.

#### Scenario: Comparing specifications and code
- **WHEN** a release change is processed
- **THEN** the system SHALL identify discrepancies between the legacy requirements, current `openspec/specs/`, and the existing implementation.

### Requirement: Cross-Release Specification Audit
The analysis of each release SHALL include a comparison with all other releases in the Stage 2 list to ensure requirement evolution is accounted for and redundant edits are avoided.

#### Scenario: Identifying future overrides
- **WHEN** analyzing a specific legacy release
- **THEN** the system SHALL check if subsequent releases in the list modify or supersede its requirements.

### Requirement: Code Stability Guarantee
The migration process SHALL NOT break the current working version of the code.

#### Scenario: Preventing regressions
- **WHEN** a legacy requirement conflicts with working code behavior
- **THEN** the current code behavior SHALL be preserved unless explicitly overridden by the user.

### Requirement: Specification Synchronization on Archive
During the archival of a completed release change, the system SHALL synchronize all three perspectives into the master records in `openspec/specs/`.

#### Scenario: Finalizing a release migration
- **WHEN** a release change is archived
- **THEN** the master specifications SHALL be updated to accurately reflect the validated "as-built" state.

### Requirement: Conflict Resolution Prompt
The system SHALL proactively check for inconsistencies between legacy release requirements and current specifications in `openspec/specs/`.

#### Scenario: Resolving requirement conflicts
- **WHEN** a conflict is detected between a legacy requirement and an existing spec
- **THEN** the system SHALL halt and prompt the user to resolve the inconsistency manually.
