## Why

The current subtitle export system is fragmented across different selection modes (Yellow/Range and Pink/Set), leading to inconsistent behavior in punctuation restoration and spacing. Keyboard navigation is currently limited to word-level jumps, making it difficult to select specific punctuation marks with the same granularity as mouse selection. Centralizing the string preparation logic and enhancing keyboard movement will ensure data fidelity and architectural consistency.

## What Changes

- **Unified Export Logic**: Consolidate all string preparation for clipboard and Anki exports into a single `prepare_export_text` service in `lls_core.lua`.
- **Fidelity Preservation**: Implement token-lookbehind in the non-contiguous (Pink) export path to preserve verbatim connectors like hyphens and slashes between adjacent members.
- **Punctuation Parity**: Unify the detection and restoration of terminal punctuation (`!`, `?`, `.`) across all mining pathways.
- **Keyboard Granularity**: Update the Drum Window keyboard navigation to allow token-by-token movement when the Shift key is held, enabling the selection of individual punctuation marks.

## Capabilities

### New Capabilities
- `keyboard-selection-granularity`: Enables precise token-level cursor movement and selection using Shift + Arrow keys in the Drum Window.

### Modified Capabilities
- `anki-export-mapping`: Standardizes the preparation, cleaning, and formatting of subtitle text for Anki exports across all interaction modes.

## Impact

- **Affected Files**: `scripts/lls_core.lua`.
- **Systems**: Anki Export (TSV), Clipboard Copy, Drum Window UI interaction.
- **Dependencies**: Relies on the existing `build_word_list_internal` tokenizer for granular token access.
