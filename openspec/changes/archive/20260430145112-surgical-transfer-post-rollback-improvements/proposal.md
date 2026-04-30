## Why

After commit `20260429210156`, a series of 27 commits (branch `20260429211359`) attempted to unify the global highlighting engine and fix bracket/punctuation coloring across Drum Mode C and Window W. The changes were too invasive — they restructured the `draw_drum` / `draw_dw` rendering pipelines, FSM state transitions, and `calculate_highlight_stack` logic — causing a cascading regression that ultimately broke Drum Mode C entirely (FSM wouldn't activate, hit-zones drifted, click-to-word stopped working). The user rolled back to commit `131f530` (`20260429210156`).

However, that failed branch produced valuable specification artifacts, test cases, and identified genuine defects that need to be addressed. Two open change projects (`20260429185737-rework-string-preparation-for-export` and `20260429195210-unify-subtitle-export-and-keyboard-granularity`) also remain un-implemented. This proposal consolidates ALL pending improvements into a single, phased, minimally-invasive transfer plan — preserving every working mechanism in the stable codebase while surgically grafting only the validated improvements.

## What Changes

### Phase A — Specification & Documentation Transfer (Zero Code Changes)
- Adopt the `global-semantic-coloring` specification (punctuation color propagation across subtitle boundaries).
- Adopt the `keyboard-selection-granularity` specification (Shift+Arrow token-level navigation).
- Adopt the `performance-hardening` specification (word-map indexing, rendering caches).
- Update `anki-highlighting` spec with the Character-Offset Precision Anchoring requirement from the failed branch.
- Sync `unified-drum-rendering` spec to document the rendering stack rules that prevented the regression.

### Phase B — Export Engine Unification (Isolated, Non-Rendering Code)
- Implement `prepare_export_text` unified service (from `20260429185737`).
- Refactor `clean_anki_term` to preserve user-selected punctuation (from `20260429185737`).
- Integrate token-lookbehind for Pink/Set adjacent member fidelity (from `20260429195210`).
- Centralize terminal punctuation restoration across Yellow and Pink paths.
- Wire all export call sites (`cmd_dw_copy`, `cmd_copy_sub`, `dw_anki_export_selection`, `ctrl_commit_set`) to the unified engine.

### Phase C — Keyboard Granularity (Isolated Navigation Code)
- Implement Shift-aware token-level movement in `cmd_dw_word_move`.
- Add fractional logical index support in `dw_compute_word_center_x` using epsilon-aware comparison.
- Update `draw_dw` selection rendering for fractional indices.

### Phase D — Semantic Punctuation Coloring (Rendering Code — Guarded)
- Implement the global semantic color flow engine as a **post-processing pass** on the existing highlight stack — NOT by restructuring the stack itself.
- Propagate highlight colors to adjacent punctuation tokens using a read-only scan of the finalized color array.
- Treat ASS line-break sequences (`\N`, `\h`) as atomic tokens in the propagation scan.
- **Constraint**: This phase MUST NOT modify `calculate_highlight_stack`, `draw_drum` structure, or FSM state machine logic.

### Phase E — Performance Caching (Rendering Code — Guarded)
- Implement `FSM.ANKI_WORD_MAP` for O(1) highlight lookups during rendering.
- Implement two-tier rendering cache (`DRUM_LAYOUT_CACHE`, `DRUM_DRAW_CACHE`).
- Add cache invalidation triggers on highlight database updates.
- **Constraint**: This phase MUST NOT alter the visual output — purely performance-transparent.

## Capabilities

### New Capabilities
- `global-semantic-coloring`: Ensures consistent highlight propagation for punctuation and symbols across subtitle boundaries and line wraps.
- `keyboard-selection-granularity`: Enables precise token-level cursor movement and selection using Shift+Arrow keys in the Drum Window.
- `performance-hardening`: Implements word-map indexing and hierarchical rendering caching for O(1) highlight lookups.

### Modified Capabilities
- `anki-export-mapping`: Unified `prepare_export_text` service replaces fragmented export paths; punctuation preservation; adjacent member fidelity for Pink selections.
- `anki-highlighting`: Character-Offset Precision Anchoring requirement added for non-contiguous fragment capture.
- `unified-drum-rendering`: Rendering stack rules hardened; semantic punctuation post-processing pass defined.

## Impact

- **Affected Files**: `scripts/lls_core.lua` (primary), `mpv.conf` (new options).
- **Systems**: Anki Export (TSV), Clipboard Copy, Drum Window UI, Drum Mode C rendering, OSD highlight pipeline.
- **Dependencies**: No external dependencies. All changes are internal to `lls_core.lua`.
- **Risk Mitigation**: Phased delivery with Phase A (specs-only) and Phase B (isolated non-rendering code) carrying zero regression risk. Phases D and E are rendering-adjacent but constrained to post-processing passes that do not restructure the core rendering pipeline or FSM logic.
