## Why

This change formalizes the features introduced in Release v1.0.0 into the OpenSpec system. This release marked the transition of the mpv configuration into a specialized Language Learning Suite, focusing on "Drum" context visualization, intelligent autopause behavior, and a unified OSD system.

## What Changes

- Formal specification of the **Drum Context Mode**, including dynamic highlights and ASS protection.
- Definition of the **Karaoke-Safe Autopause** suite, covering "End of Phrase", "Word by Word", and "Hold-to-Play" behaviors.
- Standardization of the **Clean OSD System**, including positioning, styling, and universal application across scripts.

## Capabilities

### New Capabilities
- `drum-context`: Provides visualization of preceding and succeeding subtitle lines around the active dialogue with dynamic highlighting.
- `karaoke-autopause`: Implements advanced pause logic that tracks karaoke tokens in dual tracks and supports hold-to-bypass functionality.
- `clean-osd`: A unified notification system with specific styling (Middle-Left, 20pt font) and reactive timing (500ms duration).

### Modified Capabilities
- None (Initial migration).

## Impact

- **Documentation**: Historical logic and test cases from RFC v1.0.0 are now actionable specifications.
- **Maintenance**: Future changes to these core features can now be tracked via delta specs.
