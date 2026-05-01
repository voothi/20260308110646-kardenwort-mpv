# Proposal: Archive and Synchronize Performance Optimization Specs

## Problem
Several performance optimization and cache hardening projects have been completed in the `openspec/changes` directory:
- `20260501023103-optimize-hot-paths`
- `20260501093901-optimize-speed-and-reliability-hot-paths`
- `20260501100842-fix-cache-integrity-after-audit`
- `20260501105900-harden-rendering-caches-and-fix-dead-code`
- `20260501111725-remediate-cache-shadowing-and-fix-word-logic`

These changes contain valuable architectural specifications (e.g., O(1) character scanning, cache invalidation strategies, rendering performance invariants) that need to be synchronized into the main `openspec/specs` directory to ensure they are preserved and followed in future development. Once synchronized, these changes should be formally archived.

## Proposed Change
This project will:
1. Extract and consolidate all specifications from the five listed performance projects.
2. Synchronize these specifications into the primary `openspec/specs` catalog, ensuring no regressions or conflicts with existing specs.
3. Formally archive the completed changes to maintain a clean workspace.
4. Verify the current version (`db8f24a4fac2e1056680e3fce0ed049a3a2badf1`) against the synchronized specifications.

## Capabilities

### Modified Capabilities
- `rendering-optimization`: Update core specs to include O(1) scanning invariants and IPairs-based iteration requirements.
- `cache-hardening`: Update core specs to include `LAYOUT_VERSION` consistency and `flush_rendering_caches` synchronization requirements.
- `drum-window`: Update specs to include `DRUM_DRAW_CACHE` management and track/mode synchronization invariants.

## Impact

- **Affected Code**: `openspec/specs/*`, `openspec/changes/*` (archival).
- **Correctness**: Ensures that future changes adhere to the hardened cache and rendering logic established in the audit.
- **Performance**: Solidifies the performance gains by making the O(1) lookups and IPairs optimizations part of the permanent specification.
