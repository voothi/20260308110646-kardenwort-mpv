# Standardized Terminology and Historicity

## Purpose
Define the project's canonical language, color space, and historical evolution to ensure consistency across AI-generated code, documentation, and user requests.

## Requirements

### Requirement: Canonical Thesaurus Adherence
The AI agent and developers SHALL prioritize the following canonical terms over generic descriptions:

| Term | Subject | Definition |
| :--- | :--- | :--- |
| **SRT Mode** | Core UI | The standard subtitle display mode (formerly "Normal Mode"). |
| **Drum Mode (Mode C)** | Core UI | A playback mode that dims context lines to highlight the active subtitle (formerly "Reel Mode"). |
| **Drum Window (Mode W)** | Core UI | The primary high-precision OSD viewport for reading and word-level navigation (formerly "Static Reading Mode"). |
| **Search HUD** | Core UI | The `Ctrl+F` global search interface (formerly "Search Box"). |
| **Translation Tooltip** | UX | The secondary subtitle hint (Balloon) toggled by `e` (RU `у`). |
| **Book Mode** | Navigation | A stationary viewport state where navigation doesn't reset scrolling (formerly "Reading Mode"). |
| **Context Copy Mode** | Logic | The mechanism for exporting multi-line subtitle blocks to the clipboard (formerly "Copy Subtitle Mode"). |
| **Surgical Highlighting** | Logic | Coloring only alphanumeric tokens while preserving white punctuation. |
| **Warm Path** | Interaction | Contiguous selection (**Gold**) resulting in an **Orange** match. |
| **Cool Path** | Interaction | Non-contiguous/split selection (**Pink**) resulting in a **Purple** match. |
| **Interaction Shield** | Stability | A 50-150ms suppression window to ignore hardware jitter (ghost-clicks). |
| **Grounded Match** | Accuracy | Highlighting anchored to a specific `logical_idx` and `time_pos`. |

### Requirement: Historical Entity Mapping
When processing user requests referencing legacy terms or analyzing ZIDs from previous versions, the agent SHALL apply the following mappings:
| Legacy Term | Subject | Modern Equivalent | Transition ZID |
| :--- | :--- | :--- | :--- |
| `Normal Mode` | UI Mode | `SRT Mode` | Early Development |
| `Reel Mode` | UI Mode | `Drum Mode` | 20260412105348 |
| `Window Mode` | UI Mode | `Drum Window` | 20260414115025 |
| `Static Reading Mode`| UI Mode | `Drum Window` | 20260414115025 |
| `Reading Mode` | Navigation| `Book Mode` | 20260422132514 |
| `Search Box` | UI Component| `Search HUD` | 20260428015150 |
| `Copy Subtitle Mode` | Logic | `Context Copy` | 20260426192835 |
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
