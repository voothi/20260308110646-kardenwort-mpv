## Why

The project has a backlog of legacy release changes that need to be systematically integrated into the OpenSpec framework. This change initiates "Stage 2" of the RFC migration process, following the completed `20260422081955-migrate-rfcs`, to ensure all historical releases are properly documented, validated, and synchronized with the final project specifications.

## What Changes

- **Three-Way Synchronization**: Aligning legacy specifications (from the change directory), current master specifications (`openspec/specs/`), and the current live codebase.
- **Cross-Release Audit**: Comparing the current release's specifications with all other releases in the Stage 2 list to account for future evolutions and avoid redundant edits.
- **Code Stability Guarantee**: Ensuring that the current working version of the code is never broken during the synchronization and migration process.
- **Manual Validation Workflow**: Parsing and issuing suggestions for each release before applying code changes to allow for manual inspection and verification against the live code.

## Capabilities

### New Capabilities
<!-- No new functional capabilities, this is a documentation and synchronization process -->

### Modified Capabilities
- `rfc-migration-checklist`: Updated to incorporate the Stage 2 release list and the manual validation/synchronization workflow requirements.

## Impact

- **OpenSpec Archival**: Completes the historical record for 28 legacy releases.
- **Spec Integrity**: Improves the accuracy of `openspec/specs/` by merging historical deltas and aligning them with the actual codebase.
- **System Stability**: Rigorous manual validation ensures that the functional codebase remains intact while documentation catches up.
- **Auditability**: Provides a clear three-way trace (Legacy Spec <-> Current Spec <-> Live Code) for all releases.
