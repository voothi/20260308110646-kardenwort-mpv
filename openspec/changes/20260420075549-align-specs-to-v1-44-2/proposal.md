## Why

The formal project specifications have drifted significantly from the actual implementation ground truth (v1.44.2). Recent architectural hardening—including Multi-Pivot Grounding, persistent selection logic, and the "Warm vs. Cool" color palette—has been fully implemented and verified in `lls_core.lua` but has not yet been archived into the `openspec/specs` repository. This ensures future changes are built on an accurate operational baseline.

## What Changes

- **Grounding Architecture**: Formally adopt the `LineOffset:WordIndex:TermPos` multi-pivot coordinate system as the standard for mining records.
- **Selection Persistence**: Decouple paired selection sets from modifier-key releases to support remote control and minimalist input devices.
- **Refined Interaction Shield**: Standardize the 150ms temporal "interaction shield" logic to prevent hardware ghost clicks from disrupting user flow.
- **Chromatic Alignment**: Update all visual specifications to match the verified "Warm (Gold/Orange) vs. Cool (Pink/Purple)" color system.
- **Temporal Resilience**: Standardize the 10.0s temporal gap tolerance for high-recall highlight bridging across subtitle segments.
- **Metadata Integration**: Explicitly define the extraction of `source_url` metadata for Anki export.

## Capabilities

### New Capabilities
- None: This is a documentation alignment project for the existing v1.44.x feature set.

### Modified Capabilities
- `ctrl-multiselect`: Update requirements for selection persistence (persistent across mod-release), color themes (Gold/Pink), and coordinated input triggers.
- `mmb-drag-export`: Align visual feedback requirements (Gold/Orange) with the current rendering engine.
- `drum-window-indexing`: Transition the primary indexing requirement from the legacy `SentenceSourceIndex` to the `LineOffset:WordIndex:TermPos` Multi-Pivot system.
- `lls-mouse-input`: Incorporate the 150ms Interaction Shield and remove outdated `ctrl-released` discard rules.
- `high-recall-highlighting`: Update the inter-segment join tolerance from `1.5s` to `10.0s`.
- `smart-joiner-service`: Add requirements for the Elliptical Joiner (` ... `) logic used in non-contiguous phrase reconstruction.
- `source-url-discovery`: Add requirements for mapping extracted metadata to the `source_url` Anki field.

## Impact

- **Documentation**: 7 existing specifications will be updated to reflect truth.
- **Code**: No functional logic changes required in the core engine; this is a documentation-only alignment.
- **Verification**: Future tests and changes will be checked against the robust v1.44.2 requirements.
