# Spec: Spec Compliance Audit

## Context
As a meta-specification, this defines the requirements for the auditing process itself to ensure it is systematic and reliable.

## Requirements

### Requirement: Comprehensive Coverage
The audit must address every folder within `openspec/specs/` that contains a `spec.md` or `delta-*.md` file.

### Requirement: Accurate Mapping
For each requirement identified in the specifications, the audit must pinpoint the specific Lua file or configuration block responsible for its implementation.

### Requirement: Actionable Reporting
The final report must categorize each requirement as:
- **COMPLIANT**: Code matches requirement.
- **NON-COMPLIANT**: Code explicitly violates requirement.
- **MISSING**: Requirement is not implemented in the current codebase.
- **OBSOLETE**: Requirement applies to a feature or system that has been removed.

## Verification

### Automated Verification
- Check for the existence of the `compliance_report.md` artifact.
- Ensure all specs listed in `openspec/specs/` are represented in the report.

### Manual Verification
- Spot-check 3 random "COMPLIANT" entries to verify the code mapping is accurate.
