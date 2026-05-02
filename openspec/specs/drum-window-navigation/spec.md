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
- **THEN** the yellow pointer SHALL land on and highlight the punctuation token.

#### Scenario: Selecting punctuation via mouse
- **WHEN** the user clicks on a punctuation token in the Drum Window
- **THEN** the yellow pointer SHALL land on and highlight that specific punctuation token.

### Requirement: Virtual Seek Target
The system SHALL calculate the next seek target based on a virtual `DW_SEEK_TARGET` to bypass engine latency during rapid seeking.

#### Scenario: Virtual Seek Target
- **WHEN** the user holds `d` for rapid seeking
- **THEN** the system SHALL calculate the next seek target based on a virtual `DW_SEEK_TARGET` to bypass engine latency.

## Context

### Historical Regression Context
This implementation reconciles several critical project states to prevent known regressions:

- **Commit `af9c776` Alignment**: Restored the edge-aware "Paged" jump targeting. When playing, the system jumps so the active line is at the top margin, maximizing visible upcoming context.
- **Commit `d264b61` Alignment**: Restored independent cursor behavior.
  - In Book Mode, manual seeking (`a`/`d`) moves only the video focus (white).
  - In Regular Mode, selection follows player but word-focus resets on every line change to prevent "phantom" yellow highlights.
- **Commit `38d2f94` Regression Fix**: Resolved responsiveness issues where `a`/`d` were blocked by conflicting repeat timers.
