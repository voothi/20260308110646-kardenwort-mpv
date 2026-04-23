## Why

This change formalizes the Cyrillic Import Fix & UI Silence introduced in Release v1.26.4. To maintain a high-quality "English reading" experience in the Drum Window, it was necessary to filter out translation noise (Cyrillic characters) that often appears in mixed-track `.ass` files. Additionally, the user requested the removal of redundant UI status messages to achieve a more "premium" and focused immersion environment.

## What Changes

- Implementation of **Targeted .ass Filtering**: The `load_sub` parser now utilizes a `has_cyrillic` check to skip translation dialogue lines, ensuring only target-language content is imported into the primary reading area.
- Implementation of **UI Noise Reduction**: Redundant OSD status messages (e.g., "Drum Window: OPEN/CLOSED") have been suppressed to prioritize immediate visual feedback and a minimalist aesthetic.
- Hardening of **Text Processing**:
    - **Hoisting**: Core utilities (`has_cyrillic`, `is_word_char`, `build_word_list`) have been moved to the top of the script to ensure they are initialized before use.
    - **Nil-Safety**: Strategic guards have been added to all base text functions to prevent runtime exceptions when processing malformed subtitle data.

## Capabilities

### New Capabilities
- `targeted-content-filtering`: A data-cleansing capability that selectively imports subtitle content based on linguistic markers (e.g., character set detection).
- `ui-noise-reduction`: A design philosophy that minimizes non-essential OSD feedback to increase user focus during intensive immersion.

### Modified Capabilities
- `text-processing-hardening`: Structural patterns that improve script stability and text analysis reliability.

## Impact

- **Clean Reading Experience**: Translation clutter is eliminated from the Drum Window's primary view.
- **Focused Immersion**: Zero-latency, silent UI toggles that reduce distractions.
- **Improved Stability**: Reduced risk of script crashes during subtitle loading and text parsing.
