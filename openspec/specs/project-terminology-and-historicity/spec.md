# Standardized Terminology and Historicity

## Purpose
Define the project's canonical language, color space, and historical evolution to ensure consistency across AI-generated code, documentation, and user requests.

## Requirements

### Requirement: Canonical Thesaurus Adherence
The AI agent and developers SHALL prioritize the following canonical terms over generic descriptions:
- **Warm Path**: Contiguous selection (Gold) → Orange database match.
- **Cool Path**: Non-contiguous/split selection (Pink) → Purple database match.
- **Surgical Highlighting**: Alphanumeric coloring only (preserving white punctuation).
- **Interaction Shield**: Ghost-click suppression (50ms-150ms).
- **Grounded Match**: Highlighting anchored to a specific `logical_idx` and `time_pos`.

### Requirement: Historical Entity Mapping
When processing user requests referencing legacy terms or analyzing ZIDs from previous versions, the agent SHALL apply the following mappings:
| Legacy Term | Subject | Modern Equivalent | Transition ZID |
| :--- | :--- | :--- | :--- |
| `Red` | Selection | `Bright Yellow` | `<Legacy>` |
| `Bright Yellow` | Selection | `Gold` | 20260419140508 |
| `Pale Yellow` | Selection | `Gold` | 20260419140508 |
| `Muted Yellow` | Selection | `Pink` | 20260501172103 |
| `Blue` | Active Line | `White` | 20260428192102 |
| `Green` | Match | `Orange` | 20260419140508 |
| `Auto-hover` | Tooltip | `Translation Tooltip`| 20260412105348 |

### Requirement: Dual-Notation Color Specification
To prevent rendering ambiguity between ASS (BGR) and Web (RGB) hex formats, all color definitions in specifications MUST use the dual-notation standard:
- **Format**: `Color Name (BGR: [HEX] | RGB: #[HEX])`
- **Example**: `Gold (BGR: 00CCFF | RGB: #FFCC00)`

### Requirement: Linear Evolution Ledger
The project SHALL maintain a flat "Correspondence Table" for all renamings to allow the AI to trace chains of identity (e.g., A → B → C).
