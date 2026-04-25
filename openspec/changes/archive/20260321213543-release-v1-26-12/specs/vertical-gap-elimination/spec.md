# Spec: Vertical Gap Elimination

## Context
Incorrect newline characters and split anchors caused artificial vertical gaps in Drum Mode.

## Requirements
- Use exactly one `\N` between context lines in Drum Mode.
- Abandon split `\an8` / `\an2` logic for the same context block.
- Standardize on `\an8` for top contexts and `\an2` for bottom contexts.

## Verification
- Confirm that the vertical spacing between the active line and its context is consistent with standard line heights.
- Verify that there are no "double empty lines" between subtitle segments.
