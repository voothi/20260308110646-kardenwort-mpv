# Spec: Reader Cue Timing

## Context

When sub-viewer generates an SRT from a plain-text or Markdown file, it assigns a
duration to each subtitle cue based on reading-speed estimates. Long subtitles that
wrap to multiple display lines were previously capped at a flat 7-second maximum,
causing them to disappear before a reader could finish — particularly noticeable on
190+ character prose lines that naturally span two or three visual rows.

Additionally, all timing parameters were compile-time constants in `viewer.py` with
no way to adjust them without editing the source file.

## ADDED Requirements

### Requirement: Per-line Duration Cap

The maximum cue duration must scale proportionally with the number of display lines
in the cue, rather than using a single flat ceiling.

#### Scenario: Single-line cue respects base cap

- **GIVEN** `READER_MAX_CUE_SECONDS = 7.0`
- **WHEN** a cue contains one display line
- **THEN** its duration must not exceed 7.0 seconds

#### Scenario: Two-line cue gets twice the cap

- **GIVEN** `READER_MAX_CUE_SECONDS = 7.0`
- **WHEN** a cue contains two display lines (joined by `\n`)
- **THEN** its duration must not exceed 14.0 seconds

#### Scenario: Long prose line breaks the old 7-second ceiling

- **WHEN** a prose sentence of 175+ characters is wrapped to 2 display lines at
  90 chars/line
- **THEN** the estimated duration must exceed 7.0 seconds

### Requirement: Configurable Reader Timing via mpv.conf

All reader timing parameters must be overridable from `mpv.conf` using the
`kardenwort-reader_*` script-opts namespace, without editing `viewer.py`.

Supported keys:

| mpv.conf key                              | Controls                        | Type  | Default |
|-------------------------------------------|---------------------------------|-------|---------|
| `kardenwort-reader_max_cue_seconds`       | Per-line duration ceiling       | float | 7.0     |
| `kardenwort-reader_min_cue_seconds`       | Minimum cue duration floor      | float | 1.2     |
| `kardenwort-reader_min_date_seconds`      | Minimum duration for date cues  | float | 2.5     |
| `kardenwort-reader_cps`                   | Characters per second           | float | 15.0    |
| `kardenwort-reader_wpm`                   | Words per minute                | float | 180.0   |
| `kardenwort-reader_max_chars_per_line`    | Line-wrap threshold (chars)     | int   | 90      |

#### Scenario: Override max_cue_seconds via script-opts-append

- **WHEN** `mpv.conf` contains `script-opts-append=kardenwort-reader_max_cue_seconds=11.0`
- **AND** sub-viewer generates an SRT from a text file
- **THEN** no cue duration exceeds `11.0 × display_lines` seconds

#### Scenario: Override via inline script-opts

- **WHEN** `mpv.conf` contains `script-opts=kardenwort-reader_wpm=200.0,...`
- **THEN** the word-based duration estimate uses 200 wpm

#### Scenario: Date cue receives a dedicated minimum floor

- **WHEN** a cue's text contains a recognizable date (e.g. "May 24, 2026", "2026-05-24", "24 May 2026")
- **THEN** the cue duration must be at least `min_date_seconds` (default 2.5s)
- **AND** if the natural estimate already exceeds the floor, it is not reduced

#### Scenario: Month name alone is not a date

- **WHEN** a cue contains only a month name without a day and year (e.g. "May flowers bloom")
- **THEN** the date floor is not applied

#### Scenario: Invalid value is silently ignored

- **WHEN** a `kardenwort-reader_*` value cannot be parsed as a number
- **THEN** the corresponding global retains its default value

#### Scenario: mpv.conf not found

- **WHEN** no `mpv.conf` exists anywhere in the search path
- **THEN** sub-viewer starts normally using built-in defaults

## Verification

- Set `script-opts-append=kardenwort-reader_max_cue_seconds=10` in `mpv.conf`,
  drag a long-prose `.txt` file onto sub-viewer, and confirm subtitle durations
  for two-line entries reach up to ~10–12 seconds instead of capping at 7.
- Remove or comment the line to confirm defaults are restored on the next run.
