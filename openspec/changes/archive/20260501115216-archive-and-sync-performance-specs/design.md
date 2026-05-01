## Context

The repository has recently undergone a series of rapid performance optimizations and cache hardening audits across five distinct OpenSpec changes. While the code is synchronized, the specifications for these improvements are currently scattered across individual change directories. This project aims to centralize these specifications and archive the completed changes.

## Goals / Non-Goals

**Goals:**
- Consolidate specifications for O(1) character scanning, IPairs iteration, and cache invalidation strategies into the main `openspec/specs` directory.
- Formally archive the five performance-related changes.
- Ensure the `openspec/specs` catalog accurately reflects the current "hardened" state of the `lls_core.lua` rendering pipeline.

**Non-Goals:**
- Implementing new code changes (the goal is architectural synchronization).
- Modifying behavior that was intentionally excluded during the performance audit.

## Decisions

- **Direct Synchronization**: Use `openspec archive --sync` for each change to automate the transfer of delta specifications into the main catalog.
- **Conflict Resolution**: If a change's spec conflicts with a main spec, the "hardened" version from the performance audit takes precedence, as it reflects the most recent validated state.
- **Verification**: Post-synchronization, a full audit of `openspec/specs` will be performed to ensure consistency and completeness.

## Risks / Trade-offs

- **Spec Redundancy**: Some changes might have overlapping or redundant spec updates (e.g., both 105900 and 111725 touch cache hardening). The `archive --sync` process will be monitored to ensure clean merging.
- **Historical Accuracy**: Archiving these changes will move them to `openspec/changes/archive`, which is correct for completed work but requires the ZIDs to be correctly correlated with git history for future audits.
