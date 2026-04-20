## Context

The `calculate_highlight_stack` function in `lls_core.lua` is responsible for evaluating all Anki highlights against the current subtitle tokens. Currently, Phase 3 (Split matching) iterates through a broad temporal and segment window (+/- 35 lines) and builds a `ctx_list` for every multi-word term. This results in redundant tokenization and string cleaning. Additionally, the temporal gap used for contiguous phrase bridging is currently tied to the split-phrase limit (60s), which is overly permissive. Local Mode index grounding is also "all or nothing," leading to highlight loss if the subtitle file has minor shifts.

## Goals / Non-Goals

**Goals:**
- Optimize Phase 3 performance by implementing a shared token scan buffer.
- Enforce realistic temporal constraints for segment-bridging contiguous phrases (1.5s).
- Implement resilient "Gated Healing" for Local Mode index anchoring.
- Standardize all internal fallbacks to match global configuration.

**Non-Goals:**
- Changing the core `logical_idx` algorithm.
- Introducing a persistent global token cache (cache should be per-refresh).
- Altering the TSV schema.

## Decisions

### 1. Shared Context Buffer
Within `calculate_highlight_stack`, or preferably at the call-site in the main rendering loop, a shared `ctx_list` will be generated for the maximum required search window (+/- 35 lines). This list stores cleaned word tokens, timestamps, and indices once, which all Phase 3 evaluations then consume without re-tokenizing.

### 2. Tightened Contiguous Gap
Modify `get_relative_word_text` to accept an optional `max_gap` parameter.
- For **Phase 1 (Contiguous)**, set this to `1.5` seconds.
- For **Phase 3 (Split)**, set this to `Options.anki_split_gap_limit` (60.0s).
This ensures that "Saved Orange" highlights only bridge symbols or short pauses between subtitles, while "Saved Purple" highlights can span long conversational gaps.

### 3. Gated Fuzzy Healing (Local Mode)
In Local Mode (Global OFF), if `data.__pivots` exists and the strict `sub_idx == origin_l + g.l_off` check fails, the engine will search for the expected `(sub_idx, logical_idx)` within a +/- 1 line radius. If a matching word is found at a neighboring index that *also* has a valid neighborhood match (Phase 2), the highlight is restored. This prevents "highlight drop" due to minor file edits while maintaining high precision.

### 4. Hardened Fallbacks
Standardize the default values in `calculate_highlight_stack`:
- `anki_split_search_window` defaults to `35` (currently 15/20 in code).
- `anki_split_gap_limit` defaults to `60.0` (currently 10.0 in code).

## Risks / Trade-offs

- **Performance**: Building a shared `ctx_list` for every refresh cycle (every frame change) adds a slight overhead at the start of the rendering loop. 
- **Solution**: The `ctx_list` should only be built when `sub_idx` changes or highlights are reloaded, not necessarily on every frame if the player is paused.
- **Complexity**: Gated Healing adds logic to the Phase 2 path, potentially increasing latency for large cards. However, since it only fires on failure, the overhead is minimal for healthy indices.
