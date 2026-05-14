# Drum Window Navigation

## Purpose
Define the scrolling, targeting, and state management behavior for the primary navigation mode.
## Requirements
### Requirement: Unified ensure visible logic
The Drum Window SHALL implement a `dw_ensure_visible(line_idx, paged)` function that supports both incremental and jump-based scrolling.

#### Scenario: Manual Navigation (Pushed)
- **WHEN** `dw_ensure_visible` is called with `paged = false` and `line_idx` is outside the margin
- **THEN** the viewport center SHALL move incrementally to bring `line_idx` exactly into the margin zone.

#### Scenario: Playback Navigation (Paged)
- **WHEN** `dw_ensure_visible` is called with `paged = true` and `line_idx` hits the bottom margin
- **THEN** the viewport center SHALL jump forward such that `line_idx` becomes aligned with the top margin (leaving `dw_scrolloff` lines above).

### Requirement: Configurable Context Margins
The system SHALL use `Options.dw_scrolloff` to determine the number of lines to keep as context at the top and bottom of the Drum Window during all automated scrolling operations.

#### Scenario: Margin Configuration
- **WHEN** `dw_scrolloff` is set to `5` in `mpv.conf`
- **THEN** both `paged` and `pushed` scrolling logic SHALL maintain a 5-line buffer from the viewport edges.

### Requirement: Dual-Track Viewport Synchronization in Drum Mode
When Drum Mode renders both primary (lower) and secondary (upper) tracks, the secondary viewport SHALL remain synchronized to the primary viewport context.

#### Scenario: Follow mode synchronization (Book Mode OFF)
- **WHEN** Drum Mode follow-leading is active and playback advances
- **THEN** the secondary (upper) viewport SHALL track the same effective viewport context as the primary (lower) viewport
- **AND** the upper track SHALL NOT remain independently center-locked while the lower track follows context behavior.

#### Scenario: Paged synchronization (Book Mode ON)
- **WHEN** Book Mode is ON in Drum Mode and paged viewport updates occur
- **THEN** the secondary (upper) viewport SHALL apply the same effective page/offset transition as the primary (lower) viewport
- **AND** both tracks SHALL move together across page boundaries.

### Requirement: Independent Pointer and Selection States
The Drum Window SHALL maintain separate states for the active video subtitle (white) and the manual navigation cursor (yellow) to allow for decoupled reading and seeking.

#### Scenario: Manual Seek in Book Mode
- **WHEN** the user presses `a` or `d` in Book Mode
- **THEN** the video SHALL seek AND the white active highlight SHALL move AND the yellow cursor highlight SHALL NOT be updated (maintaining its current position).

#### Scenario: Selection Dismissal on Manual Seek
- **WHEN** the user starts manual seeking via `a`/`d` in Book Mode OFF
- **THEN** any active yellow word-focus (`DW_CURSOR_WORD`) SHALL be dismissed (`-1`).

#### Scenario: Automatic Selection Cleanup (Regular Mode)
- **WHEN** the system is in Book Mode OFF and the playback moves to a new subtitle
- **THEN** the yellow line highlight SHALL follow the player AND the yellow word-focus SHALL be reset to `-1`.

#### Scenario: Smart Focus Fallback for Copying
- **WHEN** Book Mode is ON and the user navigates via `a`/`d` (with `DW_FOLLOW_PLAYER` active)
- **THEN** a `Ctrl+C` command SHALL prioritize copying the white (active/navigated) line if no specific word or range selection is active on the yellow pointer.

### Requirement: Targeted Vertical Navigation
The Drum Window SHALL implement word-aware vertical navigation that prioritizes valid word tokens over punctuation and whitespace during line transitions.

#### Scenario: Jumping over symbolic lines
- **WHEN** the user is on a line with words and presses DOWN
- **AND** the next line contains only punctuation (e.g., "...")
- **THEN** the system SHALL jump to the first line below the current one that contains at least one token where `is_word` is true.

