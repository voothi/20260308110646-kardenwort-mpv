# Release Notes - v1.60.0 (FSM Stabilization & Spec-Driven Testing)

**Date**: 2026-05-07
**Version**: v1.60.0
**Implementation ZIDs**: 20260506090626, 20260506095404, 20260506103358, 20260506135440, 20260506164500, 20260506190022, 20260506195038, 20260506223500, 20260506232017, 20260507001035, 20260507090243, 20260507102212, 20260507163304

## Highlights

### 🛡️ **FSM Architecture & Specification Hardening**
- **Architecture Validation**: Conducted a surgical audit of the entire `lls_core.lua` FSM logic, fixing regressions and discrepancies between the specifications (`fsm-architecture`) and the actual code.
- **Selection Priority Simplification**: Refactored the context copy logic into the FSM state machine. Active manual selections (Pink Set, Yellow Range, Yellow Pointer) now reliably override Context Copy mode, providing deterministic extraction regulated via the `Esc` key.
- **Spec-Gap Remediation**: Resolved "sticky" interaction edge-cases relating to search hijacking, configuration-bound secondary positioning, and DOCKED neutrality.

### 🥁 **Drum Mode Unification & Interaction**
- **Unified Wheel Scrolling**: Synchronized Mouse Wheel scrolling in Drum Mode to match Drum Window (DW) mode. The wheel now scrolls the text content naturally without advancing the playback position, creating a clean separation between track control and text navigation.
- **Dual-Track Scroll Sync**: When scrolling the main (bottom) subtitle track in Drum Mode, the upper (secondary) subtitles now scroll in perfect synchronization, including accurate hit-zone lighting and highlighting.
- **Tooltip Key Parity**: Brought DW translation tooltip functionality (`e` / `RMB`) directly into Drum Mode for the primary subtitle window, providing feature parity across both immersion interfaces.

### ⏯️ **Playback Automation & Boundary Precision**
- **Natural Progression Padding**: Corrected a visual skipping issue in Autopause `PHRASE` mode. Overlapping padding ranges at the start and end of subtitles are now correctly prioritized so that audio recording captures the entire phrase organically without premature visual jumping.
- **MOVIE Mode Boundary Fix**: Hardened Autopause `MOVIE` mode to guarantee that subtitles are played exactly along their strict `.srt` boundaries, preventing truncated audio captures at the tail end of lines.
- **Seek-Repeat Restoration**: Restored smooth, continuous navigation when holding `Shift+a` or `Shift+d`.

### 🧪 **Acceptance Testing & Test Infrastructure**
- **Spec-Driven Automated Testing**: Built a robust, cross-platform acceptance testing infrastructure utilizing headless `mpv` execution via IPC (`mpv_session.py`, `mpv_ipc.py`).
- **Concurrent Deadlock Fixes**: Re-engineered Windows IPC with `ctypes` (`_WinPipe`) using overlapped I/O to eliminate CRT file-locking deadlocks during asynchronous reads and writes.
- **Dual-Subtitle Desync Fix**: Discovered and fixed a 1-index desynchronization bug between primary and secondary tracks caused by overlapping padding windows. Introduced `FSM.SEC_ACTIVE_IDX` as a secondary tracking sentinel to ensure both tracks align flawlessly during continuous playback and seeks.

---

# Release Notes - v1.58.50 (YouTube-Style Seek & Immersion Hardening)

**Date**: 2026-05-06
**Version**: v1.58.50
**Implementation ZIDs**: 20260506001349, 20260506000713, 20260505162601, 20260505150404, 20260505145046, 20260505143734, 20260505121439, 20260505115453

## Highlights

### ⏩ **YouTube-Style Cumulative Seek OSD**
- **Dynamic Accumulator**: Implemented a progressive seek OSD that mirrors modern streaming platforms. Rapid seeking now displays a cumulative total (`+2`, `+4`, `+6`) instead of redundant individual messages.
- **Directional Feedback**: OSD messages are now alignment-aware, appearing on the right (forward) or left (backward) of the screen to provide intuitive spatial orientation.
- **Configurable Templates**: Fully parameterized OSD messages via `seek_msg_format` and `seek_msg_cumulative_format`, allowing users to customize prefixes and value representations.

### 🛡️ **Immersion Engine Hardening & OSD Refinement**
- **Surgical Input Silencing**: Hardened the immersion state machine to block redundant positioning keys (`r`, `t`, `R`, `T`) when the Drum Window or Drum Mode is active, preventing accidental layout shifts during study.
- **Descriptive Minimalism**: Refactored all system status messages to include descriptive prefixes (e.g., `Drum Mode: ON`, `Autopause: OFF`) while stripping technical noise.
- **Staged Reset (Esc)**: Refined the `Esc` key logic into a non-destructive 3-stage reset (Pink Set → Yellow Range → Yellow Pointer) that preserves the Drum Window state, preventing cyclic mode toggling.
- **UI Shortening**: Long OSD prefixes (e.g., `Secondary Subtitles:`) have been shortened (e.g., `Secondary Sub:`) to reduce visual clutter.

### 🔄 **Cyclic Subtitle Navigation**
- **Wrap-Around Seeking**: Manual navigation via `a` and `d` now supports wrap-around between the first and last subtitle tracks.
- **Visual Confirmation**: Added clear OSD feedback when wrapping occurs (`Wrapped to START` / `Wrapped to END`).
- **Boundary Hardening**: Implemented robust guards to prevent state-machine inconsistencies at track edges and during native OSC timeline seeks.

### 🛠️ **Functional Improvements & Fixes**
- **Filtered Secondary Cycling**: Refined `Shift+c` logic to only cycle through external subtitle tracks, explicitly excluding the primary subtitle stream to prevent state conflicts.
- **Configurable Startup**: Introduced `immersion_mode_default` (`PHRASE` vs `MOVIE`) to allow users to specify their preferred starting state in `mpv.conf`.
- **Interactivity Guard**: Disabled mouse-based auto-scroll in non-Drum Mode to prevent unintended selection expansion on standard OSD subtitles.
- **SRT Parser Hardening**: Implemented robust whitespace normalization to handle malformed SRT files with padded block separators.
- **State Synchronization**: Hardened immersion mode transitions to prevent "Jerk Back" seeking during phantom boundary detection.

---

# Release Notes - v1.58.49 (Drum Mode Cursor Fix & Window Persistence)

**Date**: 2026-05-04
**Version**: v1.58.49
**Implementation ZIDs**: 20260504033538, 20260504035338

## Highlights

### 🎯 **Universal Drum Mode Cursor Sync**
- **Authoritative Tracking**: Fixed a critical state desync where the subtitle clipboard focus (`FSM.DW_CURSOR_LINE`) would become "stuck" during continuous playback in Drum Mode.
- **Global Heartbeat Integration**: Migrated the cursor synchronization logic from the localized Drum Window loop to the global `master_tick` heartbeat. This ensures the internal copy pointer always perfectly matches the active on-screen subtitle across all display modes.
- **Improved Follow Logic**: Selection resets and viewport center updates are now unified, guaranteeing that `Ctrl+C` captures the currently playing line even when the dedicated reading window is closed.

### 🖼️ **Interface & Persistence**
- **Window Persistence**: Added `keep-open=yes` to the standard configuration. The mpv window will now remain open at the last frame when a video finishes, preventing unexpected application closure during intensive study sessions.

---

# Release Notes - v1.58.48 (Subtitle Replay Loop & Hotkey Optimization)

**Date**: 2026-05-04
**Version**: v1.58.48
**Implementation ZIDs**: 20260504021904, 20260504023848

## Highlights

### 🔄 **Adaptive Subtitle Replay & Looping**
- **Mode-Aware Replay Engine**: Introduced a dual-mode replay system (triggered via `s` / `ы`) that adapts to the active workflow. In **Autopause OFF** (Streaming Mode), it toggles persistent loops. In **Autopause ON** (Manual Mode), it executes one-shot replays.
- **Arming Guard & Delayed Seeks**: Prevent mid-subtitle interruptions. Replay commands are now "armed" and executed precisely at subtitle boundaries, ensuring a fluid and professional immersion experience.
- **Hardware Ghosting Workaround**: Implemented a "Sticky Hold" finite state machine (FSM) recovery mechanism to defeat hardware-level keyboard ghosting that previously dropped Spacebar signals when the replay key was pressed.
- **Spacebar Loop Override**: Users can now break out of a persistent loop by simply holding the Space key at the loop boundary, enabling seamless transitions to the next phrase.

### ⌨️ **Hotkey Layout Optimization**
- **Surgical Key Reshuffle**: Optimized the primary control layout to prioritize the new Replay functionality while maintaining accessibility for core toggles.
  - `s` / `ы`: Subtitle Replay (formerly Sub Visibility).
  - `c` / `с`: Subtitle Visibility (formerly Drum Mode).
  - `x` / `ч`: Drum Mode (formerly Copy Context).
  - `W` / `Ц`: Copy Context (formerly on `x`).
- **Autopause Ergonomics**: Migrated the master Autopause toggle to `S` / `Ы` (formerly `p` / `з`), centralizing playback automation controls around the home row.

### 🛡️ **Compliance & Synchronization Audit**
- **Spec-Driven Hardening**: Formally archived and synchronized the `subtitle-replay-loop` specification.
- **Russian Layout Parity**: Ensured 100% functional parity for the new control scheme across both English and Russian keyboard layouts.

---

# Release Notes - v1.58.42 (Layout-Agnostic Hotkeys & Collision Hardening)

**Date**: 2026-05-03
**Version**: v1.58.42
**Implementation ZIDs**: 20260503203618, 20260503212729

## Highlights

### ⌨️ **Layout-Agnostic Hotkey Expansion**
- **Automatic Multi-Layout Registration**: Introduced a dynamic expansion engine (`expand_ru_keys`) that automatically registers Russian layout equivalents for every configured English binding. Users no longer need to manually specify dual-layout shortcuts in `mpv.conf`.
- **Comprehensive Cyrillic VK Mapping**: The GoldenDict trigger engine now natively supports the full Cyrillic alphanumeric set, mapping them to their physical Virtual Key (VK) counterparts for reliable dictionary lookups regardless of the active system layout.
- **Multi-Delimiter Hotkey Configuration**: Configuration strings for dictionary triggers now support space, comma, or semicolon as delimiters, allowing for sequences of backup hotkeys.

### 🛡️ **Shift-Modifier & Collision Hardening**
- **Surgical Shift Normalization**: Eliminated "false positive" triggers on Windows where unshifted Russian keys (e.g., `у`) would incorrectly fire Shift-modified actions. The engine now uses strict case-parity, mapping `Shift+e` directly to the uppercase `У` character to align with mpv's internal input table.
- **Explicit vs. Implicit Shift Guarding**: Refined the expansion logic to strictly differentiate between explicit `Shift+` modifiers and implicit shift via uppercase characters, ensuring unambiguous binding resolution.
- **Simplified Configuration Schema**: Cleaned up default `mpv.conf` options by removing redundant manually-defined Cyrillic hotkeys, relying entirely on the hardened dynamic expansion engine.

### 🔦 **Diagnostic Observability & Health**
- **Granular Trigger Logging**: Added high-resolution diagnostic tracing that records both the physical key pressed and the logical script-binding triggered (at `debug` log level), significantly simplifying the debugging of complex hotkey conflicts.
- **Enhanced Configuration Health-Check**: Updated the startup diagnostic module to validate and report layout-agnostic binding states, ensuring a professional and stable "First Run" experience.

---

# Release Notes - v1.58.38 (Hardened Clipboard Bridge & Precision Selection)


**Date**: 2026-05-03
**Version**: v1.58.38
**Implementation ZIDs**: 20260502211505, 20260502223822, 20260503131410, 20260503190627, 20260503192335

## Highlights

### 📋 **Hardened Clipboard Bridge & Reliability**
- **Triple-Tier Decoupled Copy Engine**: Introduced a sophisticated clipboard architecture that separates standard copying from dictionary lookups (Popup vs. Main window).
- **Global Trigger Lock**: Implemented a time-based recursion guard to prevent AHK-generated `^c` loops, ensuring clean synchronization without redundant UI triggers.
- **Multi-Method Trigger Engine**: High-performance Win32 bridge using PowerShell (Add-Type) or instantaneous Python/ctypes injection, reducing lookup latency to near-zero.
- **Configurable Retry Logic**: Exposed `win_clipboard_retries` and `win_clipboard_retry_delay` for fine-tuning Windows clipboard performance and mitigating resource locks.
- **OSD Stabilization**: Added a configurable `copy_osd_cooldown` to suppress redundant notification flashes during rapid clipboard operations.

### 🎯 **Precision Selection & Hit-Zone Hardening**
- **Prioritized Selection in Context Copy**: Manual selections (Pink Set, Yellow Range, or Yellow Pointer) now take absolute priority over "Context Copy" mode. This allows for precise term extraction even when multi-line context harvesting is active, regulated via `Esc` stages.
- **Regulated Context Copy via Esc**: Refined the `Esc` key logic to clear manual selections first, allowing for a seamless transition between precise term copying and contextual harvesting.
- **Ghost Hit-Zone Elimination**: Fixed "Interaction Leakage" by explicitly clearing tooltip hit-zones upon dismissal. This prevents "dead zones" in the Drum Window where inactive tooltips would intercept mouse clicks.
- **Hit-Test Guarding**: Added secondary validation to the tooltip hit-test engine, ensuring interaction is only possible when a tooltip is logically active.

---

# Release Notes - v1.58.30 (Session Resumption & Smart Diagnostics)

**Date**: 2026-05-02
**Version**: v1.58.30
**Implementation ZIDs**: 20260502005934, 20260502082941, 20260502093650, 20260502104026, 20260502135022, 20260502151844

## Highlights

### 🔄 **Intelligent Session Management**
- **Automated Last-Session Resumption**: Implemented a decoupled session manager that tracks and restores the last active media path upon a blank application launch.
- **High-Resolution Session OSD**: Utilizes a 1920x1080 virtual canvas for consistent, premium typography and layout synchronization during session recovery.
- **Linguistic Prioritization**: Custom sort predicate ensures primary target languages remain the visual anchor during session OSD rendering.

