## Why

The current implementation of the Drum Window interaction and grounding logic contains critical mathematical bugs and configuration desyncs that undermine the reliability of the Multi-Pivot Grounding system. Specifically, the adaptive temporal window calculation for long phrases is numerically incorrect, and the interaction shield duration is inconsistent across different input methods. This change hardens the engine to ensure 100% compliance with the Post-v1.44.2 specifications and professional stability standards.

## What Changes

- **Grounding Fix**: Rectify the adaptive temporal window calculation in `calculate_highlight_stack` to correctly apply the word-count growth factor only to words beyond the 10th.
- **Interaction Hardening**: Standardize the 150ms interaction shield across all navigational and remote-bound keys to eliminate "ghost clicks" caused by hardware jitter.
- **Configuration Alignment**: Synchronize `mpv.conf` and script defaults to the specification-mandated 150ms lockout duration.
- **Shield Trigger Optimization**: Refine the shield logic to ignore modifier keys (Ctrl, Shift, etc.), preventing accidental lockout during complex key combinations.

## Capabilities

### Modified Capabilities
- `window-highlighting-spec`: Update temporal bridging and neighborhood verification requirements to reflect hardened math.
- `drum-window-indexing`: Refine the interaction shield interaction model to enforce systemic 150ms lockout.

## Impact

- **Affected Files**: `scripts/lls_core.lua`, `mpv.conf`
- **Dependencies**: No new external dependencies.