#### Scenario: Word-only vertical targeting
- **WHEN** the user navigates UP or DOWN
- **THEN** the yellow navigation pointer SHALL exclusively snap to tokens where `is_word` is true.
- **AND** if the target line contains multiple words, the one closest to the current horizontal X-center SHALL be selected.

### Requirement: Precision Horizontal Navigation
The Drum Window SHALL maintain character-level precision for horizontal navigation and mouse interaction to support surgical selection of all logical tokens (including punctuation and symbols).

#### Scenario: Selecting punctuation via keyboard
- **WHEN** the user is on a word and presses RIGHT
- **AND** the next token is a punctuation marker (e.g., a bracket "[")
- **AND** the yellow pointer SHALL landing on and highlight the punctuation token.

#### Scenario: Viewport Follow (Horizontal Jump)
- **WHEN** the user navigates LEFT or RIGHT past the horizontal bounds of a line.
- **THEN** the Drum Window SHALL jump to the new line AND immediately call the viewport tracking engine (`dw_ensure_visible`) to follow the cursor.

### Requirement: Visual Line Navigation (Wrapped Subtitles)
The system SHALL implement "visual-line-aware" navigation for subtitles that are wrapped into multiple rows due to length or font size.

#### Scenario: Visual Line Traversal
- **WHEN** a single subtitle is wrapped into multiple visual lines.
- **AND** the user navigates UP or DOWN.
- **THEN** the pointer SHALL move to the adjacent visual line within the SAME subtitle first.
- **AND** only if the edge of the subtitle is reached SHALL it jump to the next subtitle.

#### Scenario: Intelligent Vertical Entry (Directional Landing)
- **WHEN** jumping to a NEW subtitle via UP or DOWN.
- **THEN** the pointer SHALL land on the FIRST visual line (if moving DOWN) or the LAST visual line (if moving UP) to maintain logical reading flow.

### Requirement: Multi-Mode Highlighting Parity (is_manual)
All navigational logic and visual highlighting (e.g., Yellow Pointer, Pink Selection) MUST behave identically across all interactive rendering layers: **Drum Window (W)**, **Drum OSD (C)**, and **Translation Tooltip (E)**.

#### Scenario: Manual Highlighting Persistence
- **WHEN** a user performs a manual navigation or selection action.
- **THEN** the system MUST ensure the highlight covers the ENTIRE token (including punctuation).
- **AND** this behavior SHALL bypass the surgical punctuation stripping used for automated database matches.

### Requirement: Startup and Recovery Logic
The system SHALL ensure that navigation is available immediately upon script initialization, even before a subtitle has naturally become active.

#### Scenario: Entry from Null Selection (Post-Esc)
- **WHEN** the Drum Window has no active selection (`DW_CURSOR_WORD = -1`).
- **AND** the user presses DOWN.
- **THEN** the yellow pointer SHALL activate on the FIRST visual line of the current logical line.
- **AND** if the user presses UP, it SHALL activate on the LAST visual line.

#### Scenario: Deterministic Null-Selection Entry Source
- **WHEN** the selection is cleared to null state (e.g., final `Esc` stage with `DW_CURSOR_WORD = -1`)
- **AND** the user performs the first navigation action
- **THEN** the "current logical line" SHALL resolve in this order:
1. Active playback subtitle line resolved by the intent snapshot.
2. Otherwise existing standing cursor line (`DW_CURSOR_LINE`) when valid.
- **AND** this source resolution SHALL be identical in Drum Window (W) and Drum Mode (C).

#### Scenario: First LEFT/RIGHT After Null Selection
- **WHEN** `DW_CURSOR_WORD = -1` and the user presses RIGHT on the resolved current logical line
- **THEN** the pointer SHALL activate on the first navigable token of that line.
- **AND** pressing LEFT in the same state SHALL activate on the last navigable token of that line.
- **AND** this activation rule SHALL NOT be substituted with a center-word heuristic unless a separate requirement explicitly enables such mode.