### 🛡️ **Smart Diagnostics & Logging**
- **Level-Aware Logging Interface**: Unified `Diagnostic` module with `info`, `warn`, `error`, `debug`, and `trace` levels, mapped to native MPV messaging.
- **Console Spam Elimination**: Intelligent log deduplication prevents repetitive messages from background tasks and configuration errors.
- **Startup Health-Check**: Consolidates keybinding and configuration validation into a single, professional summary reported exactly once per session.
- **Layout-Agnostic Debugging**: Native binding for `ё` ensures the debug console is accessible regardless of the active keyboard layout.

### 🥁 **Drum Window Navigation Refinement**
- **Word-Only Vertical Navigation**: UP/DOWN keys now strictly target words and skip lines containing only punctuation, eliminating "disappearing pointer" issues.
- **Intelligent Vertical Entry**: Multi-line subtitles are now visual-line-aware, with deterministic landing logic (top for DOWN, bottom for UP jumps).
- **Viewport Tracking**: Horizontal word jumps now trigger automatic viewport scrolling, ensuring the cursor remains visible during rapid navigation.
- **Unified Layout Engine**: `ensure_sub_layout` provides a single point of truth for tokenization and wrapping across all rendering modes (SRT, Drum, DW, Tooltip).

### 🎨 **Aesthetic Calibration & Highlight Hardening**
- **Surgical Highlight Visibility**: Forced full-token coloring for manual user actions (Yellow/Pink) ensures unambiguous focus on punctuation and symbols while maintaining minimalist aesthetics for database matches.
- **Blooming Elimination**: Highlights now utilize opaque black borders (`\3a&H00&`) to eliminate blurring effects on high-intensity colors.
- **Mandatory Weight Reset**: Decoupled selection weights from global styles, enforcing a "Premium" regular weight (`\b0`) for manual selections.
- **Parameterized Formatter**: Enhanced `format_highlighted_word` to maintain visual context and prevent opacity regressions across complex rendering loops.

### 📚 **Terminology & Historicity Standardization**
- **Project Ground Truth**: Established a centralized Historicity and Terminology Specification to reconcile legacy naming (e.g., Reel → Drum, Yellow → Gold).
- **Dual-Notation Color Specs**: Mandatory BGR (mpv-native) and RGB (standard) hex notation for all documentation and code comments.
- **Evolution Ledger**: ZID-anchored tracking of terminology transitions to ensure architectural integrity and AI consistency.

### 🔧 **Windows Stability Fixes**
- **Robust Clipboard Logic**: Implemented an exponential backoff retry loop for PowerShell `Set-Clipboard` operations to mitigate system-level resource locks.

---

# Release Notes - v1.58.18 (Search HUD Revolution & Tooltip Sync)


**Date**: 2026-05-02
**Version**: v1.58.18
**Implementation ZIDs**: 20260501131000, 20260501154851, 20260501160807, 20260501163905, 20260501165217, 20260501172103, 20260501195000, 20260501234125, 20260502002407

## Highlights

### 🔦 **Search HUD Revolution**
- **Dynamic Multi-Line Wrapping**: Overhauled the Search HUD (Ctrl+F) with a token-aware wrapping engine. Both search queries and results now flow naturally across multiple lines, eliminating visual "bleeding" and overlaps.
- **Synchronized Hit-Testing**: Introduced `FSM.SEARCH_HIT_ZONES` for pixel-perfect mouse interaction. Click targets now dynamically track the visual position of wrapped results, eliminating "click drift."
- **Adaptive UI Layout**: The results dropdown now calculates its vertical offset based on the actual height of the wrapped query block, ensuring a seamless and responsive interface.
- **"Premium" Aesthetic Sync**: Synchronized the Search HUD with the v1.58.0 baseline, implementing synchronized transparency (`\3a`, `\4a`) and borderless rendering for a sleek, modern look.

### 🥁 **Drum Window Tooltip Evolution**
- **Translation Word-Wrapping**: Implemented a sophisticated wrapping engine for the DW translation tooltip (Russian `у` / English `e`). Long translations are now gracefully wrapped to a 1400px maximum width.
- **Full Bidirectional Pointer Sync**: Achieving 100% selection parity. Yellow Pointers and Pink Selection Sets are now bi-directionally synchronized between the primary subtitle and the translation tooltip.
- **Surgical Tooltip Highlights**: The tooltip now utilizes the project's surgical highlighting model, colorizing alphanumeric tokens while preserving punctuation fidelity.
- **High-Performance O(1) Cache**: Introduced `DW_TOOLTIP_DRAW_CACHE` to ensure zero UI latency during mouse movement and rapid navigation.

### 🛡️ **Interaction Hardening & UX Stability**
- **4-Stage Context-Aware Escape**: Refined the `Esc` key behavior into a sequential 4-stage logic: clear Pink Set → clear Yellow Range → clear Yellow Pointer → Exit. This eliminates the redundant extra-press regression for single-word highlights.
- **Interaction Shield**: Standardized a 50ms "interaction shield" for search results to suppress hardware-level jitter and "ghost clicks" immediately following keyboard commands.
- **Mode-Specific Calibration**: Introduced independent color and boldness calibration for manual selections, allowing users to decouple the luminance of manual focus from database match indicators.
- **Flicker-Free "Quick-View"**: RMB-hold tooltips now implement "Sticky Quick-View" logic, maintaining visibility even when the cursor passes through empty gaps between subtitle blocks.

### 🎨 **Aesthetic Calibration Sync**
- **Uniformity Alignment**: Standardized ASS rendering tags (`\3c`, `\4c`, `\3a`, `\4a`) across SRT, Drum, DW, and Search modes to eliminate visual "blooming" and artificial font thickening.
- **Hardened Configuration**: Consistently synchronized all Search HUD styling parameters in `mpv.conf`, including transparency, font weights, and border sizing.

---

# Release Notes - v1.58.0 (Hardened Performance & Verbatim Export)

**Date**: 2026-05-01
**Version**: v1.58.0
**Implementation ZIDs**: 20260428075210, 20260428192102, 20260429000301, 20260429005929, 20260429012045, 20260429013212, 20260429015128, 20260429022653, 20260429125303, 20260429130826, 20260429133044, 20260429142144, 20260429144946, 20260429151207, 20260429185737, 20260429195210, 20260429212717, 20260430183833, 20260430233400, 20260501005019, 20260501013716, 20260501015631, 20260501023103, 20260501093901, 20260501100842, 20260501103700, 20260501105900, 20260501111725, 20260501115216

## Highlights

### 🚄 **Architectural Hardening & Performance**
- **Massive Pipeline Audit**: Conducted a comprehensive hardening of the `lls_core.lua` rendering engine. Introduced O(1) performance invariants for character scanning and character-class lookup, ensuring fluid OSD interaction even with massive subtitle files.
- **Cache Integrity Enforcement**: Hardened `flush_rendering_caches()` with mode-specific invalidation sentinels (Drum vs. Normal) and active `script-opts` observation. This eliminates stale UI output and OSD-drift regressions.
- **Hot-Path Optimization**: Migrated core loops to `ipairs()`-based iteration and implemented token-level highlight memoization, significantly reducing CPU overhead during high-frequency subtitle updates.
- **Spec-Synchronized Performance**: Formally archived and synchronized 29 performance-driven OpenSpec changes into the project's canonical specification set.

### 📋 **Absolute "Verbatim" Export Fidelity**
- **Verbatim Mining Standard**: Achieved 100% verbatim data fidelity in Anki and Clipboard exports. All automated whitespace normalization and "smart" bracket/punctuation stripping have been removed from the extraction pipeline.
- **Unified Export Engine**: Consistently preserves source formatting (hyphens, slashes, multiple spaces) across all selection modes via the refactored `prepare_export_text` service.
- **Ordered Field Mapping**: Implemented deterministic, order-preserving field mapping for Anki TSV exports. Configuration via `anki_mapping.ini` now strictly respects the defined column sequence.
- **Punctuation Parity**: Synchronized sentence boundary detection and terminal punctuation restoration across all mining modes, ensuring consistent card quality regardless of selection method.

### 🎯 **"Surgical" Highlighting & Precision Selection**
- **Surgical Highlighting Model**: Transitioned to a strictly "word-only" highlighting model. Database matches now only color alphanumeric tokens, leaving logistical symbols (brackets, commas, etc.) in the default OSD color to eliminate visual ambiguity.
- **Character-Level Navigation**: Separated logistical symbols from word tokens to enable surgical, character-level navigation using the keyboard. Users can now land on and select individual punctuation marks without a mouse.
- **Shift-Aware Precision**: Keyboard navigation in the Drum Window (Mode W) is now Shift-aware, allowing for precise, multi-symbol range selection identical to mouse-driven interaction.
- **Semantic Punctuation Deprecation**: Removed "Semantic Punctuation" and "Atomic Token" color spreading in favor of a cleaner, more predictable visual interface that 100% matches the exported text.

### 🛡️ **Stability & Regression Fixes**
- **Drum OSD Stability**: Resolved vertical drift and layout synchronization issues in Drum Mode, ensuring pixel-perfect hit-testing during rapid navigation.
- **Cache-Shadowing Remediation**: Systemically removed variable shadowing and redundant logic in the core script to prevent difficult-to-track state regressions.
- **Manual Control Restoration**: Deprecated over-automated "smart" behaviors in favor of manual, user-driven precision, resulting in a more predictable and robust immersion experience.

---

# Release Notes - v1.54.0 (Search UI Refinement & Rendering Stability)


**Date**: 2026-04-28
**Version**: v1.54.0
**Implementation ZIDs**: 20260425233159, 20260426162931, 20260426175600, 20260426233000, 20260426235000, 20260427003254, 20260427011411, 20260427014503, 20260427021928, 20260427121101, 20260427161414, 20260427200421, 20260427233207, 20260428015150

## Highlights

### 🔦 **Search UI & Aesthetic Refinement**
- **Restored Selection Highlighting**: Corrected a visual regression in the Search HUD where active selections lost their colored highlighting. The interface now accurately renders the active result in bright white while preserving match-specific color indicators.
- **Independent Search Scaling**: Introduced `lls-search_results_font_size` to allow independent scaling of the results dropdown (e.g., 80% of the main UI size), optimizing screen real estate for dense search results.
- **Aesthetic Synchronization**: Realigned search window positioning and background logic with the "Drum Mode" visual style, ensuring a cohesive look and feel across all custom UI overlays.

### 🎨 **Subtitle Rendering & Layout Hardening**
- **Calibrated Drum Spacing**: Resolved vertical drift issues in Drum Mode by calibrating hit-zone detection and line intervals. Clicks now map with pixel-perfect accuracy to the rendered OSD text.
- **Active Subtitle Highlighting**: Implemented high-contrast highlighting for the currently active subtitle line across all modes, significantly improving readability during rapid navigation.
- **Uniformity Calibration Sync**: Synchronized OSD uniformity settings across different screen layouts and aspect ratios, ensuring consistent visual behavior in both windowed and fullscreen modes.

### 🚄 **Stability & Interaction Hardening**
- **Performance Regression Fix**: Eliminated a performance bottleneck in the rendering loop that caused micro-stutters during high-frequency subtitle updates.
- **Smart Joiner 2.0**: Improved the intelligent word joiner to handle complex German compound boundaries and non-standard punctuation during Anki exports and clipboard copying.
- **Fragility Resolution**: Hardened the subtitle copy engine against malformed ASS tags and fragmentation, ensuring verbatim capture even in edge cases with overlapping formatting tags.

### 🔧 **Workflow & Configuration**
- **Subtitle Toggle Recovery**: Resolved a regression that caused subtitle visibility toggles to become unresponsive after certain mode transitions.
- **Option Synchronization**: Fully synchronized all internal script parameters with `mpv.conf`, allowing users to persist custom calibrations for hit-testing and spacing without editing the Lua source.
- **Sticky Scroll Guard**: Fixed a bug where subtitle scrolling could become "stuck" at track boundaries or during rapid seek-repeat operations.

---

# Release Notes - v1.50.0 (OpenSpec Consolidation & Compliance)

**Date**: 2026-04-25
**Version**: v1.50.0
**Implementation ZIDs**: 20260422081955, 20260424202720, 20260424204200, 20260424223910, 20260425013258, 20260425025011, 20260425031828, 20260425124431, 20260425215431, 20260425221654

## Highlights

### 🚄 **OpenSpec Migration & Synchronization (Phase 2)**
- **Massive RFC Migration**: Successfully migrated 28 legacy releases (from v1.2.16 to v1.26.34) into the OpenSpec ecosystem. This ensures a three-way synchronization between legacy documentation, master specifications, and the current live code state.
- **Requirement Harmonization**: Traced feature evolution across the entire release history to minimize churn and resolve conflicting requirements between legacy versions and current implementations.

### 🛡️ **Code Compliance & Stabilization Audit**
- **Systemic Audit**: Conducted a comprehensive compliance audit of the entire codebase against `openspec/specs`, identifying and resolving implementation gaps and pruning "dead" specifications.
- **Verified Alignment**: Updated core specifications (like the `inter-segment-highlighter`) to reflect verified implementation behaviors, such as increasing the temporal proximity threshold for phrase joining to 60.0 seconds.

### 📚 **Book Mode Enhancements**
- **Independent Pointer Navigation**: Implemented an independent pointer system for Book Mode. Visual focus now remains stable during playback or navigation, preventing disruptive OSD jumps.
- **Refined Scrolling Logic**: Improved "push" scrolling and page-by-page navigation during playback, ensuring a consistent 3-line context margin for superior readability at viewport edges.
- **Binding Cleanup**: Pruned redundant key bindings and centralized interaction logic to prevent conflicts between Book Mode and global input handlers.

### 📋 **"Verbatim Selection" Copy Compliance**
- **Context-Aware Splicing**: Overhauled the copy functionality in the Drum Window to satisfy strict "Verbatim Selection with Context" requirements. Focal lines are now correctly spliced into surrounding context blocks.
- **Punctuation Preservation**: Removed aggressive punctuation stripping to ensure brackets (e.g., `[räuspern]`) are preserved in the clipboard, satisfying "Copy as is" requirements for full lines.
- **ASS Tag Resilience**: Improved context extraction to handle ASS tags (`{...}`) during text cleaning, ensuring reliable phrase matching even in complex formatted subtitles.

