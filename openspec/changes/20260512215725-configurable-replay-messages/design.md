## Context

Currently, the `cmd_replay_sub` function in `main.lua` uses fixed strings for OSD notifications. This limits the user's ability to customize the UI experience. The project already has a pattern for configurable messages in the seek system (`seek_msg_format`).

## Goals / Non-Goals

**Goals:**
- Move all replay-related OSD strings to the `Options` table.
- Implement a simple templating engine using Lua's `string.gsub`.
- Ensure backwards compatibility by using current strings as defaults.
- Support placeholders for dynamic values (ms, count).

**Non-Goals:**
- Implementing a complex formatting library (standard Lua string manipulation is sufficient).
- Changing the visual style of the OSD (handled by `show_osd`).

## Decisions

### 1. Template Variables
We will use placeholders that mirror the style of `seek_msg_format` but adapted for replay:
- `%m`: The value of `Options.replay_ms` (e.g., "2000").
- `%c`: The value of `Options.replay_count` (e.g., "3").
- `%x`: Conditional count display. If count > 1, returns ` x%c` (OFF) or ` (x%c)` (ON). This simplifies the template for common cases.

### 2. Option Naming
- `replay_msg_format`: Template for Autopause OFF mode (default: `Replay: %mms%x`).
- `replay_on_msg_format`: Template for Autopause ON mode (default: `Replaying segment: %mms%x`).

### 3. Implementation in `cmd_replay_sub`
The logic for formatting will be centralized within `cmd_replay_sub` before calling `show_osd`.

## Risks / Trade-offs

- **[Risk]** Users might use invalid placeholders. 
  - **[Mitigation]** `gsub` will simply ignore non-matching patterns or leave them as-is.
- **[Risk]** Complex templates might exceed OSD length.
  - **[Mitigation]** Standard OSD behavior handles wrapping/truncation; we will provide reasonable defaults.
