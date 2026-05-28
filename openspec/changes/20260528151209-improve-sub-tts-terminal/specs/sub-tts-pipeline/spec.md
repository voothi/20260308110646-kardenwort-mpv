## MODIFIED Requirements

### Requirement: Progress reporting
The system SHALL report processing progress to stdout.
When executing in a TTY environment, the system SHALL output a premium, dynamic, carriage-returned progress bar that updates in-place during both the TTS synthesis stage and the speed adjustment stage.
The progress bar SHALL show:
- A visual progress meter using green and grey blocks (matching `youtube-downloader`'s pip style).
- The current cue progress counter (e.g., `[3/150]`) enclosed in dim grey brackets to match pip console style.
- A descriptive label of the current action and cue (e.g., `Synthesizing cue 3` or `Adjusting speed for cue 3`).

When executing in a non-TTY environment, the system SHALL log progress using standard line-based stdout but SHALL throttle the frequency (e.g., logging progress updates at regular percentage steps or increments, such as every 10%) to prevent log clutter.

Upon completion of each stage or of the entire pipeline, the system SHALL clean the terminal line of any carriage-returned characters and print standard clear summary messages (such as success or warning logs) on new lines.

#### Scenario: TTY progress reporting
- **WHEN** processing a subtitle file in a TTY environment
- **THEN** the system SHALL output a carriage-returned progress bar on stdout updating in-place using `\r`
- **AND** the cue counter brackets SHALL be wrapped in ANSI dim grey codes
- **AND** the system SHALL print the final summary messages on clean new lines

#### Scenario: Non-TTY progress reporting
- **WHEN** processing a subtitle file in a non-TTY environment
- **THEN** the system SHALL output progress line-by-line without carriage returns
- **AND** the system SHALL throttle progress lines to prevent bloating the log files