### 🔧 **Interaction Hardening**
- **Restored Auto-Scroll Repeat**: Resolved a regression where key-repeat functionality (`a`/`d` keys) was lost in Normal, Single Line, Reel, and Window modes.
- **OSD Stability**: Corrected runtime errors caused by function scope issues (nil upvalues) and stabilized OSD message positioning during high-frequency interactions.

---

# Release Notes - v1.48.10 (Drum Window Selection Refinement)


**Date**: 2026-04-22
**Version**: v1.48.10
**Implementation ZIDs**: 20260422005817

## Highlights

### 🎯 **Contiguous Multi-Line Selection**
- **Boundary Resilience**: Fixed an issue where range highlighting (yellow) was lost or reset when navigating across subtitle line boundaries. The selection anchor is now captured before cursor movement, ensuring a seamless selection trail between lines.
- **Modifier Logic Refinement**: Restricted range selection to standard `Shift` and `Ctrl+Shift` arrow combinations, maintaining the `Ctrl` key's role for fast navigation without unintended highlighting.

### ⚙️ **Configurable Navigation Parameters**
- **User-Defined Jumps**: Navigation jump distances are no longer hardcoded. Users can now customize the word/line jump amount via `lls-dw_jump_words` and `lls-dw_jump_lines` in `mpv.conf`.
- **Documentation Sync**: Updated `input.conf` to reflect these configurable capabilities, providing clear guidance on the role of Ctrl and Shift modifiers in the Drum Window.

---

# Release Notes - v1.48.8 (Stability Hardening & Performance)

**Date**: 2026-04-21
**Version**: v1.48.8
**Implementation ZIDs**: 20260421231238

## Highlights

### 🛡️ **Critical Stability Fix: Export Freeze Resolved**
- **Infinite Loop Guard**: Eliminated a critical UI freeze that occurred when using the Middle Mouse Button (MMB) to export terms if the click landed in whitespace or metadata regions. The string search engine now includes mandatory forward-progress guards and empty-term validation.
- **Search Engine Hardening**: Audited and hardened all internal `while` loops in the core script to ensure stability even when processing malformed or complex subtitle tags.

### ⚡ **Drum Window Performance Boost**
- **Layout Caching**: Introduced a structure-aware layout cache for the Drum Window (Mode W). This eliminates redundant OSD calculations during mouse movement, resulting in significantly smoother interaction and lower CPU usage.
- **Instant Anki Export**: Shifted the favorite-saving pipeline to an in-memory update model. Adding new words to Anki is now instantaneous, removing the previous UI stutter caused by full TSV file re-parsing.

### 🔧 **Internal Reliability**
- **Fingerprint-Based Syncing**: The background synchronization system now uses file fingerprints (mtime/size) to ensure consistency while avoiding unnecessary disk I/O.
- **Improved Context Extraction**: Refined the context-aware punctuation stripping to better handle multi-sentence selections and sentence boundaries.

---

# Release Notes - v1.48.2 (Sticky Navigation & UX Refinement)

**Date**: 2026-04-21
**Version**: v1.48.2
**Implementation ZIDs**: 20260421220419

## Highlights

### 🥁 **Sticky Column Navigation (VSCode Style)**
- **Horizontal Position Persistence**: Implemented a "sticky column" logic for vertical movement in the Drum Window (Mode W). Arrowing Up/Down now preserves your horizontal OSD position, snapping to the closest word on the target line. This provides a professional, editor-like navigation experience.
- **Lazy Anchor Initialization**: The navigation engine now intelligently initializes the sticky anchor. If the cursor is fresh or has been cleared (ESC/Mouse), the first vertical move anchors to the current word's center as a sensible baseline.
- **Horizontal Synchronization**: Manual horizontal movement (Left/Right) now dynamically updates the sticky column anchor, ensuring your next vertical leap starts from your new manual focus.
- **Navigation Economy**: Significant improvements to word-targeting logic for wrapped subtitle lines. Selecting specific words in long, multi-line blocks is now significantly faster and more intuitive.

---

# Release Notes - v1.48.0 (Precision Hardening & Performance)


**Date**: 2026-04-21
**Version**: v1.48.0
**Implementation ZIDs**: 20260421151234, 20260421153053

## Highlights

### 🎯 **Footprint-based Precision Hardening**
- **Surgical Punctuation Discipline**: Overhauled the rendering engine to use independent coordinate verification for punctuation. Symbols (commas, periods, brackets) no longer "bleed" into the colors of their neighbors, ensuring crystal-clear visual boundaries between terms.
- **Advanced Nesting Gradients**: Introduced expanded 3-tier visual depth for overlapping split-phrase (Purple) matching sets, providing superior hierarchical context for complex sentence patterns.
- **Pixel-Perfect Export Logic**: Migrated the Anki export engine to a strict fractional-index-based selection loop. This mathematically guarantees that trailing periods or leading brackets are only exported if explicitly highlighted by the user.
- **Continuous Multi-line Selections**: Implemented refined "Tail-Capture" logic for multi-line dragging, ensuring that line-traversing highlights are fully captured without "holes" or visual gaps at line boundaries.

### ⚡ **High-Performance "Zero-Overhead" Sync**
- **TSV Fingerprinting**: Implemented a pure-Lua fingerprinting system (`mtime` + `size`) for the Anki database. The script now intelligently skips the expensive parsing and index-rebuilding cycle if the file hasn't been modified on disk.
- **URL Discovery Optimization**: Extended the fingerprinting architecture to `.url`, `.txt`, and `.md` sidecar files. Directory scanning and file interrogation are now bypassed during periodic syncs if the source metadata remains unchanged.
- **Seamless Interaction**: Significantly reduced CPU spikes and UI micro-stutter during background sync iterations (default 5s), ensuring a fluid reading experience even with thousands of active mining records.

---

# Release Notes - v1.44.4 (Hardened Grounding & Precise Verification)

**Date**: 2026-04-20
**Version**: v1.44.4
**Implementation ZIDs**: 20260420002846, 20260420003934, 20260420015008, 20260420075549, 20260420181519

## Highlights

### 🛡️ **Hardened Interaction & Resilience**
- **Systemic Interaction Shield**: Standardized a 150ms "interaction shield" across all navigation and keyboard actions. This suppresses hardware-level jitter and "ghost clicks" from remote controls and touchpads immediately after a command.
- **Surgical RMB Isolation**: Hardened the Right-Mouse Button (RMB) behavior to exclusively pin tooltips. RMB actions no longer alter the yellow selection cursor or trigger accidental focus jumps.
- **Responsive Modifier Handling**: Refined the shield logic to ignore modifier keys (Ctrl, Shift, Alt, Meta), ensuring that complex mouse-keyboard combinations remain responsive and fluid.

### 🎯 **Precision Verification & Global Highlighting**
- **Word-Token Intersection**: Replaced fragile literal string matching with a robust word-tokenized check for Global Mode neighbors. Verification now succeeds through punctuation and formatting differences, ensuring 100% stable vocabulary highlighting.
- **Un-grounded Global Split Matching**: Refactored detection for non-contiguous terms (Purple) to be segment-relative. These now highlight correctly across the entire timeline, regardless of the original record's timestamp.
- **Corrected Adaptive Windows**: Rectified the mathematical logic for long-phrase temporal windows. The word-count growth factor is now correctly applied, stabilizing highlights for complex, sentence-length captures.

### 📦 **Expanded Media Support & UI Refinement**
- **Embedded Subtitle Support**: Relaxed initialization constraints to enable the Drum Window (Mode W) for internal/embedded subtitles in MKV files, expanding accessibility beyond external SRT/ASS tracks.
- **Logical Search Cursor**: Repositioned the search field cursor to the beginning (`|Search...`), providing a more intuitive and familiar input experience in the global search overlay.
- **Formal Spec Synchronization**: Synchronized all project specifications with the current architectural ground truth, formally adopting Multi-Pivot Grounding and the Unified Punctuation Spacing Rule (UPSR).

---

# Release Notes - v1.44.2 (Hardened Interaction & Unified Mining)


**Date**: 2026-04-19
**Version**: v1.44.2
**Implementation ZIDs**: 20260419191638, 20260419211035, 20260419215300

## Highlights

### 🚄 **Unified Interaction Engine & Multi-Layout Support**
- **Multi-Delimiter Shortcut Lists**: Massive refactoring of the input system. Every Drum Window command (Add, Pair, Select, Seek, etc.) now supports space, comma, or semicolon separated lists. Map `t`, `е`, and `MBTN_LEFT` to the same action simultaneously in `mpv.conf`.
- **Remote Control Optimization**: Tailored specifically for minimalist controllers (e.g., 8BitDo Zero 2). All interaction logic has been unified to provide parity between mouse and keyboard triggers.
- **Smart Context-Aware Export**: Mining triggers are now context-aware. Interacting with any member of a "Paired Selection Set" (Pink) automatically commits the entire set, eliminating the need for complex modifier combinations.

### 🛡️ **Hardware Jitter Resilience & Focus Stability**
- **Mouse Interaction Shield**: Introduced a 150ms "interaction shield" that ignores incoming mouse button signals immediately following a keyboard/remote command. This eliminates "ghost clicks" and "pointer jumps" caused by hardware-level mapper conflicts (e.g., JoyToKey jitter).
- **Strict Context Isolation**: Hardened the interaction engine to ensure keyboard commands never query native mouse position properties, resulting in 100% stable focus during remote-only use.
- **Coordinate-Precise Sync**: Standardized hit-testing logic to ensure the Drum Window focus (Yellow) and Anchor always jump to the exact pixel-perfect word under the mouse pointer before any action is executed.

