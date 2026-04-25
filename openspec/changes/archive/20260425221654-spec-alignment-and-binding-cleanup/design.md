## Context

During the recent compliance audit, two areas for refinement were identified:
1. The `inter-segment-highlighter` specification incorrectly mandates a 1.5s temporal gap for joining segments, whereas the implementation successfully uses a 60s threshold for broader contextual recall.
2. The `lls_core.lua` script contains redundant `mp.add_forced_key_binding` calls for Book Mode with `nil` key arguments, which are unnecessary as the bindings are correctly managed via `input.conf`.

## Goals / Non-Goals

**Goals:**
- Formally update the `inter-segment-highlighter` requirements to reflect the 60s threshold.
- Remove lines 5741-5742 from `lls_core.lua`.

**Non-Goals:**
- Changing the actual 60s implementation logic (it is already functional and desired).
- Modifying `input.conf`.

## Decisions

- **Requirement Update**: The `Requirement: Temporal Proximity for Multi-Segment Phrases` in the `inter-segment-highlighter` spec will be updated to 60.0 seconds.
- **Code Pruning**: Delete the redundant `add_forced_key_binding` calls. These were likely legacy placeholders or intended as named bindings that are already covered by `mp.add_key_binding(nil, "toggle-book-mode", ...)`.

## Risks / Trade-offs

- **None**: These are low-risk alignment and cleanup tasks.
