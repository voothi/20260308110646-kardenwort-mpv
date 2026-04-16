## Context
The `anki_strip_metadata` feature and strict context matching were preventing labels like `[UMGEBUNG]` from highlighting correctly when they appeared in new contexts. Additionally, compound words like `Netto/Globus` were treated as single blocks, making it difficult to select or highlight their components.

## Goals
- Allow bracketed labels to highlight globally by relaxing neighbor checks for them.
- Support intra-word selection and highlighting for terms separated by `-` and `/`.
- Preserve the visual appearance of the Drum Window (no extra spaces around hyphens/slashes).

## Decisions

- **Global Label Highlighting**: In `calculate_highlight_stack`, a word that is entirely enclosed in brackets `[...]` in the subtitle will be exempt from the neighbor strictness check.
- **Intra-word Splitting**: 
    - `build_word_list` will perform a second pass to split tokens by `[/-]` symbols, keeping the symbols as their own tokens.
    - `dw_osd:update` will use a "smart joiner" logic: add a space between words ONLY if neither the current word nor the next word is a hyphen or slash.
- **Robust Stripping**: `dw_anki_export_selection` will use an "if entirely bracketed, strip brackets" fallback to ensure labels are saved as clean words.

## Verification
- Highlighting for `[UMGEBUNG]` across multiple segments.
- Clicking `Netto` within `Netto/Globus`.
- Visual verification of `Netto/Globus` rendering in Drum Window.
