## Why

This change formalizes the Subtitle Feature Consistency & Feedback introduced in Release v1.26.8. To ensure a reliable user experience, it was necessary to address scenarios where advanced features (Drum Mode, Search, etc.) would silently fail or behave unpredictably when used with embedded subtitles rather than external tracks. This update introduces robust validation guards and significantly improves the clarity of OSD feedback for complex track and copy mode interactions.

## What Changes

- Implementation of **Robust Feature Guarding**: Toggle functions for Drum Mode (`c`), Drum Window (`w`), and Search (`Ctrl+F`) now include validation checks for the existence of external subtitle paths (`Tracks.pri.path`).
- Implementation of **Descriptive Copy Mode Feedback**: The `cmd_cycle_copy_mode` (`z`) utility has been updated to provide semantic OSD labels:
    - **A (Primary/Target)**: For target-language acquisition.
    - **B (Secondary/Translation)**: For context verification.
    - **Fixed to Primary**: Automatically identified for single-track scenarios.
- Introduction of **Intelligent Track Cycle Feedback**: The `cmd_cycle_sec_sid` (`j`) function now provides descriptive feedback based on the detected codec:
    - For `.ass` files: "Managed internally by ASS styling."
    - For single `.srt` files: "Only 1 track available."
- Elimination of the "Secondary Subtitles: OFF" loop for structurally singular dual-language files.

## Capabilities

### New Capabilities
- `feature-path-validation`: A safety mechanism that ensures advanced processing features are only activated when their required data dependencies (external subtitle files) are met.
- `descriptive-ui-feedback`: A UX pattern that replaces abstract identifiers with human-readable, context-aware labels.
- `intelligent-track-diagnostics`: A logic layer that analyzes media track properties (codec, count) to provide accurate status reporting.

### Modified Capabilities
- `universal-subtitle-search`: Hardened with path-based activation guards.
- `context-copy-engine`: Upgraded with clearer user feedback.

## Impact

- **User Reliability**: Elimination of silent feature failures; the system now explicitly states when a feature requires external files.
- **Onboarding Efficiency**: New users can immediately understand the purpose of different copy and track modes through descriptive labels.
- **Support Reduction**: Fewer "bugs" reported for expected behaviors in complex subtitle formats (like merged ASS files).
