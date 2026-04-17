## Why

The current regex-based parser in `lls_core.lua` (`build_word_list`) is brittle and difficult to maintain. It frequently fails on complex German compounds, punctuation boundaries, and metadata brackets, leading to inconsistent highlighting and selection behavior. Transitioning to a scanner-based approach (inspired by Lute) will provide a single-pass, robust solution for English and German.

## What Changes

- Implement a single-pass scanner (state machine) to replace the current split-based `build_word_list`.
- Define an explicit set of "Word Characters" for English and German (including `äöüßÄÖÜ`).
- Atomize ASS tags (`{...}`) and Metadata (`[...]`) so they are preserved as single tokens and don't interfere with word boundaries.
- Refactor `compose_term_smart` to work with the new token stream.
- **BREAKING**: Word boundaries in `lls_core.lua` will be redefined to be more consistent, which may slightly change how previous multi-word selections are interpreted.

## Capabilities

### New Capabilities
- `scanner-parser`: A robust, state-machine based tokenization engine for Lua that handles ASS tags, metadata, and multi-language word boundaries.

### Modified Capabilities
- None. (Existing capabilities like `highlighting` remain the same in requirement, but will benefit from the improved implementation).

## Impact

- **Affected Code**: `scripts/lls_core.lua` (specifically the parsing and joining functions).
- **Core Systems**: Highlighting engine, Manual Selection (Drum Window), Anki Export.
- **Dependencies**: None. Remains a pure Lua solution.
