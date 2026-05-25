## Purpose
Define Sub Viewer launcher behavior for subtitle-first playback and reader text conversion workflows, including deterministic dual-track generation and conflict-safe output handling.
## Requirements
### Requirement: Interactive Standalone Subtitle Playback
The system MUST allow launching mpv to play subtitle files directly on a static black background canvas without requiring a real video track.

#### Scenario: Drag-and-drop subtitle launching
- **WHEN** the user launches the sub-viewer shortcut passing a subtitle file as an argument
- **THEN** mpv SHALL open and render the subtitles on a fully seekable black background

### Requirement: Dynamic Timeline Bounding
The system MUST automatically adjust the playback timeline length to match the duration of the loaded subtitle file.

#### Scenario: Small subtitle files
- **WHEN** a subtitle file of 12 minutes is loaded
- **THEN** the mpv player seekbar total duration SHALL display exactly 12 minutes and 2 seconds

### Requirement: Reader Input Support For Plain Text
The sub-viewer MUST support opening plain text files (`.txt`, `.md`, `.rst`, `.log`) by generating temporary reading subtitles without mutating the original source file.

#### Scenario: Single text input
- **WHEN** the user sends one supported text file via SendTo
- **THEN** the launcher SHALL generate a sidecar `.srt` reader file and open it in mpv
- **AND** the original text file content SHALL remain unchanged

### Requirement: Paired Text Inputs As Dual Subtitles
The sub-viewer MUST support two selected text files as synchronized dual subtitle tracks.

#### Scenario: Two text files selected
- **WHEN** two supported text files are sent together
- **THEN** the launcher SHALL generate primary and secondary reader `.srt` files
- **AND** the secondary track SHALL be loaded as `--secondary-sid`
- **AND** cue boundaries SHALL be synchronized using primary track timings

### Requirement: Mismatched Line Count Tolerance
Paired text conversion MUST preserve positional pairing by line index, even when file lengths differ.

#### Scenario: Unequal line counts
- **WHEN** the primary and secondary text files have different numbers of non-empty lines
- **THEN** cues SHALL align by index
- **AND** missing sides SHALL be represented as blank placeholders instead of shifting alignment

### Requirement: Deterministic Primary/Secondary Role Selection
The launcher MUST resolve primary/secondary roles deterministically, not by raw Explorer argument order.

#### Scenario: Ordered role selection
- **WHEN** selected files include numbered stems (`text1`, `text2`, `text3`) or language suffixes (`en`, `de`, `ru`)
- **THEN** primary/secondary role selection SHALL prioritize `1 -> 2 -> 3`
- **AND** language priority SHALL prefer `en` before `de` before `ru`

### Requirement: Conflict-Safe Reader SRT Output Layout
Reader `.srt` output naming MUST avoid polluting the source directory with repeated ZID postfix files.

#### Scenario: No existing sidecar srt
- **WHEN** no `basename.srt` exists
- **THEN** the generated reader subtitle SHALL be written as `basename.srt` in the source directory

#### Scenario: Existing sidecar srt conflict
- **WHEN** `basename.srt` already exists
- **THEN** the launcher SHALL create a `ZID` subdirectory under the source directory
- **AND** generated files SHALL be written there as plain `basename.srt` names with numeric suffix fallback

#### Scenario: Paired output with one-side conflict
- **WHEN** one of the paired text files already has an existing `basename.srt`
- **THEN** both generated paired outputs SHALL use the same `ZID` subdirectory for coordinated output

### Requirement: Reader Cue Serialization Uses Native SRT Line Breaks
The sub-viewer reader conversion pipeline MUST serialize wrapped cue text using native SRT newline characters and MUST NOT emit ASS break markers (`\N`) inside cue payload text.

#### Scenario: Single text input serialization
- **WHEN** a supported reader text file (`.txt`, `.md`, `.rst`, `.log`) is converted to a reader `.srt`
- **THEN** each wrapped cue payload SHALL contain literal line breaks where wrapping occurs
- **AND** cue payload text SHALL NOT contain serialized `\N` markers.

#### Scenario: Paired text input serialization
- **WHEN** two supported text files are converted via paired reader workflow
- **THEN** both generated primary and secondary `.srt` outputs SHALL use native SRT line breaks for wrapped cue payloads
- **AND** neither output SHALL contain serialized `\N` markers in cue payload text.

### Requirement: Reader Cue Spacing Integrity
Reader cue generation MUST preserve textual spacing fidelity around wrapped boundaries, avoiding synthetic double spaces created by marker conversion.

#### Scenario: Wrapped cue boundary spacing
- **WHEN** long lines are split into wrapped cue payload lines
- **THEN** each emitted payload line SHALL be boundary-trimmed without synthetic leading/trailing spaces caused by break-marker serialization
- **AND** hyphenated tokens (for example `high-bandwidth`, `data-center`, `дата-центров`) SHALL remain intact without injected interior spaces.

## Discussion Anchors
- `20260517144548` text files as reader mode
- `20260517155418` enable dual text-file SendTo workflow
- `20260517155733` apply robust unequal-line pairing logic
- `20260517160256` adopt Subtitle Edit-inspired duration heuristic
- `20260517162045` secondary timecodes must follow primary
- `20260517162358` paired conflict handling when only one side already has `.srt`
- `20260517163403` deterministic `1,2,3` and `en,de,ru` role ordering
- `20260517164300` move conflict output from ZID filename suffix to ZID subdirectory
