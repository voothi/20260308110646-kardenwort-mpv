## Why

This change formalizes the Drum Window Evolution & Static Reading Mode introduced in Release v1.2.16. The Drum Window has been transformed from a scrolling list into a comprehensive **Static Reading Mode**. This update addresses the need for independent navigation and precise text selection within the immersion environment, ensuring that video playback does not interfere with the user's reading or extraction workflow.

## What Changes

- Implementation of **Viewport Decoupling**: Introducing **Follow Mode** (synchronized with playback) and **Manual Mode** (frozen viewport for static reading/selection).
- Implementation of **Multi-line & Substring Selection**: The navigation system now supports range selection using the `Shift` modifier (word-by-word and line-by-line).
- Implementation of **Seek Synchronization**: Manual seeks (`a`/`d`) now automatically clear selections and re-enable Follow Mode to keep the viewport in sync with playback.
- Visual & Layout Polishing: Integration of `\q0` subtitle wrapping to prevent line overlapping and optimization of line spacing for maximum context visibility.

## Capabilities

### New Capabilities
- `drum-window-reading-mode`: A specialized operational state that provides a static, flicker-free environment for intensive reading and text selection.
- `multi-line-substring-selection`: Enhanced text processing logic that allows for the extraction of specific word ranges across multiple subtitle boundaries.

### Modified Capabilities
- None (Core component evolution).

## Impact

- **Reading Efficiency**: A stable visual environment for analyzing complex dialogue without the distraction of automatic scrolling.
- **Extraction Precision**: Ability to selectively harvest phrases or sentences spanning multiple lines with a single clipboard command.
- **Workflow Fluidity**: Automatic recovery of Follow Mode on seek ensures the system remains responsive to the video state.
