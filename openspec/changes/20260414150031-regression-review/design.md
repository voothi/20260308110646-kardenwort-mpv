# Design: Regression Review Strategy (v1.32.0)

## Overview

The regression review focuses on the interaction between the newly implemented file recovery logic and the existing event-driven architecture of the Drum Window. The methodology involves a "Static Logic Analysis" followed by a "Simulated Failure Review" to be executed in Phase 2.

## Components

### 1. TSV Recovery Logic Review
- **Ref**: `load_anki_tsv(force)`
- **Design**: The function now attempts to create a file if `io.open(tsv_path, "r")` fails. 
- **Critical Check**: Verify that `tsv_path` is correctly normalized and that directory structures exist. 
- **Edge Case**: If the file exists but is empty, does the header check correctly handle the logic?

### 2. Error Handling & OSD Stability
- **Ref**: `cmd_toggle_drum_window()`
- **Design**: Direct `pcall` wrapping of the entire toggle logic.
- **Critical Check**: If `FSM.DRUM_WINDOW` is set to `DOCKED` at the start of the `pcall`, but the function fails halfway, the UI might be "logically open" but "visually closed". The design must ensure state rollback on error.

### 3. System Event Observer Robustness
- **Ref**: `sid`, `track-list`, `osd-dimensions` observers.
- **Design**: These are high-frequency events.
- **Critical Check**: Evaluate if excessive `pcall` and `print` overhead impacts performance during rapid seek or dimension changes.

## Integration Plan

The review will be documented in a structured report (Phase 2) covering:
- **Code Walkthrough**: Line-by-line validation of the diff.
- **Requirement Mapping**: Ensuring `tsv-state-recovery` and `drum-window` specs are satisfied.
- **Regression Matrix**: Checking against known "gotchas" in mpv lua (e.g., globals, timer overlaps).
