# Standardized Terminology and Historicity

## Purpose
Define the project's canonical language, color space, and historical evolution to ensure consistency across AI-generated code, documentation, and user requests.
## Requirements
### Requirement: Infrastructure & Ecosystem Vocabulary
The project environment SHALL use a specific set of terms to describe its tooling and methodology:

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
| **anki_mapping.ini** | Configuration | The dynamic Anki field mapping configuration (`anki_mapping.ini`) located in the repository root. |
| **Central Register** | Log | The `docs/conversation.log` file, acting as the master registry of all requests and interactions. |
| **Legacy Release Store**| Organization | The `docs/rfcs` directory containing historical releases using the **SDD** methodology. |
| **OpenSpec** | Methodology | The modern, agentic-centric specification framework for active development. |
| **SDD** | Methodology | **Software Design Document**: The legacy planning methodology (now archived). |

#### Scenario: Terminology audit
- **WHEN** reviewing project documentation
- **THEN** all infrastructure terms SHALL match the definitions above.

### Requirement: The ZID Traceability Model
The project utilizes a timestamp-based anchoring system (**ZID**) to ensure absolute traceability:
- **ZID (Zettelkasten Identifier)**: A unique `yyyyMMddHHmmss` string generated for every interaction and commit. It is **project-unique**, serving as a one-to-one primary key for any event or record.
- **Git Commit Linking**: Every commit SHALL include the ZID of the request that triggered it.
- **Conversation Anchors**: Every AI message (to and from chat) and major artifact (Release Notes, Specifications) SHALL be prefixed with a ZID tag.
- **Unified Registry**: The `conversation.log` acts as the **Single Source of Truth** and central register for all anchors, complementing the user's private **Linguistic Journal**.
- **Rationale**: This creates an immutable link between the **Source Code** (Git), the **Conversation** (`conversation.log`), and the **Activity Log** (AI session). These anchors allow the AI and user to refer back to any specific point in history with 100% conceptual precision.

### Requirement: Global Operational Rules (GEMINI.md)
The following mandatory rules govern all technical interactions within the project:
- **Environment**: Development is strictly limited to **Windows 11** and the **Antigravity IDE**.
- **Shell**: Use **PowerShell** only. Avoid `grep`, `ls`, or other Unix-native utilities.
- **Git Protocol**: NEVER perform `Merge` or mutate Git history (Rebase/Force-Push) without direct user instructions.
- **ZID Generation**: At the start of every response, the agent MUST execute `python U:\voothi\20241116203211-zid\zid.py` to obtain the current ZID anchor.
- **Traceability Delta**: When correlating ZIDs between Git commits and the `conversation.log`, allow for a small temporal delta. While the log entry typically precedes the Git commit, the sequence may occasionally be reversed; always look for the closest matching points in the timeline.

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

#### Scenario: Thesaurus consistency
- **WHEN** generating OSD feedback or log messages
- **THEN** the system SHALL use terms defined in the thesaurus (e.g., `[Kardenwort]` instead of `[Kardenwort]`).

### Requirement: Historical Entity Mapping
The project SHALL maintain a flat "Correspondence Table" for all renamings to allow the AI to trace chains of identity (e.g., A → B → C).

| Legacy Term | Subject | Modern Equivalent | Transition ZID |
| :--- | :--- | :--- | :--- |
| `mpv Language Learning Suite`| Project | `mpv Language Acquisition Suite`| 20260310145846 |
| `Learning` | Domain | `Acquisition` | 20260310145846 |
| `mpv Language Acquisition Suite`| Project | `Kardenwort MPV` | 20260322202226 |
| `kardenwort-mpv.lua` | Script | `kardenwort/main.lua` | 20260414150031 |
| `sub_context.lua` | Script | `kardenwort/main.lua` | 20260408221530 |
| `autopause.lua` | Script | `kardenwort/main.lua` | 20260408221530 |
| `copy_sub.lua` | Script | `kardenwort/main.lua` | 20260408221530 |
| `fixed_font.lua` | Script | `kardenwort/main.lua` | 20260408221530 |
| `kardenwort/main.lua` | Script | `scripts/kardenwort/main.lua`| 20260511182348 |
| `kardenwort_utils.lua` | Script | `scripts/kardenwort/utils.lua` | 20260511182348 |
| `resume_last_file.lua`| Script | `scripts/kardenwort/resume.lua`| 20260511182348 |
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

#### Scenario: Legacy term lookup
- **WHEN** an AI agent encounters the term `kardenwort/main.lua`
- **THEN** it SHALL treat it as an alias for `scripts/kardenwort/main.lua` based on the mapping table.

### Requirement: Dual-Notation Color Specification
To prevent rendering ambiguity between ASS (BGR) and Web (RGB) hex formats, all color definitions in specifications MUST use the dual-notation standard:
- **Format**: `Color Name (BGR: [HEX] | RGB: #[HEX])`
- **Example**: `Gold (BGR: 00CCFF | RGB: #FFCC00)`

### Requirement: Linear Evolution Ledger
The project SHALL maintain a flat "Correspondence Table" for all renamings to allow the AI to trace chains of identity (e.g., A → B → C).

