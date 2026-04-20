## Why

The formal project specifications have drifted significantly from the actual implementation ground truth (Post-v1.44.2). While the core features were implemented to support specialized input (8BitDo Zero 2) and precision mining, several layers—most notably **Precision Neighborhood Verification** and **Multi-Pivot Grounding**—remain undocumented in the central spec repository. This project synchronizes all specifications with the current robust architectural state.

## What Changes

- **Grounding Architecture**: Formally adopt the `LineOffset:WordIndex:TermPos` multi-pivot coordinate system.
- **Precision Neighborhood Verification**: Implement **Word-Token Intersection logic** for Global highlights, ensuring contextually grounded matching across disjoint scenes.
- **Selection Persistence**: Decouple paired selection sets (Pink) from modifier-key releases to support minimalist remotes.
- **Refined Interaction Shield**: Standardize the 150ms temporal shield to prevent hardware ghost clicks.
- **Unified Spacing & Joining**: Implement the **Unified Punctuation Spacing Rule (UPSR)** and **Elliptical Joiners (` ... `)** for high-fidelity term reconstruction.
- **Chromatic Alignment**: Update visuals to the "Warm (Gold/Orange) vs. Cool (Pink/Purple)" system.
- **Metadata Integration**: Explicitly define the extraction of `source_url` metadata.

## Capabilities

### Modified Capabilities
- `high-recall-highlighting`: **MAJOR UPDATE**: Incorporate **Precision Neighborhood Verification** (Token Intersection) and update temporal bridging to **60.0s**.
- `ctrl-multiselect`: Update for selection persistence (Pink set stays), colors (Gold/Pink), and coordinated input.
- `mmb-drag-export`: Align visual feedback (Gold) and automatic commit logic.
- `drum-window-indexing`: Transition to **Multi-Pivot Grounding** and add **Temporal Epsilon (+1ms)**.
- `lls-mouse-input`: Incorporate **150ms Interaction Shield** and **Pointer Jump Sync**.
- `smart-joiner-service`: Formalize **UPSR** and **Elliptical Joiner** logic.
- `source-url-discovery`: Add **source_url** Anki keyword mapping.

## Impact

- **Documentation**: 7 existing specifications synchronized with HEAD.
- **Context**: Resolves the "unreleased" documentation gap for highlighting hardening.
- **Verification**: Future features will benefit from the stabilized grounding and verification rules established here.
