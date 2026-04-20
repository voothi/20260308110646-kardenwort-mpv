## Why

The formal project specifications have drifted significantly from the actual implementation ground truth (Post-v1.44.2). While `main` is theoretically at `v1.44.2`, the active development branch (`20260420030047`) contains critical hardening for Global Highlighting (Precision Neighborhood Verification) that has not yet been documented. This project synchronizes all specifications with the current robust architectural state to ensure a consistent baseline for future development.

## What Changes

- **Grounding Architecture**: Formally adopt the `LineOffset:WordIndex:TermPos` multi-pivot coordinate system as the standard for mining records.
- **Precision Neighborhood Verification**: Implement word-token intersection logic for Anki Global highlights, ensuring that fuzzy-matched terms are contextually anchored by neighboring tokens.
- **Selection Persistence**: Decouple paired selection sets from modifier-key releases to support remote control devices.
- **Refined Interaction Shield**: Standardize the 150ms temporal "interaction shield" logic to prevent hardware ghost clicks from disrupting user flow.
- **Chromatic Alignment**: Update all visual specifications to match the verified "Warm (Gold/Orange) vs. Cool (Pink/Purple)" color system.
- **Temporal Resilience**: Standardize the 10.0s temporal gap tolerance for high-recall highlight bridging.

## Capabilities

### New Capabilities
- None: This is a documentation alignment project for the existing post-v1.44.x feature set.

### Modified Capabilities
- `high-recall-highlighting`: **MAJOR UPDATE**: Incorporate **Precision Neighborhood Verification** requirements (Word-Token Intersection) and update the inter-segment join tolerance from `1.5s` to `10.0s`.
- `ctrl-multiselect`: Update requirements for selection persistence (persistent across mod-release), color themes (Gold/Pink), and coordinated input triggers.
- `mmb-drag-export`: Align visual feedback requirements (Gold/Orange) with the current rendering engine.
- `drum-window-indexing`: Transition the primary indexing requirement from legacy `SentenceSourceIndex` to the `LineOffset:WordIndex:TermPos` Multi-Pivot system.
- `lls-mouse-input`: Incorporate the 150ms Interaction Shield and remove outdated `ctrl-released` discard rules.
- `smart-joiner-service`: Add requirements for the Elliptical Joiner (` ... `) logic.
- `source-url-discovery`: Add requirements for mapping extracted metadata to the `source_url` Anki field.

## Impact

- **Documentation**: 7 existing specifications will be updated to reflect truth.
- **Context**: The `openspec/specs` directory will finally account for the "unreleased" highlighting hardening currently active in `lls_core.lua`.
- **Verification**: Future changes on this branch will be validated against these high-fidelity coordinates and fuzzy-verification rules.
