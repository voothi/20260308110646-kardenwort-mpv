## MODIFIED Requirements

### Requirement: Download Progress Feedback
The download system SHALL provide progress feedback for downloads.

When executing in a TTY environment, the system SHALL render an in-place, carriage-returned, premium pip-style progress bar (green/grey block aesthetic) for both the video stream and the subtitle stream of every URL.

When executing in a non-TTY environment, the system SHALL emit textual progress lines using a delta-based throttling pattern. For the **video** byte-progress stream, the system SHALL print:
1. The very first progress event (the first emission with a parseable percent value).
2. Every progress event whose percent value has increased by at least 10% since the last printed line.
3. The completion event (the explicit `[download] 100% of ... in ... at ...` line).

For the **subtitle** byte-progress stream (which yt-dlp emits without a percent value), the system SHALL print at least one progress line per subtitle file in non-TTY mode so that subtitle progress is not silently dropped, and SHALL print the subtitle completion summary on a clean new line.

The system SHALL print queue section headers with the per-URL counter brackets (e.g. `[3/10]`) wrapped in dim grey ANSI styling to match the project's premium pip-style cue counter convention.

Upon transition between processing stages (URL → metadata → video stream → subtitle stream → companion-audio stream → final OK summary), the system SHALL call the parameterized line-clearing helper before printing any standalone summary log line, so that no carriage-return residue from prior in-place output leaks into the next line.

#### Scenario: Download in progress
- **WHEN** a video is being downloaded
- **THEN** the system SHALL display download progress
- **AND** the system SHALL show estimated time remaining

#### Scenario: Download completes successfully
- **WHEN** a video download completes successfully
- **THEN** the system SHALL display a success message
- **AND** the system SHALL show the file path of the downloaded video

#### Scenario: Download fails
- **WHEN** a video download fails
- **THEN** the system SHALL display an error message
- **AND** the system SHALL log the error details

#### Scenario: Queue section header styling
- **WHEN** the system prints the section header for one entry in the URL processing queue
- **THEN** the `[idx/total]` counter SHALL be wrapped in ANSI dim grey styling
- **AND** the source label (file name or "Direct URL") SHALL be wrapped in ANSI bold styling
- **AND** in non-TTY environments the styling SHALL collapse to plain text without raw escape sequences

#### Scenario: Non-TTY video progress throttling
- **WHEN** a video download is in progress
- **AND** stdout is not a TTY
- **THEN** the system SHALL print the first parseable progress event
- **AND** SHALL print only subsequent events whose percent value has increased by at least 10% since the last printed event
- **AND** SHALL print the completion event on its own line

#### Scenario: Non-TTY subtitle progress is not silently dropped
- **WHEN** a subtitle file is being downloaded
- **AND** stdout is not a TTY
- **THEN** the system SHALL print at least one subtitle-progress line for that file
- **AND** SHALL print the subtitle completion summary line when the file completes

#### Scenario: Inter-stage transition cleanup
- **WHEN** a TTY-mode in-place progress bar has just been emitted
- **AND** the system is about to print a standalone `[OK]`, `[INFO]`, `[WARN]`, or section header line
- **THEN** the system SHALL call the line-clearing helper before printing the next line
- **AND** no carriage-return residue from the prior bar SHALL appear on the new line

### Requirement: Pip-Style Output and Fallback Log Accuracy
Progress rendering and fallback diagnostics SHALL remain accurate across TTY and non-TTY execution contexts.

TTY detection SHALL be performed once at module import time and cached in a module-level `_IS_TTY` constant. All downstream branching on TTY-versus-non-TTY behavior (including ANSI escape emission, in-place line redraw, the pause-console countdown, and the streaming subprocess wrapper's per-pipe handling) SHALL consult the cached constant, and SHALL NOT call `sys.stdout.isatty()` again at the hot path.

The line-clearing helper SHALL accept a `width` parameter (default 65) and SHALL be used uniformly across the module for every in-place line clear, including the pause-console countdown clear path. Inline ad-hoc `"\r" + " " * N + "\r"` snippets SHALL NOT be used.

Counter brackets in cue/queue progress lines (e.g. `[3/10]`, `[3/150]`) SHALL be wrapped in dim grey ANSI styling to match the project's premium pip-style aesthetic.

#### Scenario: Non-TTY progress output
- **WHEN** progress text is rendered while stdout is not a TTY
- **THEN** progress lines SHALL not contain raw ANSI escape sequences
- **AND** the textual progress information SHALL remain readable in plain logs

#### Scenario: Original-language fallback with no subtitle tracks
- **WHEN** `youtube_download_subtitle_languages` is `"original"`
- **AND** language detection fails
- **AND** neither manual subtitles nor automatic captions are present in metadata
- **THEN** the system SHALL NOT log that it fell back to all subtitles
- **AND** the system SHALL NOT log that it fell back to all auto-subtitles

#### Scenario: Cached TTY constant is the single source of truth
- **WHEN** the module is loaded
- **THEN** `_IS_TTY` SHALL be set exactly once via `sys.stdout.isatty()`
- **AND** the streaming subprocess wrapper's per-pipe branching SHALL use `_IS_TTY` rather than calling `sys.stdout.isatty()` again
- **AND** the pause-console countdown SHALL gate its TTY-only countdown logic on `_IS_TTY` rather than calling `sys.stdout.isatty()` again

#### Scenario: Parameterized line clearing helper
- **WHEN** any code path needs to clear the current console line
- **THEN** it SHALL call the `clear_line(width=...)` helper
- **AND** SHALL NOT emit ad-hoc whitespace-padded carriage returns
- **AND** the helper SHALL emit the standard ANSI `\x1b[K` "erase to end of line" escape followed by `width`-column whitespace padding as a legacy fallback
