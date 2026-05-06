## 1. Verification & Hardening

- [ ] 1.1 Verify `get_center_index` in `lls_core.lua` follows the `Sentinel -> Binary Search -> Overlap Priority` order exactly.
- [ ] 1.2 Confirm `state-diagram.md` Mermaid syntax is valid and `DR_MODE` typos are eliminated.
- [ ] 1.3 Verify `JUST_JERKED_TO` is correctly applied within the Sentinel check to prevent seek loops.

## 2. Specification Synchronization

- [ ] 2.1 Run `/opsx:archive` to merge these hardened requirements into the global `openspec/specs/fsm-architecture/`.
- [ ] 2.2 Verify that `spec.md` and `state-diagram.md` in the main specs folder now include the new padding resolution rules.
