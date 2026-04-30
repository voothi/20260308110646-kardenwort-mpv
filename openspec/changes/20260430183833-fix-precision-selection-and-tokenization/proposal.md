## Why

The current subtitle interaction logic makes precise selection difficult. Specifically, punctuation and brackets are often bundled with adjacent words, and keyboard navigation is not sufficiently granular for professional-grade vocabulary mining. Users need the ability to surgically select exactly what they want without highlight "bleeding" or imprecise cursor jumps.

## What Changes

- **Restored Precision Navigation**: `Shift` + `Arrow` keys now step through punctuation, brackets, and symbols individually, allowing for character-level precision when needed.
- **Improved Tokenization**: Brackets (`[` `]`), slashes (`/`), and hyphens (`-`) are now treated as separate tokens rather than part of a word. This allows clicking a word inside brackets (like `[UMGEBUNG]`) to only highlight the word itself.
- **Strict Highlight Boundaries**: Removed the global semantic color-spreading logic. Highlights (both user selections and database matches) are now strictly unambiguous and only color the tokens they represent.
- **Space Filtering**: Navigation remains character-precise but continues to skip pure whitespace tokens to maintain momentum.

## Capabilities

### New Capabilities
- `precision-navigation`: Character-level stepping through non-word symbols when holding Shift.
- `atomic-punctuation-tokens`: Separation of logistical symbols from alphanumeric word clusters.

### Modified Capabilities
- `rendering-engine`: Removal of highlight-bleeding (semantic pass) to ensure unambiguous visual feedback.

## Impact

- `lls_core.lua`: Significant changes to tokenization rules, cursor navigation logic, and the rendering pipeline.
- Selection/Highlighting: Visual feedback is now more surgical and directly reflects the exported data.
