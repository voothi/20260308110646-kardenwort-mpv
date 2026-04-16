## Context
The `anki_strip_metadata` feature and strict context matching were preventing labels like `[UMGEBUNG]` from highlighting correctly when they appeared in new contexts. Additionally, compound words like `Netto/Globus` were treated as single blocks, making it difficult to select or highlight their components.

## Goals
- Allow bracketed labels to highlight globally by relaxing neighbor checks for them.
- Support intra-word selection and highlighting for terms separated by `-` and `/`.
- Preserve the visual appearance of the Drum Window (no extra spaces around hyphens/slashes).

## Decisions

- **Global Label & Unit Highlighting**: In `calculate_highlight_stack`, words entirely enclosed in brackets `[...]` OR common short units/labels (like `ca`, `km`, `z.B.`) will be exempt from the strict context neighbor check.
- **ASS Tag Stripping**: Update `build_word_list` and match logic to strip ASS tags `{[^}]+}` from tokens before processing. This prevents formatting codes from breaking word matches.
- **Extended Intra-word Splitting**: Include en-dash (`–`) and em-dash (`—`) as word boundaries in `build_word_list`, joining them seamlessly in the OSD.
- **Smart Joiner**: Use the existing smart joiner logic to ensure no extra spaces are added around hyphens, slashes, or dashes.
- **Robust Stripping**: `dw_anki_export_selection` will use an "if entirely bracketed, strip brackets" fallback to ensure labels are saved as clean words.

## Verification
- Highlighting for `[UMGEBUNG]` across multiple segments.
- Clicking `Netto` within `Netto/Globus`.
- Visual verification of `Netto/Globus` rendering in Drum Window.