#### Scenario: Null Selection After Manual Seek/Scroll
- **WHEN** `DW_CURSOR_WORD = -1` (pointer cleared) and the user performs manual subtitle navigation (`a`/`d`) or manual viewport scrolling
- **THEN** the standing logical line used for the next pointer activation SHALL be synchronized to the latest manual context:
1. manual seek target line (for `a`/`d`),
2. otherwise current manual viewport center line (for explicit scroll),
3. otherwise active playback line.
- **AND** the next `UP`/`DOWN` or `LEFT`/`RIGHT` activation SHALL use that synchronized line instead of a stale pre-seek/pre-scroll line.

#### Scenario: First Null UP/DOWN Activation Is Line-Locked
- **WHEN** pointer state is null (`DW_CURSOR_WORD = -1`)
- **AND** the first activation is `UP` or `DOWN`
- **THEN** activation SHALL be line-locked to the resolved current logical line for that first step
- **AND** it SHALL NOT fall through to adjacent subtitle lines if a targeted visual-row probe on that line fails.

#### Scenario: Startup Snap
- **WHEN** the application starts AND the user performs a navigation action before playback has reached a subtitle.
- **THEN** the system SHALL automatically snap the cursor to the nearest boundary (start or end of track) to prevent navigation deadlocks.

### Requirement: Architectural Integrity
- **Unified Engine**: ALL rendering and navigation components MUST utilize the unified `ensure_sub_layout` engine to ensure visual line boundaries are calculated consistently across all modes.
- **Defensive Design**: Core navigation functions SHALL implement safety fallbacks for missing layout data to ensure crash-free performance during transient states.

#### Scenario: Selecting punctuation via mouse
- **WHEN** the user clicks on a punctuation token in the Drum Window
- **THEN** the yellow pointer SHALL land on and highlight that specific punctuation token.

### Requirement: Virtual Seek Target
The system SHALL calculate the next seek target based on a virtual `DW_SEEK_TARGET` to bypass engine latency during rapid seeking.

#### Scenario: Virtual Seek Target
- **WHEN** the user holds `d` for rapid seeking
- **THEN** the system SHALL calculate the next seek target based on a virtual `DW_SEEK_TARGET` to bypass engine latency.

### Requirement: Intent-Snapshot Activation in DW and DM
DW/DM arrow activation SHALL consume a single resolved navigation-intent snapshot for both Drum Window (`W`) and Drum Mode mini (`C` with `W` closed).

#### Scenario: Null-pointer activation at subtitle boundary
- **WHEN** playback is live and pointer is null (`DW_CURSOR_WORD = -1`)
- **AND** user presses `UP`, `DOWN`, `LEFT`, or `RIGHT` near a subtitle boundary tick
- **THEN** activation SHALL use the intent snapshot's resolved active context for that key intent
- **AND** the yellow pointer SHALL NOT activate from a stale pre-boundary line for the same intent.

### Requirement: Event-Consistent Arrow Semantics
Arrow navigation SHALL apply identical event semantics for EN/RU bindings in DW/DM activation paths.

#### Scenario: EN and RU arrows preserve activation contract
- **WHEN** navigation is triggered by either EN (`UP/DOWN/LEFT/RIGHT`) or RU (`ВВЕРХ/ВНИЗ/ЛЕВЫЙ/ПРАВЫЙ`) bindings
- **THEN** both bindings SHALL follow the same event-type gating and null-activation behavior
- **AND** runtime behavior SHALL remain parity-consistent across both layouts.

## Context

### Historical Regression Context
This implementation reconciles several critical project states to prevent known regressions:

- **Commit `af9c776` Alignment**: Restored the edge-aware "Paged" jump targeting. When playing, the system jumps so the active line is at the top margin, maximizing visible upcoming context.
- **Commit `d264b61` Alignment**: Restored independent cursor behavior.
  - In Book Mode, manual seeking (`a`/`d`) moves only the video focus (white).
  - In Regular Mode, selection follows player but word-focus resets on every line change to prevent "phantom" yellow highlights.
- **Commit `38d2f94` Regression Fix**: Resolved responsiveness issues where `a`/`d` were blocked by conflicting repeat timers.
