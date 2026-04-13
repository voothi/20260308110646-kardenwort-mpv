## 1. Configuration & Schema Setup

- [x] 1.1 Standardize parameter names in the script's option table (srt, drum, dw, tooltip).
- [x] 1.2 Add entries for `font_name` and `font_bold` for each of the four modes.
- [x] 1.3 Update `mpv.conf` with example configurations for the new unified styling interface.

## 2. Core Rendering Integration

- [x] 2.1 Modify the SRT rendering path to inject `{\fn}` and `{\b}` tags based on user config.
- [x] 2.2 Update Drum Mode (c) rendering logic to support custom font selection and weight.
- [x] 2.3 refactor Drum Window (w) rendering to apply localized styling from the unified schema.
- [x] 2.4 Update Tooltip rendering to support specific font and weight overrides.

## 3. Transparency & Sizing Unified Logic

- [x] 3.1 Implement a helper function to calculate ASS alpha hex codes from numeric opacity strings.
- [x] 3.2 Apply unified background opacity logic to Drum Window boxes.
- [x] 3.3 Apply unified background opacity logic to Tooltip boxes.
- [x] 3.4 Ensure font sizing metrics are consistent and scaled correctly across OSD resolutions.

## 4. Verification & Premium Polish

- [x] 4.1 Verify font selection works with spaces and special characters.
- [x] 4.2 Validate that font weight (bold) toggles work correctly without disrupting text alignment.
- [x] 4.3 Ensure fallback behavior when a font is missing from the system.
- [x] 4.4 Final visual audit for stylistic parity across all modes.
