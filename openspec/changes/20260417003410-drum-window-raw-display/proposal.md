## Why

Users noticed that the state-machine scanner (introduced for Lute-style tokenization) causes artificial spaces to appear around special characters (e.g., `z . B .` instead of `z.B.`). This occurs because the new "Smart Joining" logic in `compose_term_smart` makes assumptions about word boundaries that don't always match the original subtitle file's intent. Bringing back "Original Form" display is necessary for high-fidelity rendering, especially for German compounds and acronyms.

## What Changes

- **Parametrization**: Introduce `dw_original_spacing` (Boolean) to allow users to choose between Lute-style "Clean" display and "Original Form" (Mirror) display.
- **Scanner Evolution**: Update the parser to capture whitespace as distinct "Filler Tokens" instead of discarding them.
- **Joiner Logic**: Update `compose_term_smart` to use preserved original spacing tokens when `dw_original_spacing` is enabled.
- **Selection Isolation**: Decouple the "Visual Token Stream" from the "Logical Word Index" to ensure word-jumps (A/D keys) and Anki selection indexing remain stable and predictable.

## Capabilities

### New Capabilities
- `original-spacing-preservation`: The ability to perfectly mirror the formatting of source subtitle files while maintaining individual word selection and coloring.

### Modified Capabilities
- `scanner-parser`: Updated to support full character-stream tokenization including whitespace.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (Scanner core, display joiner, selection logic).
- **Core Systems**: Drum Window rendering, Word Selection (Manual), Anki Export.
- **Config**: Adds `dw_original_spacing` to `mpv.conf`.
