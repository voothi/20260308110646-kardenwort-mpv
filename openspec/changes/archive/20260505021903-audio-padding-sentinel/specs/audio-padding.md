# Specs: Audio Padding (ZID: 20260505021903)

## ADDED Requirements

### Requirement: audio-padding:REQ-1 (Configuration)
The system MUST support `audio_padding_start` and `audio_padding_end` options in milliseconds, accessible via `mpv.conf`.

#### Scenario: User sets custom padding
- **WHEN** `lls-audio_padding_start=150` and `lls-audio_padding_end=300` are set.
- **THEN** The system uses 0.15s pre-roll and 0.3s post-roll for all subtitle boundaries.

### Requirement: audio-padding:REQ-2 (Padded Seeking)
Seeking to a subtitle (previous/next/replay) MUST target the `start_time` minus the configured `audio_padding_start`.

#### Scenario: Navigating to next subtitle
- **WHEN** User presses `d` to go to a subtitle starting at 00:10.000 with 200ms padding.
- **THEN** The player seeks to 00:09.800.

### Requirement: audio-padding:REQ-3 (Padded Autopause)
In `Autopause ON` mode, the player MUST pause at `end_time` plus the configured `audio_padding_end` (minus `pause_padding`).

#### Scenario: Autopause with tail
- **WHEN** Subtitle ends at 00:12.000 with 200ms padding and 150ms `pause_padding`.
- **THEN** The player pauses at 00:12.050 (12.200 - 0.150).

### Requirement: audio-padding:REQ-4 (Context Persistence)
The system MUST maintain the "Active Subtitle" context (highlighting and automation) until the current subtitle's padded tail has finished, even if the next subtitle has technically started.

#### Scenario: Dense subtitles with padding
- **WHEN** Sub A ends at 10.0s and Sub B starts at 10.1s, with `audio_padding_end` of 200ms.
- **THEN** The script MUST NOT switch focus to Sub B until 10.2s is reached.
