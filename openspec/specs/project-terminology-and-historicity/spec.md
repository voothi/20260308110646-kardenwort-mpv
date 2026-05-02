# Standardized Terminology and Historicity

## Purpose
Define the project's canonical language, color space, and historical evolution to ensure consistency across AI-generated code, documentation, and user requests.

## Requirements

### Requirement: Infrastructure & Ecosystem Vocabulary
The project environment uses a specific set of terms to describe its tooling and methodology:

| Term | Subject | Definition |
| :--- | :--- | :--- |
| **ZID** | Methodology | **Zettelkasten Identifier** (`yyyyMMddHHmmss`) used to link commits, logs, and AI conversations. |
| **Kardenwort Ecosystem**| Project | An open-source suite of linguistic utilities on GitHub (e.g. En, De) for language acquisition. |
| **Antigravity** | Infrastructure | The agentic AI coding IDE used for project development. |
| **Weak Model** | AI Tier | Low-latency models (e.g. **Gemini 3 Flash**) used for routine auditing and simple edits. |
| **Middle Model** | AI Tier | Balanced models (e.g. **Gemini 3.1 Pro (low)**, **Sonnet 4.6**) for feature implementation. |
| **Senior / Pro Model** | AI Tier | High-reasoning models (e.g. **Gemini 3.1 Pro (high)**, **Opus 4.6**) for architecture. |
| **OpenSpec Core** | Organization | The `openspec/specs` directory containing current, general system specifications. |
| **Change Project** | Organization | The `openspec/changes` directory containing active feature implementations. |
| **Change Archive** | Organization | The `openspec/changes/archive` directory containing historical completed tasks. |
| **mpv.conf** | Configuration | The primary player and script configuration file. |
| **input.conf** | Configuration | The centralized keybinding configuration file. |
| **anki_mapping.ini** | Configuration | The dynamic Anki field mapping configuration (`script-opts/anki_mapping.ini`). |
| **Central Register** | Log | The `docs/conversation.log` file, acting as the master registry of all requests and interactions. |
| **Legacy Release Store**| Organization | The `docs/rfcs` directory containing historical releases using the **SDD** methodology. |
| **OpenSpec** | Methodology | The modern, agentic-centric specification framework for active development. |
| **SDD** | Methodology | **Software Design Document**: The legacy planning methodology (now archived). |

### Requirement: The ZID Traceability Model
The project utilizes a timestamp-based anchoring system (**ZID**) to ensure absolute traceability:
- **ZID (Zettelkasten Identifier)**: A unique `yyyyMMddHHmmss` string generated for every interaction and commit.
- **Git Commit Linking**: Every commit SHALL include the ZID of the request that triggered it.
- **Rationale**: This creates an immutable link between the **Source Code** (Git), the **Conversation** (`conversation.log`), and the **Activity Log** (AI session), allowing developers to reconstruct the exact context of any change by following the closest timestamp delta.

### Requirement: Canonical Thesaurus Adherence
The AI agent and developers SHALL prioritize the following canonical terms over generic descriptions:

