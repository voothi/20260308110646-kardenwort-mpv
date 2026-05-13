## Why

The DM/DW interaction model around `Esc` staged clearing, pointer re-entry, `a`/`d` seeks, and manual viewport scrolling accumulated ambiguous behavior and regressions across recent iterations. The anchor chain from `20260513222855` through `20260513233501` converged on stable runtime expectations, but those guarantees were not packaged as an OpenSpec change proposal.

Without a formal proposal, future refactors can reintroduce stale standing-line state, delayed follow restoration, or DM-vs-DW Book Mode divergence.

## What Changes

- Formalize `Esc` Stage 3 post-conditions as normative behavior, including immediate restore of follow-leading mode in both DM and DW.
- Formalize null-pointer activation semantics after `Esc`, including deterministic source-line resolution and no stale pre-seek/pre-scroll fallback.
- Formalize synchronization rules for null-pointer state after manual `a`/`d` seek and explicit viewport scrolling.
- Formalize DM Book Mode parity with DW Book Mode paging behavior.
- Add a dedicated traceability capability that captures anchor-to-behavior mapping for this regression chain.

## Capabilities

### New Capabilities
- `dm-dw-state-traceability`: Canonical state-machine traceability for DM/DW Esc-follow, pointer source resolution, seek/scroll synchronization, and Book Mode parity.

### Modified Capabilities
- `drum-window`: Clarifies Stage 3 Esc restore semantics and active-line anchoring requirements.
- `drum-window-navigation`: Clarifies null-selection activation and stale-state prevention after seek/scroll.
- `book-mode-navigation`: Extends Book Mode parity requirements to DM mini viewport behavior.

## Impact

- Affected runtime logic: `scripts/kardenwort/main.lua` (Esc Stage 3 follow restore, seek/scroll synchronization, DM Book paging parity).
- Affected specs: `openspec/specs/drum-window/spec.md`, `openspec/specs/drum-window-navigation/spec.md`, `openspec/specs/book-mode-navigation/spec.md`.
- Affected documentation: new traceability capability under `openspec/specs/dm-dw-state-traceability/spec.md`.
- Operational impact: reduces regression risk for DM/DW mode switching and pointer/follow state transitions under real-time subtitle movement.
