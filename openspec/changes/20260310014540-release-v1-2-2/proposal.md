## Why

This change formalizes the Context Copy FSM Array Symmetry Fix introduced in Release v1.2.2. After the v1.2.0 FSM migration, inaccuracies were reported in dialogue extraction from dual-track `.ass` files. The previous strict-radius logic failed to handle interleaved tracks correctly, leading to missing sentences and asymmetrical context harvests.

## What Changes

- Restoration of **Dynamic Traversal Loops** in `scripts/lls_core.lua` to ensure the sentence quota is met by skipping filtered foreign-language tracks.
- Implementation of **Target Language Index Snapping** for `get_center_index` to prevent the algorithm from pivoting on filtered foreign-language blocks.
- Restoration of the `is_context` clipboard pipeline shortcut to reduce redundant parsing overhead during extraction.

## Capabilities

### New Capabilities
- `context-copy-fsm-repair`: Algorithmic fixes for symmetrical and chronological context extraction from interleaved dual-track subtitle files.

### Modified Capabilities
- None (Incremental fix).

## Impact

- **Accuracy**: Guaranteed 1:1 matching between requested context lines and extracted native-language sentences.
- **Performance**: Improved clipboard processing efficiency via the `is_context` optimization.
- **Reliability**: Eliminates the "missing sentence" regression reported in dual-track ASS environments.