| Term | Subject | Definition |
| :--- | :--- | :--- |
| **DualSub / DualSubs** | Core | The practice of displaying two subtitle tracks (Target + Translation) simultaneously. |
| **Primary Track** | Core | The target-language subtitle track (the focus of acquisition). |
| **Secondary Track** | Core | The native-language translation subtitle track (the reference). |
| **Interleaved Tracks**| Logic | A single `.ass` file containing alternating tracks that require de-duplication/merging. |
| **LMB / RMB / MMB** | Mouse | **Left**, **Right**, and **Middle** mouse buttons respectively. |
| **SRT Mode** | Core UI | The standard subtitle display mode (formerly "Normal Mode"). |
| **Drum Mode (Mode C)** | Core UI | A playback mode that dims context lines to highlight the active subtitle (formerly "Reel Mode"). |
| **Drum Window (Mode W)** | Core UI | The primary high-precision OSD viewport for reading and word-level navigation (formerly "Static Reading Mode"). |
| **Search HUD** | Core UI | The `Ctrl+F` global search interface (formerly "Search Box"). |
| **Translation Tooltip** | UX | The secondary subtitle hint (Balloon) toggled by `e` (RU `у`). |
| **Book Mode** | Navigation | A stationary viewport state where navigation doesn't reset scrolling (formerly "Reading Mode"). |
| **Context Copy Mode** | Logic | The mechanism for exporting multi-line subtitle blocks to the clipboard (formerly "Copy Subtitle Mode"). |
| **Token Meta** | Logic | The centralized metadata object tracking word-level state, colors, and hit-zones. |
| **FSM (Finite State Machine)** | Logic | The master controller managing mode transitions (SRT, Drum, Search) and state flags. |
| **Master Tick** | Engine | The 0.05s central execution loop (`master_tick()`) that funnels all periodic OSD updates. |
| **Isotropic Mapping** | Rendering | Scaling the X/Y grid based on height (`oh / 1080`) to ensure resolution-independent hit-testing. |
| **UPSR** | Logic | **Unified Punctuation Spacing Rule**: Central engine (`compose_term_smart`) for joining word tokens. |
| **Atomic Tokens** | Parsing | Symbols like `[` `]` `/` `-` treated as distinct logical entities for surgical selection. |
| **Safety Gap** | Layout | The mandatory vertical offset (5%) between primary and secondary OSD tracks. |
| **Aural Buffer** | Timing | The temporal padding (`pause_padding`) added before autopause to prevent syllable clipping. |
| **Consolas Calibration** | Rendering | The font-specific multipliers (`char_width`, `line_height`) used for pixel-perfect hit-testing. |
| **Viewport Margin** | UI | The number of context lines kept visible during vertical scrolling (`scrolloff`). |
| **scrolloff** | UI | The "Indentation Field" (default 3 lines) at the top/bottom before the viewport scrolls. |
| **Fuzzy Search** | Search | Logic allowing typos and non-contiguous character matching in the Search HUD. |
| **Order-Independent Search**| Search | Keyword matching that ignores the sequence of words in the query. |
| **Query Buffer** | Search | The active text input field in the Search HUD. |
| **Surgical Highlighting** | Logic | Coloring only alphanumeric tokens while preserving white punctuation. |
| **Warm Path** | Interaction | Contiguous selection (**Gold**) resulting in an **Orange** match. |
| **Cool Path** | Interaction | Non-contiguous/split selection (**Pink**) resulting in a **Purple** match. |
| **Kardenwort MPV** | Branding | The modern name of the suite (formerly "mpv Language Acquisition Suite"). |
| **Follow Mode** | UI | Viewport state that automatically tracks active playback. |
| **Manual Mode** | UI | Viewport state where scrolling is user-controlled (scrolling "frozen"). |
| **Edge-scrolling** | UI | Automatic scrolling when the cursor hits viewport boundaries. |
| **Smart Spacebar** | Logic | Multi-modal playback key handling Pause, Autopause, and Resume. |
| **Karaoke Merging** | Logic | Process of reassembling fragmented word tokens into chronological sentences. |
| **Language-Aware Context** | Logic | Filtering context extraction to exclude translations (e.g. via Cyrillic detection). |
| **Layout Agnosticism** | UX | Mapping standard keys across multiple keyboard layouts (EN/RU). |
| **Interaction Shield** | Stability | A 50-150ms suppression window to ignore hardware jitter (ghost-clicks). |
| **Grounded Match** | Accuracy | Highlighting anchored to a specific `logical_idx` and `time_pos`. |

### Requirement: Historical Entity Mapping
When processing user requests referencing legacy terms or analyzing ZIDs from previous versions, the agent SHALL apply the following mappings:
| Legacy Term | Subject | Modern Equivalent | Transition ZID |
| :--- | :--- | :--- | :--- |
| `mpv Language Learning Suite`| Project | `mpv Language Acquisition Suite`| 20260310145846 |
| `Learning` | Domain | `Acquisition` | 20260310145846 |
| `mpv Language Acquisition Suite`| Project | `Kardenwort MPV` | 20260322202226 |
| `kardenwort-mpv.lua` | Script | `lls_core.lua` | 20260414150031 |
| `sub_context.lua` | Script | `lls_core.lua` | 20260408221530 |
| `autopause.lua` | Script | `lls_core.lua` | 20260408221530 |
| `copy_sub.lua` | Script | `lls_core.lua` | 20260408221530 |
| `fixed_font.lua` | Script | `lls_core.lua` | 20260408221530 |
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
