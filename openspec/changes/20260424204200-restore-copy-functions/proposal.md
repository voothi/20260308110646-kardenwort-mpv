# Proposal: Restore Copy Mode and Context Functions

## Problem Statement
After implementing cursor synchronization for manual navigation in Book Mode, a regression was reported where the global `z` (Cycle Copy Mode) and `x` (Toggle Context Copy) functions stopped working as expected. This primarily affects users navigating the Drum Window in Book Mode, as the current selection-based copy logic (`cmd_dw_copy`) does not respect the global context and language target settings, and the keys themselves may feel unresponsive or blocked by the Drum Window's forced interaction model.

## User Impact
- Users cannot toggle Context Copy (`x`) or cycle Language Targets (`z`) while the Drum Window is active.
- Manual selections in the Drum Window do not include surrounding context lines even if `COPY_CONTEXT` is "ON".
- Language filtering (Copy Mode A vs B) is ignored during Drum Window exports.

## Proposed Solution
1. **Explicit Key Hijacking**: Integrate `z` and `x` into the Drum Window's `manage_dw_bindings` to ensure they are captured and executed reliably while the window is active.
2. **Context-Aware Drum Copy**: Enhance `cmd_dw_copy` to respect the `FSM.COPY_CONTEXT` state. When enabled, the verbatim selection will be wrapped with the configured number of context lines.
3. **Language-Aware Drum Copy**: Refactor the fallback copy logic in `cmd_dw_copy` (single line/word) to respect `FSM.COPY_MODE`, allowing users to copy the translation instead of the source text when desired.
4. **Resilient OSD Feedback**: Ensure that `show_osd` messages for mode toggles are not obscured by the Drum Window's own high-frequency rendering loop.

## Expected Outcomes
- Restored functionality for `z` and `x` keys in all modes.
- Consistent copy behavior between regular subtitles and the Drum Window.
- Enhanced precision for learners who rely on context and translation toggles during manual navigation in Book Mode.
