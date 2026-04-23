# Kardenwort MPV - Language Acquisition Suite

[![Version](https://img.shields.io/badge/version-v1.48.10-blue)](https://github.com/voothi/20260308110646-kardenwort-mpv/releases/tag/v1.48.10) 
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) 

A high-performance [mpv](https://mpv.io/) configuration specifically engineered for immersion-based language acquisition, optimized for the convenient consumption of **Dual-Subtitle** (DualSubs) content.

> **Attribution & Source**
>
> Developed and maintained by **Denis Novikov (voothi)** as part of the Kardenwort ecosystem.
>
> *   **Repository**: [Source Code](https://github.com/voothi/20260308110646-kardenwort-mpv)

> [!IMPORTANT]
> **Optimized Acquisition Environment**
>
> **Validated Setup:**
> *   **Platform**: Windows 11, macOS, Linux, Android (Termux).
> *   **Workflow**: Optimized for both merged `.ass` and separate `.srt` files.
> *   **Interface**: Distraction-free OSC (hidden by default).


## Table of Contents

- [Project Goals](#project-goals)
- [Distinctive Advantages](#distinctive-advantages)
- [Advanced Subtitle Workflow](#advanced-subtitle-workflow)
- [Intelligent Scripts](#intelligent-scripts)
  - [Universal Subtitle Search](#universal-subtitle-search)
  - [Karaoke-Safe Autopause](#karaoke-safe-autopause)
  - [Static Reading Mode (Drum Window)](#static-reading-mode)
  - [Anki Highlighting & Export](#anki-mining)
  - [Intelligent Range Selection & Copy](#intelligent-range-selection)
  - [Smart Spacebar](#smart-spacebar)
  - [Smart Font Scaling](#smart-font-scaling)
- [Immersion-Centric Keybindings](#immersion-centric-keybindings)
- [Configuration Guide (mpv.conf)](#configuration-guide-mpvconf)
- [Installation](#installation)
- [Development Analytics](#development-analytics)
- [License](#license)

---

## Project Goals

The primary objective of this suite is to provide a highly optimized environment for the **Extensive Acquisition** of languages through the convenient consumption of video content. 

This project is specifically designed for learners who work with **Dual Subtitles** (DualSubs)—where original target-language captions are paired with a secondary translation track.

### Core Objectives:
1.  **Dual-Subtitle Optimization**: Engineered to handle the visual and technical challenges of displaying two subtitle tracks (Original & Translated) in `.srt` or `.ass` formats simultaneously. 
2.  **Convenient Content Consumption**: Focuses on the *playback phase* of intensive acquisition. Every feature—from [Independent Shifting](#positional-flexibility) to [Smart Spacebar](#smart-spacebar)—is built to remove friction during long, high-volume immersion sessions.
3.  **YouTube Auto-Subtitle Handling**: Provides specialized tools like [Static Reading Mode](#static-reading-mode) to maintain linguistic context when dealing with poorly synchronized or lower-quality YouTube-extracted captions.
4.  **Local Offline Focus**: Aimed at a robust local-first workflow. Learners can download media and subtitles, prepare them using external tools, and then consume them offline with maximum stability and control.
5.  **Anki Workflow Core**: Deep integration with Anki/TSV databases. Highlighting, context extraction, and non-contiguous term matching are built-in native features, not just afterthoughts.

### Workflow Integration
While this project focuses on the **consumption** of material, it is designed to be the final step in a broader acquisition workflow:
- **Preparation**: For downloading and translating your material, we recommend companion tools like [voothi/subtitles](https://github.com/voothi/20251228104300-subtitles/).
- **Consumption**: Use this suite to engage with the prepared Dual-Subtitle content for extensive acquisition.

[Return to Top](#table-of-contents)

## Distinctive Advantages

This suite solves problems that standard video players and generic scripts ignore:
1.  **Dual-Layout Keybindings**: Native support for both English and Cyrillic keyboard layouts. Your hotkeys work flawlessly without needing to constantly switch your system input language.
2.  **Karaoke-Ready Autopause**: Unlike standard autopause scripts that stutter on `.ass` word-by-word highlights, this suite precisely scans for formatting tags to stop *only* when a phrase is complete.
3.  **Non-Intrusive OSD Design**: All status popups (Play/Pause, Layout, Visibility) are minimized and pushed to the **Left-Center** of the screen. Your visual field remains 100% clear.
4.  **ASS Mathematics Protection**: The suite dynamically sizes simple text, but completely respects the baked-in layout geometry of complex immersive video files.
5.  **Watch-Later Cleanliness**: Temporary visibility toggles for intense immersion sessions are explicitly excluded from `watch-later` saving, ensuring you never corrupt your clean baseline configuration.
6.  **[Static Reading Mode](#static-reading-mode)**: Converts the standard scrolling subtitle "drum" into a frozen, text-editor style viewport. Navigate, mouse-select, double-click to seek, and edge-scroll without the text flickering or moving under your cursor.
7.  <span id="positional-flexibility">**Positional Flexibility**</span>: Fine-grained vertical adjustment for both primary and secondary tracks (and their Russian layout equivalents). Manually resolve overlaps and tune your visual field without touching a configuration file.
8.  **Universal Fuzzy Search**: Instantly look up vocabulary and phrases across the entire subtitle file with an independent, non-intrusive overlay. Supports clipboard pasting and direct mouse selection.
9.  **Hardware-Accelerated Mouse Selection**: Click-and-drag text selection inside the Drum Window tracks your cursor at 60fps using native `mouse_move` hardware events rather than a polling timer.
10. **Intelligent Anki Integration**: Save vocabulary with a single click. High-recall matching ensures your saved words stay highlighted (Amber/Purple/Mixed) across the entire session. Implements **Multi-Pivot Grounding** (`Line:Word:TermPos`) to mathematically eliminate highlight bleed.
11. **Contextual Tooltips**: Peek at translations instantly via keyboard (`e`) or Right-Click (`RMB`) in the reading window.
12. **Scanner-Based Precision**: A robust state-machine parser handles complex German boundaries and protects "Original Form" subtitle spacing.
13. **Smart Stacking Engine**: Unified layout coordination for dual-track subtitles that restores manual positioning control while preventing visual overlap by default.
14. **Selection Priority**: Persistent multi-word selections (Ctrl + LMB) now take visual precedence over transient cursor highlights.
15. **Dynamic Source Discovery**: Automatically extracts YouTube/Source URLs from local metadata files (`.url`, `.txt`, `.md`) for zero-touch Anki metadata population.
16. **Chromatic Selection Theme**: Implements a "Warm vs. Cool" workflow using Gold for contiguous and Neon Pink for split-phrase selections.
17. **Hardware Interaction Shielding**: A bulletproof 150ms "interaction shield" that ignores mouse jitter and "ghost clicks" from remote control software (JoyToKey, etc.) immediately after keyboard commands.
18. **Multi-Layout Shortcut Lists**: All major command parameters now support space, comma, or semicolon separated lists. Map `t`, `е`, and `MBTN_LEFT` to the same action simultaneously in `mpv.conf`.
19. **Precision Context Verification**: Implements word-tokenized intersection for vocabulary matches, ensuring highlights persist through punctuation and formatting differences.
20. **Embedded Subtitle Support**: The Drum Window (Mode W) now supports internal/embedded subtitle tracks in MKV files, providing a consistent experience across all media formats.
21. **Footprint-based Precision Rendering**: Overhauled punctuation discipline with sub-token stack recalculation and 3-tier nesting gradients for superior visual hierarchical context.
22. **Zero-Overhead Periodic Sync**: Implements `mtime` + `size` fingerprinting to bypass expensive parsing and filesystem scanning for TSV and URL sidecars when data is unchanged.
23. **Sticky Column Navigation**: Vertical keyboard movement in the Drum Window now preserves horizontal OSD position, snapping to the closest word on the target line for a professional, editor-like experience.
24. **Freeze-Proof Export Engine**: A hardened string search logic with mandatory forward-progress guards and empty-term validation to eliminate UI freezes during selection.
25. **Contiguous Multi-Line Selection**: Refined selection logic that reliably maintains the highlighting anchor across subtitle line boundaries, enabling seamless "mass selection" via keyboard navigation.
26. **Configurable Jump Distances**: Fully adjustable navigation speed. Users can customize the exact number of words or lines jumped during Ctrl-boosted navigation via `mpv.conf`.

[Return to Top](#table-of-contents)

## Advanced Subtitle Workflow

Instead of relying on mpv's native dual-subtitle loading (which often strips formatting), this configuration advocates for a **Merged .ass Workflow**:

1.  **Multiple Tracks**: Use [Subtitle Edit](https://github.com/SubtitleEdit/subtitleedit) to merge target and native language tracks.
2.  **Custom Positioning**: Bake positioning (Top/Center/Bottom) and colors directly into a single `.ass` file.
3.  **Visual Protection**: Our `mpv.conf` respects the internal mathematics of the `.ass` file, ensuring margins and styles are never overridden by the player.

[Return to Top](#table-of-contents)

## Intelligent Scripts

### <span id="universal-subtitle-search"></span>Universal Subtitle Search
A high-performance navigation overlay that decouples content lookup from playback.
- **Cyrillic & German Parity**: Fully case-insensitive Russian search support and native input for German umlauts (`äöü`) and the eszett (`ß`).
- **Professional Editing**: Support for `Ctrl+A` (Select All) and Bash-style `Ctrl+W` (Delete Word).
- **Clipboard Integration**: Paste queries directly with `Ctrl+V` (EN) or `Ctrl+М` (RU).
- **Hit Highlighting**: Elegant visual feedback highlighting matching characters (Subsequence-aware). **Fully configurable** via the `Options` table.
- **Interactive Dropdown**: Navigate results via arrow keys or click directly on an item with the mouse to seek. **Styling (colors/bolding)** is now user-adjustable.
- **Dynamic OSD Support**: Automatically overrides the global `osd-border-style` (e.g., from `background-box`) while active to ensure a clean, readable interface on top of the custom search panels.
- **Hard-Sync Logic**: Every jump uses explicit `seek absolute+exact` commands to ensure primary and secondary tracks are perfectly aligned.
- **Toggle**: `Ctrl + F` (English) or `Ctrl + А` (Russian).

#### **How the Search Engine Works**
The search bar uses a multi-stage **Keyword-Based Fuzzy Matching** engine:
1.  **Tokenization**: Your query is split into individual keywords (separated by spaces).
2.  **Order-Independent Matching**: The engine finds results containing all keywords, regardless of the sequence you typed them in.
3.  **"Really Fuzzy" Subsequence**: Each keyword matches if its letters appear in the correct order within a word, even if other letters are in between (e.g., `mne` matches **m**a**n**ag**e**).
4.  **Hit Highlighting**: Character matches are elegantly bolded and colored in the result list.
5.  **Relevance Ranking**:
    -   **Exact Match**: Literal matches are prioritized first.
    -   **Compactness Bonus**: Higher priority is given to "dense" matches where letters are clustered within a single word rather than scattered across the whole line.
    -   **Structural Bonus**: Matches at the start of a subtitle line receive a specific weight.

### Karaoke-Safe Autopause
Advanced pause logic designed specifically for immersion students using `.ass` karaoke-formatted subtitles.
- **End of Phrase**: By default, it pauses only when the sentence is finished (detecting the end of the `{\c}` tag sequence).
- **Word by Word**: Toggle with `K` to pause after every word highlighted in your karaoke tracks.
- **Dual-Track Aware**: Intelligently tracks timings in both primary and secondary tracks to ensure you never miss a phrase.
- **Toggle**: `P` (English) or `З` (Russian).

### <span id="static-reading-mode"></span>Static Reading Mode (Drum Window)
A high-performance rolling context engine that has evolved into a robust **Static Reading Mode** for in-depth immersion analysis.
- **Advanced Mouse Selection**: Experience text-editor smooth interactions. Click and drag (`LMB`) to instantly highlight ranges, or `Shift+Click` to extend. Hardware-accelerated for 60fps tracking.
- **Actionable Text**: Double-Click any subtitle word to instantly seek video playback to that exact phrase and re-center the viewport.
- **Stationary "Book Mode"**: Toggle with **`b`** to lock the viewport. Navigating through lines or selecting words won't cause the window to scroll or flicker, providing a stable, reading-focused experience.
- **Selection Persistence**: Manual seeks via `a`/`d` no longer clear your yellow highlight, allowing you to check context and return to your pending export line.
- **"Original Form" Display**: Toggle `dw_original_spacing` to perfectly mirror any subtitle's whitespace and character-stream formatting without sacrificing word-level selection.
- **Contextual Tooltips**: Press **`e`** or **Right-Click** on any line to instantly see a translation hint. In "Hover Mode" (`n`), hints appear automatically as you scan the text.
- **Static Viewport**: The viewport remains stable while navigating via arrows, providing a flicker-free environment for reading and selection.
- **Boundary-Aware Sliding Window**: The viewport intelligently shifts at track edges to maintain consistent line density and vertical positioning.
- **Interaction Shielding & Stability**: Features a 150ms shield that silences the mouse arrow following keyboard navigation, preventing accidental pointer "jumps" when using remote controls.
- **Active Line Visibility**: The current playback line is highlighted in a **high-contrast bright blue**, ensuring it remains perfectly legible against the window's dark theme.
- **Sticky Column Navigation**: Vertical movement (Arrows Up/Down) now preserves the horizontal OSD position, mimicking the VSCode carriage transition for more predictable keyboard navigation.
- **Performance Layout Cache**: A structure-aware caching engine that eliminates redundant OSD calculations during mouse movement, ensuring a smooth 60fps interaction experience.
- **Toggle**: `W` (English) or `Ц` (Russian).

### <span id="anki-mining"></span>Anki Highlighting & Export
A specialized subsystem that bridges the gap between immersion and flashcard creation.
- **High-Recall Highlighting**: Saved vocabulary and phrases are automatically highlighted across the entire video. 
  - **Orange**: Contiguous word sequences.
  - **Purple**: Split-word constructs (e.g., separable verbs).
  - **Mixed**: Blended colors for overlapping terms.
- **Precision Grounding**: Uses a comprehensive coordinate system (`Line:Word:TermPos`) to anchor highlights to specific scenes, preventing common words from bleeding across unrelated segments.
- **Multi-Word Selection**: 
  - `Ctrl + LMB`: Accumulate individual words into a yellow pending selection.
  - `MMB`: Commit the selected set as a highlight and export it to your TSV database.
- **Automatic Sanitization**: Strips leading/trailing punctuation and bracketed metadata (e.g. `[Musik]`) to ensure cards are optimized for dictionary matching. Smart joiners preserve hyphens/slashes in German compounds.
- **Drag-to-Pair (Range Conversion)**: High-performance mining upgrade. Contiguous yellow selection ranges can now be converted into discrete paired selection sets (Pink) in a single action via keyboard (`t`) or Ctrl+Drag.
- **Dynamic Context**: The engine intelligently scans surrounding lines to capture grammatically complete sentences for your flashcards.
- **Instant Record Access**: Press **`o`** within the Drum Window to instantly open your active TSV database in your default editor.
- **Dynamic Source Discovery**: Automatically scans for `.url`, `.txt`, or `.md` files in the media folder to extract `SourceURL` metadata for Anki exports.
- **Zero-Latency Mining**: In-memory row injection provides instantaneous feedback when saving words, bypassing the performance penalty of full TSV re-parsing.

### <span id="intelligent-range-selection"></span>Intelligent Range Selection & Copy
A sophisticated extraction tool that supports substring and multi-line range selection.
- **Range Selection**: Hold **`Shift`** with navigation keys to select exact word ranges or multiple consecutive subtitle lines.
- **Substring Copy**: `Ctrl+C` aggregates only the highlighted words into a clean, format-free clipboard export.
- **Symmetrical Traversal**: Intelligently leaps across dual-track layouts to retrieve pure target-language lines.
- **Copy Modes**: Toggle between Target text and Translation chunks (Toggle: `Z` / `Я`).
- **Context expansion**: Request surrounding sentences to export chronological paragraphs (Toggle: `X` / `Ч`). Requires separate subtitle files.

### Smart Spacebar
A custom key handler that distinguishes between quick taps and long holds.
- **Play While Held**: Pressing and holding `SPACE` bypasses ALL autopause rule sets (Word-by-word and End-of-phrase). The video plays smoothly as long as the key is down.
- **Tap to Toggle**: Quickly tapping `SPACE` (< 200ms) functions as a standard Play/Pause toggle.

### Smart Font Scaling
Ensures that your immersion material remains perfectly readable regardless of window size, while protecting complex layouts.
*   **For `.srt` Files**: Dynamically adjusts subtitle scaling so text doesn't become tiny on large monitors or giant in small windows. Includes a **Softer Scaling** formula to prevent aggressive wrapping.
*   **For `.ass` Files**: Intelligently detects the Advanced SubStation format and bypasses scaling, allowing the file's internal positioning mathematics to render flawlessly.
*   **Configurable**: Enable/Disable or tune the "scaling strength" directly in `mpv.conf`.

[Return to Top](#table-of-contents)

## Immersion-Centric Keybindings

Optimized `input.conf` for rapid review, featuring **dual-layout support** (English/Cyrillic).

| Key (EN) | Key (RU) | Action |
|---|---|---|
| `RIGHT` / `LEFT` | `RIGHT` / `LEFT` | Exact **2-second** seek forward / backward |
| `A` / `D` | `Ф` / `В` | Exact **2-second** seek forward / backward (Window Mode / Global) |
| `a` / `d` | `ф` / `в` | **Seek** to previous / next subtitle line |
| `q` / `Q` | `й` / `Й` | **Quit** / Quit and save position |
| `SPACE` | `SPACE` | **Smart Space**: Hold to Play, Tap to Toggle Pause |
| `m` | `ь` | Toggle **Mute** |
| `0` / `9` | `0` / `9` | Adjust **Volume** (Up / Down) |
| `[` / `]` | `х` / `ъ` | Decrease / Increase **Playback Speed** (10%) |
| `{` / `}` | `Х` / `Ъ` | Halve / Double **Playback Speed** |
| `BS` | `BS` | **Reset Playback Speed** (Set to 1.0) |
| `.` / `,` | `ю` / `б` | Frame Step Forward / Backward |
| `f` | `а` | Toggle **Fullscreen** |
| `W` / `E` | `Ц` / `У` | **Panscan** (Zoom Out / In) |
| `r` / `t` | `к` / `е` | Adjust **Primary** Position (Up / Down) |
| `Shift+R` / `Shift+T` | `К` / `Е` | Adjust **Secondary** Position (Up / Down) |
| `j` | `о` | **Cycle Secondary Track** (Translation) |
| `s` | `ы` | Toggle Subtitle Visibility (Styled OSD) |
| `e` | `у` | **Toggle Tooltip** (Reading Mode Only) |
| `y` | `н` | Toggle Secondary Position (**Top ↔ Bottom**, SRT only) |
| `c` | `с` | Toggle **Drum Mode** (Legacy Multi-line Context) |
| `w` | `ц` | Toggle **Static Reading Mode** (Drum Window) |
| `b` | `и` | Toggle **Book Mode** (Static Viewport Lock) |
| `n` | `т` | Toggle **Hover Tooltips** (Reading Mode) |
| `o` | `щ` | **Open Record File** (Active TSV database) |
| `Ctrl+f` | `Ctrl+а` | Toggle **Universal Subtitle Search** Overlay |
| `Ctrl+a` | `Ctrl+ф` | **Select All** (Inside Search HUD) |
| `Ctrl+w` | `Ctrl+ц` | **Delete Word** (Bash-style, Search HUD) |
| `LMB (Drag)` | `LMB (Drag)` | **Select Text** (Click and drag to highlight) |
| `LMB (Double)` | `LMB (Double)` | **Seek** to clicked subtitle line |
| `Ctrl + LMB` | `Ctrl + LMB` | **Multi-Word Selection** (Accumulate individual words) |
| `Ctrl+Shift+LMB` | `Ctrl+Shift+LMB` | **Extend Pink Selection** (Paired highlights) |
| `MMB` | `MMB` | **Commit & Export** (Release to save to Anki/TSV) |
| `Shift + UP/DN` | `Shift + В/Н` | Multi-line Range Selection (Arrows) |
| `Ctrl + Shift + LEFT/RIGHT` | `Ctrl+Shift+Л/П` | Block-word Selection (Navigation) |
| `Ctrl + Shift + UP/DOWN` | `Ctrl+Shift+В/Н` | Multi-line Jump Selection |
| `Ctrl + UP/DN` | `Ctrl + В/Н` | Viewport Scroll (Matches Mouse Wheel) |
| `Ctrl+c` | `Ctrl+с` | **Copy Range** (Exact highlighted words to clipboard) |
| `x` | `ч` | Toggle **Context Copy** (Include surrounding lines) |
| `z` | `я` | Cycle **Copy Mode** (Foreign ↔ Translation) |
| `TAB` | `TAB` | Cycle OSC Visibility (**Always ↔ Auto ↔ Never**) |
| `p` | `з` | Toggle **Autopause** (ON/OFF) |
| `k` | `л` | Toggle **Karaoke Mode** (Word-by-Word / End-of-Phrase) |
| `S` | `Ы` | Take a **Screenshot** |

[Return to Top](#table-of-contents)

---

## Configuration Guide (mpv.conf)

The project now uses a centralized configuration model. All core script behaviors (AutoPause, Drum Mode, Search HUD) are controlled directly from `mpv.conf` using the `lls-` prefix.

### Key Operational Settings:
- **`sub-align-y=bottom`**: Standardizes the layout for drum mode.
- **`secondary-sub-pos=10`**: Places secondary tracks at the top of the frame.
- **`sub-pos=95`**: Places primary subtitle tracks near the bottom.
- **`sub-ass=yes`**: Enables high-quality subtitle rendering for native karaoke support.
- **`osc=no`**: Removes visual clutter from the screen.
- **`save-position-on-quit=yes`**: Pick up your immersion session exactly where you left off.

### Centralized Script Controls:
- **`script-opts-append=lls-autopause_default=yes`**: Toggle autopause at session start.
- **`script-opts-append=lls-dw_font_name=Consolas`**: Unified font for reading modes.
- **`script-opts-append=lls-anki_sync_period=5`**: Frequency of TSV database reloads.
- **`script-opts-append=lls-dw_vline_h_mul=0.87`**: Tunable vertical hit-test multiplier.
- **`script-opts-append=lls-book_mode=no`**: Stationary viewport lock (default).
- **`script-opts-append=lls-dw_original_spacing=yes`**: Perfectly mirror source subtitle formatting.
- **`script-opts-append=lls-copy_default_mode=A`**: Set the default clipboard target.

### Anki Field Mapping
The suite leverages an external `anki_mapping.ini` to decouple metadata from logic. Users can define custom fields, static literals, and language-specific TTS flags for zero-touch Anki imports.

### Switchable Layout Modes:
The configuration supports a **Mode-based architecture**. You can define and switch between different font size calibrations (e.g., MODE 1 for size 30, MODE 2 for size 34) directly in `mpv.conf` to ensure hit-testing remains pixel-perfect regardless of your chosen font scale.

(Refer to the heavily commented `mpv.conf` file in the repository for a complete list of all 35+ adjustable parameters and functional templates.)

[Return to Top](#table-of-contents)

## Installation

1.  **Locate Config**: Open `%APPDATA%\mpv\` (Windows).
2.  **Deploy**: Copy `mpv.conf`, `input.conf`, and the `scripts/` folder into the directory.
3.  **Self-Documenting Hotkeys**: `input.conf` is fully commented with detailed explanations for every key. Refer to it as your primary manual.
4.  **Scripts**: The core logic is powered by the unified `lls_core.lua` script. Ensure it's saved with **UTF-8** encoding.
5.  **Restart**: Relaunch mpv to apply the optimized v1.48.10 settings.

[Return to Top](#table-of-contents)

## Development Analytics

This project maintains a data-driven approach to development tracking. We use a custom clustering algorithm to estimate human effort from git commitment intervals.

- **Project Inception**: March 8, 2026
- **Current Maturity**: ~882 Commits (v1.48.10)
- **Intensity Profile**: 5.7 Commits/Hour 

To repeat the analysis on your local machine, use the provided Python tool:
```powershell
git log --pretty=format:"%ad" --date=iso-strict | python docs/scripts/analyze_repo.py
```

[Return to Top](#table-of-contents)

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

[Return to Top](#table-of-contents)