### 🎨 **Advanced Range-Aware Pairing & Persistence**
- **Drag-to-Pair (Range Conversion)**: High-performance mining upgrade. Contiguous yellow selection ranges can now be converted into discrete paired selection sets (Pink) in a single action via keyboard (`t`) or Ctrl+Drag.
- **Persistent Selection Mode**: Decoupled the Paired Selection Set from modifier-key release. Pink highlights now persist indefinitely until explicitly committed or discarded (`Ctrl+ESC`), allowing for precise, multi-step curation of complex non-contiguous phrases.
- **Improved Visual Depth**: Standardized the use of "Gold" (#00CCFF) for contiguous selection cursors and "Neon Pink" (#FF88FF) for paired selection paths.

---

# Release Notes - v1.42.4 (Strict Grounding Enforcement)

## Highlights

### 🎯 **Strict Grounding Enforcement**
- **Eliminated Highlight Bleed**: Resolved a bug where multiple identical words in a single subtitle (e.g., the second "gleich" in a sentence) would incorrectly share the same highlight. The engine now strictly adheres to index-based grounding, ensuring only the exact user-selected occurrence is marked.
- **Single-Word Grounding Automation**: Updated the Drum Window (Mode W) to automatically generate and store precise grounding coordinates (`0:Index:1`) for single-word clicks. This transitions single-click exports into "New Generation" grounded records that are immune to contextual drift.
- **Gated Fuzzy Fallback**: Hardened the rendering logic in `calculate_highlight_stack` to block fuzzy context fallbacks for any record that contains valid grounding metadata, while maintaining compatibility for legacy cards.

---

# Release Notes - v1.42.2 (Dynamic Discovery & Precision Grounding)

**Date**: 2026-04-19
**Version**: v1.42.2
**Implementation ZIDs**: 20260419101025, 20260419104540, 20260419140508

## Highlights

### 📡 **Dynamic Media Source Discovery**
- **Automated URL Discovery**: Implemented a background scanner that searches for `.url`, `.txt`, and `.md` files in the media folder to automatically extract `SourceURL` metadata (e.g., YouTube links).
- **New Anki Field `source_url`**: Introduced the `source_url` keyword for Anki field mapping, enabling zero-touch metadata association for external media.
- **Resilient Background Sync**: URL discovery is integrated into the periodic synchronization loop with a file-path-aware cache that handles renamed or deleted source files without requiring a video restart.

### 🎯 **Precision Multi-Pivot Grounding**
- **Logical Coordinate System**: Transitioned from fragile single-index anchoring to a robust `LineOffset:WordIndex:TermPos` coordinate system for all highlights. This mathematically eliminates "highlight bleed" where common terms would incorrectly appear in unrelated scenes.
- **Temporal Epsilon Guard**: Implemented a mandatory +1ms offset in Anki exports to ensure anchoring coordinates always land safely within the intended subtitle segment, preventing boundary drift.
- **Configurable UI Tolerances**: Moved all hardcoded search windows and gap limits to user-tunable variables in `mpv.conf`, allowing for personalized balancing of recall vs. precision.

### 🎨 **Chromatic Selection Pairing & Visual Contrast**
- **"Warm vs. Cool" Selection Paths**: Overhauled the selection cursor theme to provide consistent chromatic feedback:
  - **Gold (#00CCFF)**: Used for contiguous selections, matching the resulting **Orange** database match.
  - **Neon Pink (#FF88FF)**: Used for split-phrase selections, matching the resulting **Purple** database match.
- **High-Intensity Contrast**: Optimized the hex values for the Orange and Brick palettes at 3rd-tier depth to ensure distinct separation even in high-intensity overlap scenarios.
- **Internal Sync & Docs**: Synchronized default script options with `mpv.conf` overrides and corrected legacy documentation that mislabeled the gold palette as "green."

### ⚡ **Engine Hardening & Optimization**
- **Recursive Grounded Maps**: Implemented recursive result caching and "lazy-parsing" for grounded coordinate maps to maintain 60fps UI performance during rapid scrolling and playback.
- **Stability Pass**: Finalized synchronization between the core `lls_core.lua` engine and user-facing configuration, resolving minor desyncs in default fallback behaviors.

---

# Release Notes - v1.40.2 (Strict Grounding & High-Fidelity Capture)

**Date**: 2026-04-18
**Version**: v1.40.2
**Implementation ZIDs**: 20260417112500, 20260418074913, 20260418183126, 20260418190735, 20260418194004, 20260418195829, 20260418211727, 20260418213707

## Highlights

### 🎯 **Strict Index-Based Grounding & Anchoring**
- **Logical Index Verification**: Implemented a mandatory `logical_idx` check for all subtitle highlights. This eliminates "highlight bleed" where common words (e.g., "die", "und") would incorrectly stay highlighted in unrelated segments.
- **Strict (Time, Index) Grounding**: Automated highlights are now anchored to their exact source occurrence, ensuring that Anki-exported terms only appear where they were originally mined when in local mode.
- **Pivot-Point Context Extraction**: Upgraded the context engine to use character-offset pivot points. This ensures the exporter captures the specific sentence containing your selection, even if identical words appear earlier in the track.

### 🎨 **Visual Priority & Phrase-Aware Styling**
- **Manual Overrides Automated**: Refactored the rendering loop to ensure manual focus (Bright Yellow) and persistent selections (Pale Yellow) always take visual precedence over database-driven highlights.
- **Phrase-Aware Punctuation**: Punctuation marks (commas, periods, brackets) that belong to a highlighted phrase now inherit the phrase's color, creating a cohesive visual block and improving reading flow.
- **Unified "Brick" Intersection**: Stabilized the Tri-Palette logic. Overlapping contiguous and split terms now correctly collapse into a unified "Brick" palette with up to 3 tiers of depth.

### 📋 **Verbatim Capture & Elliptical Selection**
- **Token-Weighted Range Extraction**: Migrated Ctrl+C and Anki exports to a scanner-based range extraction. This preserves all internal punctuation and original whitespace within your selection for 100% verbatim capture.
- **Elliptical Paired-Selection (` ... `)**: Introduced a specialized joiner for non-contiguous selections (e.g., German separable verbs). By injecting an ellipsis into the term, the engine now treats these as "Split-Only" targets, preventing distracting contiguous highlights on unrelated phrases.
- **Unicode Joiner (`compose_term_smart`)**: Unified all ad-hoc string reconstruction logic into a single, Unicode-aware formatter that correctly handles German, Russian, and English punctuation spacing.

### ⚙️ **Formal Spec-Driven Stabilization**
- **"Ground Truth" Compliance**: Completed a comprehensive overhaul to align the Drum Window behavior with the formal implementation-agnostic specification.
- **Robust Multi-Segment Stitching**: Hardened the sequence matching engine to bridge subtitle boundaries (up to 1.5s/5 segments) without visual flicker or gaps.
- **Final Regression Cleanout**: Resolved multiple syntax errors and logic desyncs in the OSD and window rendering loops, achieving 100% stability in Mode W.

---

# Release Notes - v1.38.4 (Selection Priority)

**Date**: 2026-04-17
**Version**: v1.38.4
**Implementation ZIDs**: 20260417103320

## Highlights

### 🥁 **Drum Window Selection Priority**
- **Non-Contiguous Selection Visibility**: Resolved a visual layering issue in the Drum Window (Mode W). Persistent multi-word selections made with `Ctrl + LMB` (muted yellow) now take absolute visual precedence over transient cursor highlights or drag-selection ranges (vibrant yellow).
- **Uninterrupted Workflow**: Users can now clearly see which words are already part of their paired selection set even when the regular selection cursor is positioned directly over them, eliminating the need to move the mouse to verify selection state.

---

# Release Notes - v1.38.2 (Scanner-Based Precision & UI Hardening)

## Highlights

### ⚡ **Scanner-Based Parsing & "Original Form" Display**
- **State-Machine Tokenization**: Migrated to a robust, single-pass scanner for subtitle parsing. This enables superior handling of complex German compounds, ASS tags (`{...}`), and bracketed metadata (`[...]`) without breaking word boundaries.
- **"Original Form" Fidelity**: Introduced `dw_original_spacing` (Boolean). When enabled, the Drum Window perfectly mirrors the whitespace and formatting of the source subtitle file, while still allowing for individual word-level interactivity and coloring.
- **Filler Token Retrieval**: The parser now captures whitespace and symbols as distinct tokens rather than discarding them, ensuring high-fidelity rendering for acronyms (e.g., `z.B.`) and technical terms.

### 🇩🇪 **High-Fidelity German Compound Support**
- **Punctuation-Agnostic Highlighting**: The highlighter's context neighbor check now "skips" over compound separators (dashes, slashes) and brackets to verify matches. This restores highlighting for German terms like `Amazon-Verteilzentrum` or words adjacent to metadata tags.
- **Smart Export Joiner**: Upgraded the Anki export engine with a smart joiner that preserves hyphens and slashes in compound terms, ensuring the exported data remains linguistically accurate.
- **Expanded UTF-8 Normalization**: Full case-insensitive matching and normalization for German umlauts (`äöü`) and the sharp S (`ß`, `ẞ`).
- **German Character Search**: Native input support for umlauts and eszett in the Search HUD, enabling precise filtering of German vocabulary.

### 🥁 **UI Stability & Layout Hardening**
- **Boundary-Aware Sliding Window**: Fixed the "shrinking block" effect at track boundaries. The Drum viewport now intelligently shifts its range to maintain consistent subtitle line density when navigating near the start or end of a file.
- **Reliable Seek Highlighting**: Standardized active line highlighting across all modes. Active subtitles now consistently render in white during navigation and playback, resolving a regression where floating-point precision issues caused lines to remain dimmed.
- **Smart Stacking & Positioning**: Improved layout coordination for dual-track subtitles in Drum Mode. Restored manual vertical adjustment control (via `r`/`t` keys) while implementing better default spacing to prevent overlap.

### 🛡️ **Bracketed Metadata & Content Handling**
- **Selective Bracket Preservation**: Users can now export bracketed terms (e.g., `[UMGEBUNG]`) as clean text targets. The engine strips the brackets but preserves the content if it represents the primary selection.
- **Safe Tag Neighbors**: Bracketed expressions are now treated as "safe" neighbors during strict context matching, preventing surrounding words from losing their highlights.

---

# Release Notes - v1.34.2 (Keyboard Tooltips & Selection Persistence)

## Highlights

### ⌨️ **Keyboard-Driven Tooltip Logic**
- **Unified Toggle Shortcut**: Introduced **`e`** (Russian **`у`**) to toggle translation tooltips in the Drum Window. This enhances keyboard-driven immersion sessions by eliminating the need for mouse interaction to peek at hints.
- **Dynamic Scroll Tracking**: Tooltips now intelligently follow their parent subtitle line during scrolling and navigation. The hint remains vertically anchored to the text rather than "float" at a static screen position.
- **Contextual Priority Targeting**: 
  - **Playback Mode**: While the video is running, the keyboard tooltip automatically follows the currently active subtitle (White).
  - **Immersion Mode**: When paused, the toggle prioritizes the user's manual selection/cursor (Yellow) for precise, word-by-word analysis.
- **RMB Interaction Hardening**: Restored and refined the Right-MouseButton (RMB) hold behavior. Tooltips now reliably appear during hold and correctly dismiss when focus is lost in non-hover modes.

### 🛡️ **Selection Persistence & Focus Stability**
- **Non-Destructive Navigation**: Manual seeking via **`a`** and **`d`** now preserves the active yellow selection in the Drum Window. This allows learners to jump back and forth between lines to check context without losing their current highlighted phrase.
- **Intelligent Autopause Focus**: Implemented a priority logic that keeps tooltips centered on the active playback line after an autopause trigger, preventing the UI from "snapping" back to a distant manual cursor unless explicit interaction occurs.

---

# Release Notes - v1.32.2 (TSV Recovery & Visual Depth)

**Date**: 2026-04-14
**Version**: v1.32.2
**Implementation ZIDs**: 20260414091237, 20260414100928, 20260414123431, 20260414150031

## Highlights

### 🎨 **Advanced Highlight Intersections & Nesting**
- **Paired Word Nesting (Purple Gradient)**: Non-contiguous/split highlights (Purple) now feature full nesting awareness. Overlapping split-word terms now exhibit a three-tier depth gradient (`anki_split_depth_1/2/3`), harmonizing their visual style with existing contiguous highlights.
- **Mixed Intersection Blending**: Introduced a sophisticated "Mixed" highlight state. When a word belongs to both a contiguous (Orange) and non-contiguous (Purple) saved term, the system now renders a distinct blended color (`anki_mix_depth_1/2/3`) to visualize the intersection accurately.
- **Decoupled Depth Tracking**: Refactored the internal stack-calculation engine to independently track `orange_stack` and `purple_stack`, enabling more precise multi-layer rendering and developer debugging.

### 🛡️ **TSV State Recovery & Initialization Hardening**
- **Auto-Creation Healing**: The Drum Window now automatically detects missing `.tsv` record files and creates a fresh template on startup. This ensures immediate UI recovery if the file is cleared or deleted mid-session.
- **Dynamic Header Skipping**: Upgraded the TSV parser to dynamically detect and ignore the header row, regardless of the custom term field configured in `anki_mapping.ini`.
- **Fail-Safe Observer Loop**: Wrapped all core mpv property observers in protected `pcall` execution. This prevents rogue subtitle errors from fatally crashing the player's internal state tracking.
- **Terminal Diagnostics**: Critical subsystem errors now bypass mpv's internal logging filter and print directly to the terminal for visibility.

---

# Release Notes - v1.32.0 (Multi-Word Ctrl-Selection & Dynamic Anki Mappings)

**Date**: 2026-04-14
**Version**: v1.32.0
**Implementation ZIDs**: 20260413133147, 20260413144355, 20260413163703, 20260413173817, 20260413213102, 20260413224742, 20260413234639, 20260414004717, 20260414015131, 20260414023304, 20260414033418

## Highlights

### 🖱️ **Multi-Word & Non-Contiguous Selection (Ctrl-Selection)**
- **Ctrl-Multiselect Gesture**: Introduced a sophisticated new workflow for marking non-contiguous constructs (e.g., German separable-prefix verbs or English phrasal verbs).
  - `Ctrl + LMB`: Click individual words to accumulate them into a yellow pending selection.
  - `Ctrl + MMB`: Commit the accumulated set as a persistent highlight and Anki export.
- **Split-Word Highlighting (Purple)**: Non-contiguous saved terms now feature a distinct **Purple** highlight to clearly distinguish them from contiguous selections.
- **Robust Highlighting Matcher**: Refactored the internal matching algorithm to reliably detect and style both contiguous (Orange) and split (Purple) multi-word terms, even when overlapping within the same subtitle block.
- **Center-Proximity Context Search**: Implemented a proximity-based search fallback for non-contiguous selections. This ensures that even when words are scattered across multiple sentences, the exported Anki context correctly captures the full logical span.

### 📋 **Dynamic Anki Mappings & Smart Export**
- **External Mapping Engine**: Migrated Anki field definitions to a dedicated `anki_mapping.ini` file. Users can now define an unlimited number of fields, use blank "holes" for alignment, and configure static text literals.
- **Automated TSV Headers**: The export engine now automatically generates Anki-compatible headers (e.g., `#deck column:N`) and field names at the top of every record file for zero-touch imports.
- **Track-Aware Metadata**: Enhanced the data pipeline to automatically extract deck names from filenames and generate language-specific TTS flags (`tts_source_[lang]`) based on active subtitle tracks.
- **Forward-Search Context Preservation**: Refined the context extraction logic to search for sentence boundaries starting from the *end* of a selection. This prevents premature truncation in multi-sentence selections.
- **Metadata & Punctuation Sanitization**: 
  - **Tag Stripping**: Automatic removal of bracketed metadata like `[musik]` or `[Lachen]` from exported cards.
  - **Period Restoration**: Naturally restores a terminal period to capitalized sentence exports that lost their original punctuation during the cleaning phase.

### 📚 **"Book Mode" & UI Stability**
- **Stationary Viewport Navigation**: Toggle **Book Mode** with **`b`** (Russian **`и`**) to lock the Drum Window UI. This freezes the viewport center while navigating (`a`/`d`) or selecting vocabulary, providing a flicker-free, book-like reading experience.
- **Synchronized Scroll Stability**: Resolved the "scroll-drift" bug. Viewport scrolling (`MouseWheel`) now perfectly preserves active selections and prevents the highlight pointer from "snapping" to the mouse during motion.
- **Hardened Subtitle Suppression**: Centralized the multi-track suppression logic in `master_tick`. Native subtitles are now rigorously hidden across all script modes, including during rapid track cycling.

### 🛠️ **Workflow Optimizations**
- **Instant Record Access**: Added the **`o`** (Russian **`щ`**) shortcut within the Drum Window to instantly open the currently active TSV record file in your system's default editor (e.g., VSCode).

---

# Release Notes - v1.28.16 (Unified Styling & FSM Hardening)


**Date**: 2026-04-13
**Version**: v1.28.16
**Implementation ZIDs**: 20260413121002, 20260413124623

## Highlights

### 🎨 **Unified Styling Architecture**
- **Mode-Specific Fonts**: Introduced the ability to specify independent `font_name`, `font_bold`, and `font_size` for all four rendering modes: Regular SRT, Drum Mode (`c`), Drum Window (`w`), and Tooltips.
- **Enhanced Legibility**: Updated default styling to **Consolas** across the suite for superior monospace alignment and professional aesthetic.
- **Monospace Calibration**: Finely tuned hit-testing and word-wrapping logic for Consolas, ensuring pixel-perfect mouse selection and pointer alignment.

### 🛡️ **FSM Architecture & Visibility Hardening**
- **Continuous Background Suppression**: The `master_tick` loop now rigorously monitors both `sub-visibility` and `secondary-sub-visibility` properties to prevent duplicate native overlays, especially when cycling tracks with `j`.
- **Visibility Conflict Resolution**: Resolved "flickering" issues by centralizing all property mutations into a single-source-of-truth logic engine.
- **Mode Mutex**: Implemented strict mutual exclusion between Drum Mode, Drum Window, and Regular OSD-SRT rendering to prevent frame buffer collisions.

### 🖼️ **Refactored Text Framing & Dark Theme**
- **Dynamic Background Boxes**: Refactored the internal text frame renderer to use hardware-weighted ASS alpha calculations. Background transparency is now perfectly balanced across all UI elements.
- **Premium Dark Aesthetics**: Implemented a "Dark Theme" baseline for the Drum Window, using consistent semi-transparent backgrounds that preserve cinematic immersion while providing high-contrast reading surfaces.

### 🛠️ **Anki Highlight Restoration**
- **Selection Fidelity**: Restored the `anki_highlight_bold` functionality within the Drum Window. Saved words and phrases now correctly display bold/color emphasis without desynchronizing from the viewport tracking.

---

# Release Notes - v1.28.12 (MMB Drag-Export & Occurrence Persistence)

**Date**: 2026-04-13
**Version**: v1.28.12
**Request ZID**: 20260413013335 (Archived: 20260413004525)

## Highlights

### 🖱️ **MMB Drag-to-Export**
- **Unified Selection Logic**: The Middle Mouse Button (MMB) now supports high-performance drag selection, identical to the Left Mouse Button.
- **Instant Commitment**: Releasing MMB now automatically triggers the Anki export process. Draw a phrase and release to instantly save it with full context and timing.
- **SCM Compatibility**: Middle-clicking an existing red selection range still commits and exports it, preserving the "Second Click Mode" workflow.

### 🎨 **Multi-Occurrence Persistence**
- **Non-Destructive Bookmarking**: Resolved the issue where saving a word in a new location would "un-highlight" previous occurrences. The engine now supports multiple time-anchors per word.
- **Global Context Fidelity**: All bookmarked instances of a word or phrase remain visible across the entire timeline, regardless of which specific instance was saved last.

### ⚖️ **Overlap-Only Intensity**
- **Intelligent Stacking**: Color intensity (highlight depth) now strictly reflects textual overlap between *different* saved items (e.g., a single word vs. a phrase).
- **Redundancy Guard**: Duplicate bookmarks of the exact same term across different locations no longer artificially darken the highlight, maintaining a clean and professional visual style.

---

# Release Notes - v1.28.10 (Sanitized Anki Export)

**Date**: 2026-04-13
**Version**: v1.28.10
**Request ZID**: 20260413004318

## Highlights

### 📋 **Universal Sanitized Capture**
- **Hardened Export Engine**: The Middle-Click (`MBTN_MID`) Anki export engine has been unified with the surgical stripping logic.
- **Boundary Sanitization**: Exporting words like `Umbruch.` or `ehrlich,` now automatically strips trailing punctuation before saving to the TSV. This ensures your Anki database remains pristine and optimized for dictionary matching.
- **Phrasal Integrity**: Internal punctuation within multi-word selections (e.g., `im Umbruch. Während`) is accurately preserved to maintain grammatical context.

### 🎨 **Bitwise-OR Highlight Aggregation**
- **Overlapping Match Fidelity**: Resolved a visual bug where commas would lose their color if a word was covered by both a single-word card and a phrase.
- **Logical Priority**: The engine now aggregates all active matches for a word. If **any** of the overlapping highlights is a multi-word phrase, the system prioritized **Continuity Mode**, ensuring commas and periods stay green for a perfect visual flow.

---

# Release Notes - v1.28.8 (High-Recall & Adaptive Highlighting)

## Highlights

### 🎨 **Adaptive Punctuation & Visual Continuity**
- **Logical Flow Balancing**: Highlights now intelligently distinguish between single vocabulary words and long-form phrases. 
  - **Single Words**: Word boundaries remain "surgical" (colored word body, white periods/commas) for a professional dictionary look.
  - **Phrases & Paragraphs**: Internal punctuation marks are now fully highlighted green to maintain visual flow and prevent "white holes" in long subtitle blocks.
- **Priority Logic**: When a single-word card overlaps with a larger phrase match, the system automatically prioritizes **Continuity Mode** to ensure a seamless visual experience.

### 📋 **Clean Capture Pipeline**
- **Boundary Sanitization**: All exported clips (clipboard copy) now automatically strip leading and trailing punctuation/whitespace. This ensures your Anki database remains clean and cards are optimized for perfect dictionary matching.
- **Internal Preservation**: Commas and periods inside a captured phrase are accurately preserved to maintain grammatical integrity.

### 🛡️ **Hardened High-Recall Engine**
- **Deep-Peek Verification**: The engine now recursively traverses up to 5 adjacent subtitle segments to verify phrase integrity, even if the text is heavily fragmented across single-word subtitles.
- **Adaptive Temporal Windows**: Introduced a dynamic fuzzy window that scales by **+0.5s per word** for long paragraphs. This prevents massive news report highlights from expiring prematurely as you read.
- **Inter-Segment Bridging**: Refined the 1.5s temporal threshold to bridge natural speaker pauses while preventing unrelated subtitle clusters from bleeding together.

### ⚡ **Performance & Data Integrity**
- **Lazy-Caching Logic**: Implemented high-performance caching for highlight terms. Word lists, cleaned keys, and context lookups are now pre-processed on first access.
- **Result**: Zero UI latency or mouse "sticking" even when hundreds of paragraph-long terms are active simultaneously.

---

# Release Notes - v1.28.6 (ReadEra Vocabulary Highlighting)

## Highlights

### 🎨 **ReadEra-Style Premium Highlighting**
- **Absolute Coordinate Rendering**: Vocabulary highlights now use a high-performance rendering engine that anchors to the physical top-left of the screen (`\an7\pos(0,0)`). This ensures every highlight box and word is placed with sub-pixel precision, eliminating visual desync.
- **Translucent Background Boxes**: Replaced invasive text-color gradients with semi-transparent rectangular "marker" underlays. This preserves the original subtitle colors while providing clear, stackable visual depth.
- **Amber/Gold Palette**: Implemented a sophisticated, depth-aware palette using correct ASS `BBGGRR` byte ordering. Highlights now shift from Light Amber (Depth 1) to Deep Rust (Depth 3) as multiple terms overlap.
- **Human-Centric Padding**: Every highlight box features soft horizontal padding (+4px) and vertical alignment offsets to mimic the look of a professional e-reader selection.

### 📋 **Intelligent Anki Mining Workflow**
- **Sentence-Aware Context**: The mining engine now prioritizes capturing grammatically complete sentences. It scans for `.`, `!`, and `?` boundaries within your context window before applying word-count truncation.
- **Automated TSV Synchronization**: Highlights are now managed via a localized `.tsv` database. The script reloads this file automatically every 30 seconds (or on demand), allowing for external cards to be edited without restarting the player.
- **Atomic Database Handling**: Uses protected `pcall` logic and atomic memory swaps during syncs to ensure the UI remains responsive and the database stays protected against corruption.

### 🛡️ **Hardened Matching & Stability**
- **Strict Whole-Word Filtering**: The highlight engine now uses tokenized word matching. Highlighting "auf" will no longer accidentally trigger on substrings like "Aufgaben," ensuring your vocabulary focus stays accurate.
- **Temporal Fuzzy Windowing**: Introduced a 10s "Fuzzy Window" that allows highlights to correctly stack and track even when a phrase spans across multiple subtitle file boundaries.
- **Particle Pollution Guard**: Implemented a 3-character minimum filter for automatic highlights, preventing common particles (like "de", "il") from cluttering your reading view while preserving high-value vocabulary.

---

# Release Notes - v1.28.4 (Selection-Aware Tooltip Suppression)

**Date**: 2026-04-12
**Version**: v1.28.4
**Request ZID**: 20260412162936

## Highlights

### 🛡️ **Analytical Immersion: Selection-Aware Suppression**
- **Symmetrical Action Suppression**: Tooltips now intelligently hide whenever you click or drag the mouse. This suppression is "sticky," remaining active on the exact line where you released the mouse until you move the focus to a different subtitle.
- **Persistent Selection Guard**: Any line within an active red-selection range is now automatically shielded from auto-hover tooltips. These lines enter a "Manual Only" mode to prevent visual clutter while reading, ensuring clues only appear when you explicitly Right-Click (RMB).
- **Manual Hint Priority**: Explicitly pressing **MBTN_RIGHT** (RMB) now resets all suppression locks for that line, allowing you to instantly peek at a hint even if the area was previously suppressed or part of a selection.

### ⚙️ **Refined Interaction Logic**
- **LMB & MMB Hold Suppression**: Tooltips now remain suppressed as long as the **Left** or **Middle (Wheel)** Mouse Button is held down. This allows you to "sweep" across lines while selecting or analyzing without any auto-hover popups interfering with your focus.
- **Improved Focus Stability**: Manual tooltip pins can be instantly dismissed with a standard click (LMB/MMB). The system is fully aware of multi-line selection drags, ensuring the UI remains professionally clean throughout complex immersion operations.

### 🧹 **Architectural Cleanup**
- **Functional Naming**: Internal mouse handles have been refactored (e.g., `cmd_dw_mouse_select`) to more accurately reflect their role in the selection and suppression lifecycle, ensuring the codebase remains maintainable as new interactions are added.

---

# Release Notes - v1.28.3 (Startup Fix)

**Date**: 2026-04-12
**Version**: v1.28.3
**Request ZID**: 20260412135354

## Bug Fixes

### 🛠️ **Resolved Startup Navigation Latency**
- **Eager Memory Loading**: Fixed an issue where navigation keys (`a`/`d`) were unresponsive immediately after starting a video. The script now eagerly loads subtitle data into memory as soon as a track is detected, regardless of whether a specialized mode (Drum/Window) is active.
- **Improved Initializer**: Consolidated all track-loading logic into the core media state handler, ensuring consistent behavior from the very first frame of playback.

---

# Release Notes - v1.28.2 (Unified Smooth Navigation Repeat)

**Date**: 2026-04-12
**Version**: v1.28.2
**Request ZID**: 20260412131945

## Highlights

### 🚄 **Unified Smooth Navigation Repeat**
- **Hold-to-Scroll Engine**: Replaced native OS key-repeat with a custom, high-precision script-controlled engine for subtitle seeking (`a`/`d`).
- **Universal Parity**: Navigation now behaves identically with smooth auto-scrolling in **Normal Mode**, **Drum Mode (`c`)**, and **Drum Window Mode (`w`)**.
- **Configurable Dynamics**: Introduced `seek_hold_delay` (default: 500ms) and `seek_hold_rate` (default: 10/sec) options. Fine-tune your scrolling experience via `mpv.conf`.
- **Zero-Stick Precision**: Leverages complex key bindings to ensure auto-scrolling stops instantly upon key release, eliminating "sticky" jumps during rapid navigation.

---

# Release Notes - v1.28.0 (Contextual Translation Tooltips)

**Date**: 2026-04-12
**Version**: v1.28.0
**Request ZID**: 20260412105348

## Highlights

### 🔦 **Contextual Translation Tooltips**
- **On-Demand Peeking**: Press **MBTN_RIGHT** (Right Click) in the Drum Window (`w`) to instantly see a secondary subtitle translation in a translucent balloon. 
- **Hold to Peek (Scanned Hover)**: Innovative interaction—hold the Right Mouse button and move across subtitles to "scan" translations fluently. Releasing the button preserves the pin on your last focus.
- **Dedicated Hover Mode**: Toggle permanent hover-based translations using **`n`** (or Russian **`т`**) for hands-free reading.

### 🎨 **Visual Unity & Customization**
- **Style Synchronization**: Tooltips are visually unified with the Drum Mode (Reel C) aesthetic, featuring matched font sizes (32) and translucent background boxes.
- **Independent Alpha Control**: Introduced separate controls for text and background opacity (`dw_tooltip_text_opacity` vs `dw_tooltip_bg_opacity`), allowing for perfectly balanced legibility.
- **Native OSD Framing**: Leverages mpv's native Style 3 background boxes for a premium, integrated look that respects global player themes.

### ⚙️ **Architectural Shortcut Management**
- **Temporary Key Overlays**: Implemented a "Hijack & Release" system where tooltip keys (RMB, `n`, etc.) are only active while the Drum Window is open, preventing global shortcut pollution.
- **Script-Opt Exposure**: Every aspect of the tooltip—shortcuts, colors, fonts, and behavior—is now fully configurable via `mpv.conf` without editing script files.
- **Enhanced Discoverability**: Integrated internal shortcut documentation directly into `input.conf` for a single, comprehensive reference hub.

---

# Release Notes - v1.26.36 (Visual Style Persistence)

**Date**: 2026-04-12
**Version**: v1.26.36
**Request ZID**: 20260412080107

## Highlights

### 🛡️ **Visual Style Persistence & Isolation**
- **Drum Mode C Fix**: Resolved a visual bug where the "Black Frame" (background box) around subtitles would disappear whenever the Search UI was active.
- **Granular Styling**: Switched from global property mutations to per-element ASS styling using the `{\\4a&HFF&}` (shadow alpha) tag. This allows the Search UI and Drum Window to stay "light" and clean without polluting the native styling of the actual reading track.
- **Safety Net Recovery**: Added an automatic recovery routine (`recover_native_osd_style`) that detects and reverts any "stuck" OSD properties left over from previous script crashes, ensuring your preferred visual theme is always respected.
- **Enhanced Context**: Refined default Drum Mode behavior with support for increased context lines (3) for better phrasal awareness during immersion.

---

# Release Notes - v1.26.34 (Universal Navigation Reliability)

**Date**: 2026-03-22
**Version**: v1.26.34
**Request ZID**: 20260322202226
**RFC**: [docs/rfcs/20260322202226-v1.26.34.md](docs/rfcs/20260322202226-v1.26.34.md)

## Highlights

### 🚄 **Universal Navigation Reliability**
- **Seamless Logic**: Exported the reliable, table-based seeking engine as global script-bindings (`lls-seek_prev` and `lls-seek_next`).
- **Global Smoothness**: Subtitle navigation (`a`/`d`) now behaves with identical high-precision reliability whether the Drum Window is open or closed. No more "double-tapping" after an autopause in any mode.

---

# Release Notes - v1.26.32 (Navigation & Pointer Fixes)

**Date**: 2026-03-22
**Version**: v1.26.32
**Request ZID**: 20260322191027
**RFC**: [docs/rfcs/20260322191027-release-v1.26.32.md](docs/rfcs/20260322191027-release-v1.26.32.md)

## Highlights

### 🚄 **Immediate Navigation Response**
- **Double-Tap Fix**: Resolved a persistent issue where jumping to the next subtitle (`d`) required two presses when the video was paused after an autopause.
- **Custom Seeking Logic**: Replaced the native `sub-seek` command with robust internal logic that calculates the exact subtitle start time from the loaded track, ensuring snappier and more reliable navigation in the Drum Window.

### 🥁 **Predictable Pointer Behavior**
- **Smart Deactivation**: The Drum Window now consistently opens with the word pointer deactivated (`-1`). This also applies after selecting search results or scrolling, preventing visual clutter and accidental word copying.
- **Focused Interaction**: Red Highlights now only appear when you explicitly engage with them via the arrow keys or mouse selection.

---

# Release Notes - v1.26.30 (Search Selection Fix)

**Date**: 2026-03-22
**Version**: v1.26.30
**Request ZID**: 20260322171238
**RFC**: [docs/rfcs/20260322171238-release-v1.26.30.md](docs/rfcs/20260322171238-release-v1.26.30.md)

## Highlights

### 🛡️ **Critical Search Selection Fix**
- **Scoping Resolution**: Fixed a Lua execution error where the script would crash when performing word-based selection in the Search HUD (`Ctrl+Shift+Arrows`). 
- **Definition Reordering**: Corrected the internal variable scope by reordering utility functions, ensuring all components are properly initialized before usage.
- **Enhanced Reliability**: The Search HUD and Drum Window are now more robust against rapid navigation and selection actions, preventing session-ending script failures.

### 🥁 **Selection State Consistency**
- **State Logic Refinement**: Fixed a naming discrepancy in the Drum Window's selection memory, ensuring that shift-selection highlights track correctly across multi-word ranges.

---

# Release Notes - v1.26.28 (Search Box Visibility Fix)

## Highlights

### 🔦 **Search HUD & Drum Window Visibility Fix**
- **Clean Interface**: Fixed a severe visual bug where enabling the "Black Frame" aesthetic (`osd-border-style=background-box`) rendered the Search and Drum Window UI unreadable.
- **Intelligent Style Override**: The script now dynamically detects when these custom UI panels are active and temporarily forces the OSD to a clean `outline-and-shadow` style. This prevents overlapping black boxes from obscuring your search results and reading context.
- **Preserved Aesthetics**: Your global `mpv` styling preferences are automatically restored the moment you close the Search or Drum Window, ensuring your immersive experience remains exactly how you like it.

---

# Release Notes - v1.26.26 (Cross-Platform Clipboard Support)

**Date**: 2026-03-22
**Version**: v1.26.26
**Request ZID**: 20260322161222
**RFC**: [docs/rfcs/20260322161222-release-v1.26.26.md](docs/rfcs/20260322161222-release-v1.26.26.md)

## Highlights

### 📋 **Universal Clipboard Integration**
- **Native OS Support**: Removed the hard dependency on Windows PowerShell. The suite now natively detects and supports the system clipboard on **Windows**, **macOS**, **Linux** (Wayland/X11), and **Android** (Termux).
- **Zero-Config Logic**: Automatically uses `pbcopy/pbpaste` (macOS), `wl-copy/wl-paste` (Wayland), `xclip/xsel` (Linux), or `termux-clipboard-*` (Android) as appropriate.
- **Improved Reliability**: Centralized clipboard handling into unified helper functions ensures that future features will automatically benefit from cross-platform compatibility.

---

# Release Notes - v1.26.24 (Isotropic Mouse Hit-Testing)

**Date**: 2026-03-22
**Version**: v1.26.24
**Request ZID**: 20260322154532
**RFC**: [docs/rfcs/20260322154532-release-v1.26.24.md](docs/rfcs/20260322154532-release-v1.26.24.md)

## Highlights

### 🎯 **Isotropic Mouse Hit-Testing**
- **Window Snap Immunity**: Fixed a severe selection bug where hit-test alignment completely drifted when the mpv window was resized or snapped to half the screen (non-16:9 aspect ratios).
- **Mathematical Overhaul**: The X-coordinate mapping now strictly anchors to the physical center of the screen and calculates horizontal offsets using the height-derived scaling factor (`scale_isotropic = oh / 1080`). 
- **Pixel-Perfect Tracking**: This mathematically guarantees that the invisible hit-test grid precisely tracks the physical pixels of the ASS-rendered text, completely irrespective of window stretching, letterboxing, or snapping.

---

# Release Notes - v1.26.22 (Drum Window Hit-Test Calibration)

**Date**: 2026-03-22
**Version**: v1.26.22
**Request ZID**: 20260322153215
**RFC**: [docs/rfcs/20260322153215-release-v1.26.22.md](docs/rfcs/20260322153215-release-v1.26.22.md)

## Highlights

### 🥁 **Precise Drum Window Hit-Testing**
- **Configurable Calibration**: Introduced `dw_vline_h_mul`, `dw_sub_gap_mul`, and `dw_char_width` as tunable options. This eliminates "click-drift" where selecting a word would hit the line above or below at large font sizes.
- **Consolas Optimization**: Calibrated the default multipliers specifically for the Consolas monospace font family, ensuring that highlights (red) align exactly with character boundaries regardless of text length.
- **Multi-Size Modes**: Reorganized `mpv.conf` into switchable "Modes" (e.g., MODE 1 for size 30, MODE 2 for size 34), allowing for instant calibration swapping when changing font sizes.

---

# Release Notes - v1.26.20 (Agent Config Standardization)

**Date**: 2026-03-22
**Version**: v1.26.20
**Request ZID**: 20260322135917
**RFC**: [docs/rfcs/20260322135917-release-v1.26.20.md](docs/rfcs/20260322135917-release-v1.26.20.md)

## Highlights

### 🚄 **Agent Configuration Standardization**
- **Documentation Parity**: Corrected a discrepancy in `AGENTS.md` where the specialized configuration folder was incorrectly referenced as `.agents/`. It is now correctly documented as **`.agent/`**, matching the actual filesystem structure.
- **Improved Clarity**: Standardized the terminology used to describe agent capabilities and OpenSpec workflows to ensure a more cohesive developer experience.

---

# Release Notes - v1.26.18 (Centralized Config & Styling)

**Date**: 2026-03-22
**Version**: v1.26.18
**Request ZID**: 20260322135347
**RFC**: [docs/rfcs/20260322135347-release-v1.26.18.md](docs/rfcs/20260322135347-release-v1.26.18.md)

## Highlights

### ⚙️ **Centralized Configuration Management**
- **Unified Control**: All adjustable script parameters from the core engine have been migrated into your main `mpv.conf`. You can now fine-tune AutoPause, Drum Mode, and Search HUD behavior directly without touching a single Lua file.
- **Improved Discoverability**: Added clear, in-line documentation for each parameter, explaining its use cases and default value.
- **Functional Templates**: Restored common configuration templates (e.g. `alang`, `slang`, `sub-visibility`) as easy-to-use commented-out examples in `mpv.conf`.

### 🎨 **Stylized & Uniform Configuration**
- **Cohesive Design Language**: Standardized both `mpv.conf` and `input.conf` with a uniform visual style. Every section now features a 75-character wide header for maximum clarity and professionalism.
- **Sectioned Documentation**: Reorganized parameters and keybindings into logical blocks, making the configuration files self-documenting and easier to navigate.

---

# Release Notes - v1.26.16 (Smart Font Scaling Integration)

**Date**: 2026-03-22
**Version**: v1.26.16
**Request ZID**: 20260322132514
**RFC**: [docs/rfcs/20260322132514-release-v1.26.16.md](docs/rfcs/20260322132514-release-v1.26.16.md)

## Highlights

### 📏 **Smart Font Scaling Core integration**
- **Native Logic**: Ported the experimental font scaling logic from `fixed_font.lua` directly into the core `lls_core.lua` engine for a more robust and unified architecture.
- **Softer Scaling Formula**: Implemented a mathematically weighted "Softer Scaling" algorithm. This ensures subtitles remain legible on small windows without causing aggressive multi-line text wrapping that obscures the video.
- **Centralized Config**: Added formal `script-opts` to `mpv.conf`. You can now enable/disable scaling and tune its "strength" (e.g., `lls-font_scale_strength=0.5`) directly from your main configuration file.
- **Architectural Cleanup**: Deleted the standalone `scripts/fixed_font.lua` script, simplifying the installation and reducing file clutter.

### 🛡️ **Drum Mode Consistency Fix**
- **Sync Fidelity**: Internal improvements to how Drum Mode and OSD overlays interact with the new scaling engine to prevent layout desync during rapid window resizing or track switching.

---

# Release Notes - v1.26.14 (Subtitle Parsing Fix)

**Date**: 2026-03-22
**Version**: v1.26.14
**Request ZID**: 20260322123553
**RFC**: [docs/rfcs/20260322123553-release-v1.26.14.md](docs/rfcs/20260322123553-release-v1.26.14.md)

## Highlights

### 🥁 **Subtitle Parsing Robustness**
- **BOM Handling**: Improved the custom `.srt` parser to correctly handle files starting with a UTF-8 Byte Order Mark (BOM). This fixes a bug where the very first subtitle of a BOM-encoded file was consistently skipped in Drum Mode.
- **Invisible Character Removal**: The parser now proactively strips invisible architectural markers at the file's start, ensuring the first subtitle ID is correctly identified as a numeric sequence.

---

# Release Notes - v1.26.12 (Drum Formatting & Sync Fidelity)

**Date**: 2026-03-21
**Version**: v1.26.12
**Request ZID**: 20260321213543
**RFC**: [docs/rfcs/20260321213543-release-v1.26.12.md](docs/rfcs/20260321213543-release-v1.26.12.md)

## Highlights

### 🥁 **Seamless Drum Mode Layout**
- **Unified Block Rendering**: Drum Mode now mathematically glues all historical, active, and future text lines into a single, cohesive ASS rendering block. This totally eliminates all visual gaps, padded box overlaps, and the previous split "bifurcation" between top/bottom lines.
- **Strict OSD Styling**: Standard Subtitles and Drum Mode now have physically decoupled style commands. Drum Mode strictly forces an ultra-clean `outline-and-shadow` appearance, while regular subtitles can still natively enjoy the PotPlayer "Black Frame" aesthetic without polluting Drum readability.

### 🛡️ **Position Sync Fidelity**
- **Dynamic Live Tracking**: Drum Mode's vertical position explicitly reads the native `secondary-sub-pos` directly from mpv in real-time. Manually moving the secondary track with `Shift+R`/`Shift+T` (or `К`/`Е`) now yields immediate, pixel-perfect position tracking within the Drum UI itself.
- **Position Toggle Repaired**: Fixed a state-desync bug where tapping `y` to jump between Top/Bottom would update internal script variables without successfully notifying mpv's actual property renderer.

### 🤫 **UI Interference Cleanup**
- **Sleek Navigating**: Forcibly disabled the native, low-res mpv `osd-bar` (timeline scale) globally. Frantically skipping through subtitle lines with `a` or `d` will no longer trigger ugly timeline artifacts. The visual timeline remains cleanly sequestered within the elegant OSC invoked via your `TAB` key.

---

# Release Notes - v1.26.10 (OpenSpec Integration)

**Date**: 2026-03-21
**Version**: v1.26.10
**Request ZID**: 20260321182207
**RFC**: [docs/rfcs/20260321182207-release-v1.26.10.md](docs/rfcs/20260321182207-release-v1.26.10.md)

## Highlights

### 🚄 **OpenSpec Workflow Integration**
- **Spec-Driven Development**: The project now supports a formal OpenSpec workflow, enabling precise alignment between human intent and AI implementation.
- **Structured Changes**: New features and fixes are now managed through a unified **Propose → Apply → Archive** lifecycle, ensuring every change is documented, designed, and verified.

### 🤖 **Enhanced Agent Capabilities**
- **Specialized Slash Commands**: Added native support for `/opsx-propose`, `/opsx-apply`, `/opsx-archive`, and `/opsx-explore` directly within the Antigravity chat.
- **Discovery Document**: Created `AGENTS.md` to provide a central reference for all specialized agent skills and workflows available in the repository.
- **Informed Assistance**: Configured `openspec/config.yaml` with deep project context (Tech stack, Design philosophy) to ensure more relevant and "premium" AI assistance.

---

# Release Notes - v1.26.8 (Subtitle Feature Consistency & Feedback)

**Date**: 2026-03-14
**Version**: v1.26.8
**Request ZID**: 20260313235721
**RFC**: [docs/rfcs/20260314000819-release-v1.26.8.md](docs/rfcs/20260314000819-release-v1.26.8.md)

## Highlights

### 🛡️ **Robust Feature Guarding**
- **External Track Detection**: The advanced feature suite (Drum Mode, Drum Window, and Search HUD) now intelligently verifies whether the currently active subtitles are external files before activating.
- **Explicit Feedback**: If you are using embedded subtitles (e.g., inside an `.mkv`), these features will now gracefully inform you that they "Require external subtitle files" instead of silently failing or getting stuck in an "ON" state.

### 📋 **Descriptive Mode Cycling**
- **Copy Mode (`z`)**: Pressing `z` to cycle the subtitle copying mode now presents clear, descriptive OSD labels: `A (Primary/Target)` and `B (Secondary/Translation)`. When only a single `.srt` track is loaded, the engine reports "Fixed to Primary (Single Track)".
- **Secondary Subtitles (`j`)**: When attempting to cycle translation tracks with only one file loaded, the engine now provides format-aware context. Instead of just asserting "OFF", the status will explain if translations are "Managed internally by ASS styling" or if there is simply "Only 1 track available."

---

# Release Notes - v1.26.4 (Cyrillic Import Fix & UI Silence)

**Date**: 2026-03-13
**Version**: v1.26.4
**Request ZID**: 20260313225638
**RFC**: [docs/rfcs/20260313225638-release-v1.26.4.md](docs/rfcs/20260313225638-release-v1.26.4.md)

## Highlights

### 🥁 **Cyrillic-Free .ass Import**
- **Targeted Filtering**: Subtitle parsing now proactively filters out Cyrillic lines when importing `.ass` files for the Drum Window.
- **Pure Environment**: This ensures your primary reading track remains a focused, target-language only environment, even if the source file contains interleaved translations.

### 🤫 **Silent UI transitions**
- **Cleaner UX**: Removed the "OPEN/CLOSED" OSD messages when toggling the Drum Window.
- **Contextual Feedback**: The visual emergence of the window provides sufficient feedback, resulting in a more professional and cinematic feel during immersion.

### 🛠️ **Hoisted Core Utilities**
- **Architectural Cleanup**: Hoisted all text-processing helpers (`has_cyrillic`, `is_word_char`, etc.) to the top of `lls_core.lua` for global reliability.
- **Nil-Safety Hardening**: Added defensive guards to all core string functions to prevent runtime crashes on malformed subtitle inputs.

---

# Release Notes - v1.26.2 (Externalized Search Styles)

**Date**: 2026-03-12
**Version**: v1.26.2
**Request ZID**: 20260312212143
**RFC**: [docs/rfcs/20260312212143-release-v1.26.2.md](docs/rfcs/20260312212143-release-v1.26.2.md)

## Highlights

### 🔦 **Externalized Search Styling**
- **Precision Configuration**: Added new parameters for hit colors, selection colors, and bolding toggles.
- **Ultra-Minimalist Defaults**: The project now defaults to a high-contrast "Black & Bold" look while allowing full user customization via the `Options` table.
- **Selection Marker Legacy**: The selection marker (`> `) and colored highlights are now optional architectural components controllable via logic or config.

---

# Release Notes - v1.26.0 (Visual Search Feedback)

**Date**: 2026-03-12
**Version**: v1.26.0
**Request ZID**: 20260312202316
**RFC**: [docs/rfcs/20260312202316-release-v1.26.0.md](docs/rfcs/20260312202316-release-v1.26.0.md)

## Highlights

### 🔦 **Hit-Highlighting in Search**
- **Elegant Visual Cues**: The search results list now elegantly highlights matching characters using **Bold High-Contrast** colors.
- **Intelligent Contrast**: Highlights adapt to the selection state—turning **White** when a line is selected to ensure maximum readability against the red selection bar.
- **Fuzzy Accuracy**: Even non-contiguous matches (e.g., `mne` matching **m**a**n**ag**e**) are precisely highlighted.

---

# Release Notes - v1.25.2 (UI Visibility Enhancement)

**Date**: 2026-03-12
**Version**: v1.25.2
**Request ZID**: 20260312195256
**RFC**: [docs/rfcs/20260312195256-release-v1.25.2.md](docs/rfcs/20260312195256-release-v1.25.2.md)

## Highlights

### 🎨 **Brighter Active Subtitles**
- **Enhanced Contrast**: The active subtitle line in the Drum Window (Static Reading Mode) is now colored in a **Brighter Blue** for significantly better visibility against the window's beige background.
- **Improved Focus**: This makes it much easier to track the current playback position when reading through a long subtitle track.

---

# Release Notes - v1.25.1 (Compact Proximity Search)

**Date**: 2026-03-12
**Version**: v1.25.1
**Request ZID**: 20260312194600
**RFC**: [docs/rfcs/20260312194622-release-v1.25.1.md](docs/rfcs/20260312194622-release-v1.25.1.md)

## Highlights

### 🎯 **Compact Proximity Ranking**
- **Intelligent Density**: The search engine now evaluates how "compact" a fuzzy match is. If you type `mne`, results where these letters are found within a single word (like "**m**a**n**ag**e**") are ranked significantly higher than results where they are scattered across the entire sentence.
- **UX Refinement**: This drastically reduces "noise" in the search results when using short fuzzy queries while maintaining the flexibility of order-independent keyword matching.

---

# Release Notes - v1.25.0 (True Fuzzy Keyword Search)

**Date**: 2026-03-12
**Version**: v1.25.0
**Request ZID**: 20260312192633
**RFC**: [docs/rfcs/20260312192633-release-v1.25.0.md](docs/rfcs/20260312192633-release-v1.25.0.md)

## Highlights

### 🔍 **True Fuzzy Keyword Search (Bash-Style)**
- **Order-Independent Matching**: You can now type keywords in any order (e.g., `fox quick` finds `The Quick Brown Fox`).
- **Approximate Keywords**: Each word in your search can be fuzzy (e.g., `tst ths` finds `tested this`).
- **Intelligent Ranking**: While order is independent, the engine explicitly rewards correct sequences and literal matches, keeping the most "natural" results at the top.

---

# Release Notes - v1.24.10 (Search Relevance & Cyrillic Parity)

**Date**: 2026-03-12
**Version**: v1.24.10
**Request ZID**: 20260312185300
**RFC**: [docs/rfcs/20260312185338-release-v1.24.10.md](docs/rfcs/20260312185338-release-v1.24.10.md)

## Highlights

### 🎯 **Relevance-Based Search Sorting**
- **Scoring Engine**: Results are now sorted by "Relevance" rather than chronological order. Exact matches and prefix-substring matches now always appear at the very top of the list.
- **Cyrillic Case Parity**: Implemented a custom UTF-8 lowercase helper. Search is now fully case-insensitive for Russian characters, ensuring consistent discovery of Cyrillic phrases regardless of input case.

---

# Release Notes - v1.24.9 (Search HUD UX Enhancements)

**Date**: 2026-03-12
**Version**: v1.24.9
**Request ZID**: 20260312175031
**RFC**: [docs/rfcs/20260312175031-release-v1.24.9.md](docs/rfcs/20260312175031-release-v1.24.9.md)

## Highlights

### 📋 **Bash-Style Word Deletion**
- **Action**: Added `Ctrl + W` (and `Ctrl + Ц`) to the Search HUD.
- **Behavior**: Instantly deletes the word before the cursor, matching the behavior of terminal environments like Bash. This significantly improves editing efficiency when refining search queries.

---

# Release Notes - v1.24.8 (Stability & Search Selection)

**Date**: 2026-03-12
**Version**: v1.24.8
**Request ZID**: 20260312174400
**RFC**: [docs/rfcs/20260312174428-release-v1.24.8.md](docs/rfcs/20260312174428-release-v1.24.8.md)

## Highlights

### 🔍 **"Really" Fuzzy Search**
- **Character-Order Matching**: Upgraded the Search HUD from literal substring matching to a robust fuzzy algorithm. You can now find "hello world" by typing "hlowrd" or "hl wrd". 
- **Select All**: Added `Ctrl + A` (and `Ctrl + Ф`) to the Search HUD. Instantly highlight your entire query for quick replacement or deletion.

### 🥁 **Drum Window (Static Reading Mode) Enhancements**
- **Enter to Seek**: Navigating the track list manually? Press `ENTER` on any line to instantly seek video playback to that timestamp and re-engage "Follow" mode.
- **Advanced Nav Multipliers**: Added `Ctrl + Arrows` and `Shift + Ctrl + Arrows` support. Navigate and select text in larger chunks (5 words/lines) for faster phrasal isolation.
- **Full Layout Parity**: All new keyboard shortcuts fully support both English and Russian layouts.

### 🛡️ **Critical Stability & UI Fixes**
- **Lexical Scope Fix**: Stabilized the script by strictly defining all command functions before usage, resolving the "disappearing window" crash.
- **Subtitle Sync Corrected**: Fixed a regression in `parse_time` that caused centisecond desynchronization in ASS subtitles.
- **UI Layering (Z-Index)**: Explicitly set OSD layers to ensure the Search HUD and Drum Window always appear on top of native subtitles and other overlays.
- **Keybinding Cleanup**: Hardened the cleanup logic to ensure search-specific keys (like Select All and Arrows) are always removed when closing the HUD.

---

# Release Notes - v1.24.0 (Universal Subtitle Search)

**Date**: 2026-03-12
**Version**: v1.24.0
**Request ZID**: 20260312115025
**RFC**: [docs/rfcs/20260312115025-release-v1.24.0.md](docs/rfcs/20260312115025-release-v1.24.0.md)

## Highlights

### 🔍 **Universal Subtitle Search**
- **Standalone Lookup Overlay**: Subtitle search is no longer tied to the Drum Window. Press `Ctrl + F` (or `Ctrl + А`) at any time to summon a transparent search overlay directly over your video.
- **Fuzzy Text Navigation**: Type keywords to immediately filter the entire primary subtitle track. Navigation is synchronized; selecting a result instantly jumps the video and updates the Drum Window's context in the background.
- **Dual Layout First-Class Support**: Full native support for Russian Cyrillic input without keyboard switching.

### 📋 **Advanced Input & Clipboard**
- **Clipboard Paste**: Press `Ctrl + V` (or `Ctrl + М`) within the search bar to paste text from your system clipboard. Line breaks are automatically stripped to ensure query cohesion.
- **UTF-8 Precision**: Enhanced the input buffer to handle multi-byte characters. Deleting Cyrillic letters with Backspace now works with perfect byte-alignment.

### 🖱️ **Interactive Search Results**
- **Mouse Selection**: The search dropdown is now fully interactive. Use your mouse to click directly on any search result to jump to that timestamp instantly.
- **Dynamic Scrolling**: The result list intelligently scrolls and center-aligns as you navigate via keyboard or mouse.

### 🛡️ **Technical Robustness & Sync**
- **Hard-Sync Playback**: Upgraded jumping logic to use `seek absolute+exact`. This eliminates the "desync" bug where secondary subtitles would occasionally fail to load or align after a rapid jump.
- **Visibility Restoration**: Fixed a core engine bug where exiting the Drum Window would force subtitles 'ON' regardless of their previous state. Your manual visibility settings are now rigorously preserved.

---

# Release Notes - v1.2.22 (Track Scrolling Shortcuts)

**Date**: 2026-03-11
**Version**: v1.2.22
**Request ZID**: 20260311101023
**RFC**: [docs/rfcs/20260311101023-release-v1.2.22.md](docs/rfcs/20260311101023-release-v1.2.22.md)

## Highlights

### ⌨️ **Universal Track Scrolling Shortcuts**
- **Symmetrical 2-Second Seeks**: Added `Shift + A` / `A` and `Shift + D` / `D` to precisely mimic the default 2-second forward and backward track scroll natively mapped to `LEFT` and `RIGHT` arrow keys.
- **Mode-Agnostic Access**: In Drum Window `w` (Static Reading Mode), arrow keys are hijacked to handle text viewport scrolling. Because `A`/`D` maps correctly via Shift, you can now freely scrub back and forth through video tracks by 2-second intervals without hiding the window or relying on standard arrow keys.
- **Native Dual Layout Support**: These keys are intrinsically mapped to both English (`A`/`D`) and Russian (`Ф`/`В`) layouts, enabling swift usage without manually toggling language keyboards. 

---

# Release Notes - v1.2.20 (Regression Audit & Documentation)

**Date**: 2026-03-11
**Version**: v1.2.20
**Request ZID**: 20260311044229
**RFC**: [docs/rfcs/20260311044229-release-v1.2.20.md](docs/rfcs/20260311044229-release-v1.2.20.md)

## Highlights

### ✅ **Comprehensive Regression Audit**
- **Hunk-by-Hunk Verification**: Full review of the +398/-46 line diff (10 hunks, 18 commits) between the pre-feature baseline and the final Mouse Selection commit confirmed zero regressions.
- **All Existing Functions Verified Intact**: `cmd_dw_copy`, `cmd_dw_word_move`, `cmd_dw_line_move`, `cmd_dw_scroll`, `cmd_toggle_drum`, `draw_drum`, `tick_dw`, `tick_autopause`, `master_tick`, `cmd_smart_space`, `cmd_toggle_sub_vis`, `cmd_cycle_sec_pos` — all untouched.
- **Selection Logic Preserved**: The `draw_dw` refactoring was verified to maintain functionally identical selection highlighting logic.
- 📋 **Full audit table**: [Hunk-by-Hunk Verdict](docs/rfcs/20260311044229-release-v1.2.20.md#hunk-by-hunk-verdict)

### 📝 **Release Documentation**
- **RFC Packaged**: Full technical write-up of the layout engine, hit-testing math, OS conflict resolution, and hardware-accelerated dragging decisions.
- **README Updated**: Version badge bumped, Static Reading Mode section expanded with Mouse Selection and Double-Click Seek features, keybindings table updated with `LMB` and `Ctrl+Arrows`.

---

# Release Notes - v1.2.18 (Advanced Mouse Selection)

**Date**: 2026-03-11
**Version**: v1.2.18
**Request ZID**: 20260311023622
**RFC**: [docs/rfcs/20260311023622-release-v1.2.18.md](docs/rfcs/20260311023622-release-v1.2.18.md)

## Highlights

### 🖱️ **Advanced Mouse Selection (Drum Window)**
- **Hardware-Accelerated Dragging**: Selecting text now tracks your cursor perfectly at your screen's refresh rate (+60fps) using native `mouse_move` bindings, instead of stuttering on a background timer.
- **Double-Click to Seek**: Double-clicking on any word inside the Drum Window will instantly seek video playback to that exact subtitle line, re-center your viewport, and re-engage "Follow" mode.
- **Point-to-Point Extension**: First click a word to set your anchor, then move your mouse to the end of your desired sentence and `Shift+Click`. The entire block will be cleanly highlighted.

### 🛡️ **UI & Native Conflict Resolution**
- **Window Dragging Fix**: Mpv's native "drag video to move window" functionality previously intercepted selection attempts. The script now temporarily disables OS window dragging while the Drum Window is open, ensuring your first click-and-drag always registers instantly.
- **Subtitle Overlap Shield**: Opening the Drum Window now aggressively snapshots and hides all underlying native subtitle tracks (and Drum Mode overlays), guaranteeing you'll never see garbled overlapping text again. Everything is restored perfectly when the window closes.

### ⌨️ **Synchronized Scrolling**
- **VSCode-Style Edge Snap**: By popular demand, `Ctrl+UP` and `Ctrl+DOWN` now scroll the viewport (just like the mouse wheel). If you scroll the cursor completely off-screen, pressing a standard arrow key will instantly snap the viewport to bring the cursor back onto the edge of your screen.

---

# Release Notes - v1.2.16 (Drum Window Evolution & Static Reading Mode)

**Date**: 2026-03-11
**Version**: v1.2.16
**Request ZIDs**: 20260311014935
**RFC**: [docs/rfcs/20260311014935-release-v1.2.16.md](docs/rfcs/20260311014935-release-v1.2.16.md)

## Highlights

### 🥁 **Drum Window Evolution**
- **Static Reading Mode**: Transformed the Drum Window into a robust "Static Reading Mode". The viewport now freezes when you navigate or scroll, providing a flicker-free environment for intensive reading during immersion.
- **Viewport Decoupling**: Completely decoupled playback tracking from manual navigation. The player's active position continues to be highlighted in Navy, but it won't move the window's view under your cursor.
- **Edge-Aware Scrolling**: Implemented text-editor style viewport control. The window only scrolls when you move the cursor to the top or bottom edges of the visible area.

### 📋 **Advanced Multi-line Selection**
- **Range Selection**: Hold **`Shift`** plus navigation keys to select and highlight text across multiple subtitle rows.
- **Substring Copy**: Refined the `Ctrl+C` behavior to support multi-line and substring extraction. Copying now aggregates all highlighted words into a clean, format-free clipboard export.
- **Word-Level Navigation**: Improved the red word-pointer's precision. It now automatically resets to the first word of the active subtitle line when navigating between lines or opening the window.

### ⌨️ **Enhanced Control Symmetrics**
- **Independent Seek/Highlight**: Seeking (`a`/`d`) now clears selection and re-centers the viewport, ensuring that highlighting and browsing do not interfere with playback navigation.
- **Dual-Layout Selection**: Full hotkey mapping for both English and Russian keyboards (`Shift + Arrows`).
- **Layout Cleanup**: Integrated `\q0` wrapping for long subtitles and tightened line spacing to maximize context without visual overlap.

---

# Release Notes - v1.2.14 (Terminology & Goals Refinement)

**Date**: 2026-03-10
**Version**: v1.2.14
**Request ZID**: 20260310145832
**RFC**: [docs/rfcs/20260310145832-release-v1.2.14.md](docs/rfcs/20260310145832-release-v1.2.14.md)

## Highlights

### 🎯 **Language Acquisition Pivot**
- **Terminology Standardization**: System-wide update to standardize on **"Language Acquisition"** and **"Immersion"** terminologies. This aligns the suite's identity with the philosophy of extensive, high-volume input.
- **Refined Philosophy**: Updated the core mission statement to focus on the **convenient consumption** of Dual-Subtitle (DualSubs) material for learners, emphasizing the use of the player for immersion sessions.

### 🧩 **Extensive Acquisition Goals**
- **Dual-Subtitle Synergy**: Formalized the project's goal of mastering the display of original and translated tracks simultaneously.
- **YouTube Context Protection**: Documented how the suite's unique features protect learners against context loss when consuming YouTube's auto-generated subtitle streams.
- **Local Workflow Authority**: Clarified the suite's role as the final destination for offline immersion following material preparation with companion tools.

---

# Release Notes - v1.2.12 (Dual Subtitle Positional Control)

**Date**: 2026-03-10
**Version**: v1.2.12
**Request ZID**: 20260310141127
**RFC**: [docs/rfcs/20260310141127-release-v1.2.12.md](docs/rfcs/20260310141127-release-v1.2.12.md)

## Highlights

### ↔️ **Dual Subtitle Positional Control**
- **Independent Shifting**: Introduced keybindings to move the secondary subtitle track vertically, independent of the primary track. This is essential for preventing overlaps in multi-line phrasal subtitles.
- **Manual Override**: Users can now tune the exact visual balance between target and translation tracks on-the-fly without editing configuration files.
- **Drum Sync**: Manual positioning persists and synergizes with "Drum Mode," allowing users to set a custom vertical baseline before activating the cascading context view.

### ⌨️ **Layout-Agnostic Positioning**
- **Primary Sub-Pos**: Explicitly mapped `r` / `t` (and Russian `к` / `е`) to ensure subtitle "nudging" works natively in both English and Cyrillic keyboard layouts.
- **Secondary Sub-Pos**: Added `Shift+R` / `Shift+T` (and Russian `К` / `Е`) for secondary track control.

---

# Release Notes - v1.2.10 (Centralized Config & Safety Gap)

**Date**: 2026-03-10
**Version**: v1.2.10
**Request ZID**: 20260310120822
**RFC**: [docs/rfcs/20260310120822-release-v1.2.10.md](docs/rfcs/20260310120822-release-v1.2.10.md)

## Highlights

### ⚙️ **Centralized Script Configuration**
- **External Overrides**: Enabled `script-opts` support in `lls_core.lua`. You can now manage script-specific toggle positions directly from `mpv.conf` without touching Lua files.
- **Dynamic Config Authority**: The script now treats `mpv.conf` as the single source of truth for all operational parameters.

### 🛡️ **Positioning Safety Guards**
- **Overlap Prevention**: Implemented a mandatory 5% "Safety Gap" between primary and secondary subtitles at the bottom of the screen. This resolves the regression where subtitles would "stick together."
- **Threshold-Based Toggling**: Replaced strict coordinate checks with robust threshold logic. The toggle now intelligently adapts to custom positions (e.g., if you set your 'Top' to 15% instead of 10%).

### ⌨️ **System Key Robustness**
- **Dual-Layout Quit**: Key `q` (and `Q` for save-position) now works in both English and Russian (`й`/`Й`) layouts.
- **Essential Controls**: Added native Russian layout mapping for Mute (`ь`), Playback Speed (`х`/`ъ`), and Frame Stepping (`ю`/`б`).

---

# Release Notes - v1.2.9 (Project Analytics & Automation)

**Date**: 2026-03-10
**Version**: v1.2.9
**Request ZID**: 20260310094822
**RFC**: [docs/rfcs/20260310094822-release-v1.2.9.md](docs/rfcs/20260310094822-release-v1.2.9.md)

## Highlights

### 📊 **New Repository Analytics**
- **Lifecycle Tracking**: Formally calculated the total development time (~24 hours intensive) and velocity (~5.6 commits/hour).
- **Inception Timestamp**: March 8, 2026 (11:06 AM).
- **Velocity Insights**: 134 commits to 16 files shows a highly granular, test-driven approach to feature development.

### 🛠️ **Analytics Automation**
- **New Tool**: Added `docs/scripts/analyze_repo.py` to the repository. This script allows for repeatable, session-based analysis of developer effort using clustered git timestamps. 
- **Usage**: Simply pipe `git log` into the script to get an updated view of project growth.

---

# Release Notes - v1.2.8 (Hotkeys & Documentation)

**Date**: 2026-03-10
**Version**: v1.2.8
**Request ZID**: 20260310025029
**RFC**: [docs/rfcs/20260310025029-release-v1.2.8.md](docs/rfcs/20260310025029-release-v1.2.8.md)

## Highlights

### ⌨️ **Simplified Hotkeys**
- **Modifier Removal**: Context Copy (`x`) and Copy Mode Cycle (`z`) no longer require `Ctrl`. Single-key triggers significantly speed up the immersion workflow.
- **Layout Robustness**: Hotkeys are now case-insensitive and fully mapped for both **English** and **Russian** layouts.

### 📖 **Comprehensive Documentation**
- **Inline Manual**: `input.conf` has been fully reorganized and commented. Every shortcut now includes an explanation of its purpose, helping users master the "Smart Spacebar," "Drum Mode," and "Autopause" features.
- **Grouped Structure**: Keys are now logically categorized into Navigation, Language-Specific, and Feature Toggle sections.

---

# Release Notes - v1.2.6 (Keybinding Source of Truth)

**Date**: 2026-03-10
**Version**: v1.2.6
**Request ZID**: 20260310024112
**RFC**: [docs/rfcs/20260310024112-release-v1.2.6.md](docs/rfcs/20260310024112-release-v1.2.6.md)

## Highlights

### 📋 **Single Source of Truth for Keybindings**
- **Consolidated Authority**: Removed the last hardcoded key (`"c"` for Drum Mode) from `lls_core.lua`. All 11 script bindings now use `nil` defaults, making `input.conf` the exclusive keybinding authority.
- **Zero Script Keys**: To change any hotkey, edit only `input.conf`. No script files need modification.

### 🧹 **Repository & Cache Cleanup**
- **Git Cache Optimization**: Removed `scripts/old_copy_sub.lua` from git tracking to prevent confusion with the new unified FSM core.
- **Ignore Patterns**: Added `__pycache__/` to `.gitignore` to maintain a clean workspace across Python-based developer tools.

---

# Release Notes - v1.2.4 (Drum Sync & Compatibility Guards)

**Date**: 2026-03-10
**Version**: v1.2.4
**Request ZID**: 20260310020401
**RFC**: [docs/rfcs/20260310020401-release-v1.2.4.md](docs/rfcs/20260310020401-release-v1.2.4.md)

## Highlights

### 🥁 **Synchronized Drum Keybindings**
- **FSM-State Prioritization**: Fixed a critical race condition where `master_tick` loop (50ms) was overwriting manual `y` (Secondary Position) toggles. Commands now write to FSM state first.
- **Stale Array Flushing**: Resolved "ghost" subtitles in Drum Mode. Cycling `j` (Secondary SID) to OFF now immediately flushes internal memory arrays upon detecting path changes.
- **Symmetrical Position Restore**: Secondary position is now perfectly restored from FSM memory when Drum Mode is turned OFF or the player shuts down.

### 🛡️ **Smart Feature Compatibility Guards**
- **Positional Integrity**: `y` (Secondary Position) now auto-blocks if the track is `.ass` or if no secondary sub is loaded, preventing layout collisions.
- **Context-Aware Copying**: `Ctrl+Z` (Copy Mode) and `Ctrl+X` (Context Copy) now detect if they are musically/mathematically supported before activating, with clear OSD feedback for SINGLE_SRT or internal-only tracks.

---

# Release Notes - v1.2.2 (Ass Context Copy Fix)

**Date**: 2026-03-10
**Version**: v1.2.2
**Request ZID**: 20260310014540
**RFC**: [docs/rfcs/20260310014540-release-v1.2.2.md](docs/rfcs/20260310014540-release-v1.2.2.md)

## Highlights

### 📋 **Intelligent ASS Context Copy Precision**
- **Symmetrical Dynamic Traversal**: Re-implemented the dynamic leaping extraction loop to completely bypass interleaved foreign-language blocks, fulfilling identical pure-English chronology sentences.
- **Center-Index Snapping**: Fixed a mathematical anomaly where randomly targeting a dual-track Russian baseline as the index center effectively skipped the exact middle string, turning 5-sentence extractions into 4-sentence extractions.
- **Clipboard Output Optimization**: Restored the `is_context` substring compilation shortcut from commit `45e8ae320` to reduce processor parsing overhead when explicitly loading filtered Context chunks.

---

# Release Notes - v1.2.0 (FSM Architecture Overhaul)

**Date**: 2026-03-10
**Version**: v1.2.0
**Request ZID**: 20260310002147
**RFC**: [docs/rfcs/20260310002147-release-v1.2.0.md](docs/rfcs/20260310002147-release-v1.2.0.md)

## Highlights

### ⚙️ **Unified State Machine Architecture**
- **Harmonized Operating Modes**: Replaced the ad-hoc, boolean-driven script collection (`autopause.lua`, `sub_context.lua`, `copy_sub.lua`) with a single, highly-performant Finite State Machine (`scripts/lls_core.lua`).
- **Context Awareness**: Features like Drum Mode and Context Copy are now natively aware of the exact loaded subtitle configuration (SRT vs ASS, Single vs Dual). This guarantees features activate only when mathematically supported.
- **Optimized Performance**: Consolidated all internal script timers into a single master tick loop, completely removing race conditions and lowering overall CPU overhead.

---

# Release Notes - v1.1.0 (ASS Context Copy Enhancements)

**Date**: 2026-03-09
**Version**: v1.1.0
**Request ZID**: 20260310000706
**RFC**: [docs/rfcs/20260310000706-release-v1.1.0.md](docs/rfcs/20260310000706-release-v1.1.0.md)

## Highlights

### 📋 **Intelligent ASS Context Copy**
- **Dual-Track Stability**: Context Copy (`Ctrl X`) robustly bridges interleaved language tracks (e.g., Russian translation chunks mixed between English subtitle lines) to fetch unified dialogue.
- **Karaoke Sentence Reconstruction**: Fragments of word-by-word karaoke highlights are now intelligently rebuilt into complete, coherent chronological sentences for clipboard exportation.
- **Targeted Context Range**: Requesting previous and next lines now specifically respects target language (filtering out translation noise) to provide pure context chunks.

---

# Release Notes - v1.0.0 (Subtitle Context & Autopause Suite)

**Date**: 2026-03-09
**Version**: v1.0.0
**Request ZID**: 20260308233056
**RFC**: [docs/rfcs/20260309002123-release-v1.0.0.md](docs/rfcs/20260309002123-release-v1.0.0.md)

## Highlights

### 🚀 **Smart Spacebar (Hold-to-Play)**
- **NEW**: Press and **HOLD** down the spacebar to temporarily unpause and smoothly bypass all word-by-word or end-of-phrase pause points.
- **TAPPING** the spacebar (< 200ms) functions as a standard Play/Pause toggle. 
- Integrated directly into `input.conf` for a seamless player experience.

### 🥁 **Drum Context Mode ('c')**
- Added a rolling context engine that displays previous and future subtitles around the active line.
- Smart "Stacking" logic ensures primary and secondary context drums never overlap when both are at the bottom of the screen.
- **Safety Check**: Automatically disables on `.ass` files to protect complex karaoke formatting.

### ⏸️ **Dual-Track Aware Autopause ('P' / 'K')**
- Redesigned `autopause.lua` to intelligently scan both primary and secondary tracks.
- Word-by-word pausing now works even if your "acquisition" track is set to the secondary position.
- Refined skip-logic to prevent "double-pausing" between languages.

### 🎨 **Minimalist Styled OSD**
- All status messages (Drum, Autopause, Position, Visibility) now use a unified **Left-Center** style.
- Reduced font size to **20pt** and duration to **500ms** to eliminate immersion distractions.
- Added custom OSD for **OSC Visibility (TAB)** and **Subtitle Positions (y)**.

## Key Fixes & Improvements
- **Dual-Layout Support**: Fully mapped English (EN) and Russian (RU) hotkeys in `input.conf` for all features.
- **Scaling Fixes**: `fixed_font.lua` now protects `.ass` files while maintaining readability for `.srt`.
- **Logic Sync**: `s` and `j` keys are now fully synchronized with Drum Mode and OSD status.
- **Configurable Timeout**: Added `osd_msg_duration` to all script settings for uniform adjustment.

## How to Update
1.  Overwrite your `input.conf` with the latest version.
2.  Delete obsolete standalone scripts (`autopause.lua`, `copy_sub.lua`, `sub_context.lua`) from your `scripts/` folder.
3.  Place the new unified `lls_core.lua` inside your `scripts/` folder.
4.  Refresh your `mpv.conf` to include the standard subtitle position defaults (10/90).
