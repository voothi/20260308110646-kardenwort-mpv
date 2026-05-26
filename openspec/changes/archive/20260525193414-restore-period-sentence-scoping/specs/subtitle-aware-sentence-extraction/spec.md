## MODIFIED Requirements

### Requirement: Punctuation-Anchored Sentence Scoping
The context extraction system SHALL derive sentence boundaries from the nearest **real** sentence terminator on either side of the selection, scanning **across** subtitle-line NUL sentinels (`\0`). The set of terminator characters SHALL be configurable via `anki_sentence_terminators` (default: `".!?"`). The system SHALL NOT use subtitle-line edges as sentence boundaries when terminators are available. Abbreviations (matched by heuristic or by `anki_abbrev_list`) SHALL NOT count as terminators.

#### Scenario: Sentence spanning multiple subtitle lines
- **WHEN** subtitle N reads `"Es kommt zu kräftigen Niederschlägen,"`, subtitle N+1 reads `"die verbreitet als Schnee liegen"`, subtitle N+2 reads `"bleiben. Autofahrer sollten besonders"`
- **AND** the user selects the word `"verbreitet"` from subtitle N+1
- **THEN** the system SHALL return `"Es kommt zu kräftigen Niederschlägen, die verbreitet als Schnee liegen bleiben."` as the primary sentence
- **AND** the system SHALL NOT truncate the result to a single subtitle line

#### Scenario: Selection spanning multiple sentences
- **WHEN** the user selects a non-contiguous phrase whose first word lies in sentence A and last word lies in sentence B
- **THEN** the system SHALL return the full text from the terminator preceding sentence A's start through the terminator ending sentence B (inclusive)
- **AND** the system SHALL include every intermediate sentence in its entirety

#### Scenario: Backward scan stops at the nearest real terminator
- **WHEN** the joined context contains `"Winterstiefel raus.\0Es kommt zu kräftigen Niederschlägen,\0die verbreitet als Schnee liegen"` and the selection anchors to `"verbreitet"`
- **THEN** the backward scan SHALL stop at `"raus."` (the period immediately preceding the sentence start)
- **AND** the returned sentence SHALL begin with `"Es kommt zu kräftigen Niederschlägen,"`, NOT with `"die verbreitet ..."`

#### Scenario: Forward scan includes the terminating punctuation
- **WHEN** the forward scan finds `.`, `!`, or `?` after the selection
- **THEN** the returned sentence SHALL include that terminator character

### Requirement: No-Terminator Fallback to Full Joined Context
When **neither** the backward nor the forward sentence-terminator scan finds a real terminator within the joined context block (e.g. YouTube auto-subtitles with no punctuation), the system SHALL return the **entire joined context** (all ±`anki_context_lines` subtitle texts, with `\0` sentinels replaced by spaces) as the primary sentence — NOT a single subtitle line. Subsequent word-count truncation (`anki_context_max_words`) SHALL still apply.

#### Scenario: Unpunctuated auto-subtitle block
- **WHEN** the joined context is `"so the next morning I went\0to the store and bought\0three apples and a pear"` (no `.!?` anywhere) and the selection anchors to `"apples"`
- **THEN** the returned sentence SHALL be `"so the next morning I went to the store and bought three apples and a pear"` (entire block, NUL replaced by space)
- **AND** the system SHALL NOT return only `"three apples and a pear"` (the single subtitle line)

#### Scenario: Asymmetric terminator availability
- **WHEN** the backward scan finds a terminator but the forward scan does not
- **THEN** the returned sentence SHALL begin after the backward terminator and extend to the end of the joined context block

### Requirement: Abbreviation-Aware Sentence Boundary Detection
The sentence-scoping scan and the word-level `is_sentence_boundary` check SHALL share abbreviation handling. A token SHALL be classified as an abbreviation when **any** of the following holds:

1. The token matches the heuristic pattern: 1–4 lowercase letters followed by `.` (e.g. `ca.`, `usw.`, `bzw.`, `d.h.`), OR a sequence of single-uppercase-letter+`.` segments (e.g. `z.B.`, `T.CON`); OR
2. The token (including its trailing period) appears in `Options.anki_abbrev_list` (case-insensitive exact match); OR
3. The candidate period participates in a spaced initialism such as `z. B.`.

The configurable allowlist SHALL be additive on top of the heuristic — the heuristic remains primary.

#### Scenario: Heuristic catches short German abbreviation
- **WHEN** the scan encounters `"ca."` immediately before a candidate terminator position
- **THEN** `is_abbreviation("ca.")` SHALL return `true`
- **AND** the scan SHALL continue past this `.`, not treat it as a sentence end

#### Scenario: Allowlist catches token outside the heuristic
- **WHEN** `anki_abbrev_list` contains `"etc."` and the scan encounters `"etc."`
- **THEN** `is_abbreviation("etc.")` SHALL return `true`
- **AND** the scan SHALL skip this `.`

#### Scenario: Genuine sentence end is detected
- **WHEN** the scan encounters `"raus."` and `"raus."` is NOT matched by the heuristic and NOT in `anki_abbrev_list`
- **THEN** `is_abbreviation("raus.")` SHALL return `false`
- **AND** the scan SHALL treat this `.` as a sentence terminator

#### Scenario: Spaced initialism is not split
- **WHEN** the scan encounters `"z. B. Globus"` inside a sentence
- **THEN** neither the period after `"z"` nor the period after `"B"` SHALL truncate the returned sentence

#### Scenario: Word-level boundary check shares the same helper
- **WHEN** `dw_anki_export_selection` evaluates whether the word before the user's selection ends a sentence
- **THEN** it SHALL call the same `is_abbreviation` helper used by the sentence-scoping scan
- **AND** SHALL NOT duplicate the heuristic logic locally

### Requirement: Configurable Abbreviation Allowlist
The system SHALL expose `anki_abbrev_list` as a script option. Its value SHALL be a space-separated list of abbreviation tokens (each including the trailing period). The default value SHALL include common German abbreviations.

#### Scenario: Default value covers common German abbreviations
- **WHEN** the user does NOT set `kardenwort-anki_abbrev_list` in `mpv.conf`
- **THEN** the effective list SHALL include at minimum `z.B.`, `bzw.`, `usw.`, `ca.`, `d.h.`, `u.a.`, `etc.`, `vgl.`, `ggf.`, `bspw.`

#### Scenario: User extends the allowlist
- **WHEN** `mpv.conf` contains `script-opts=kardenwort-anki_abbrev_list=z.B. bzw. usw. ca. Inc. Prof.`
- **AND** the scan encounters `"Prof."` in subtitle text
- **THEN** `is_abbreviation("Prof.")` SHALL return `true`

### Requirement: Configurable Sentence Terminators
The system SHALL expose `anki_sentence_terminators` as a script option whose value is a string of individual terminator characters (no separators between them). Each character in the string is treated as an independent sentence terminator. The default value SHALL be `".!?"`.

#### Scenario: Default terminators
- **WHEN** the user does NOT set `kardenwort-anki_sentence_terminators` in `mpv.conf`
- **THEN** the scan SHALL treat `.`, `!`, and `?` as sentence terminators

#### Scenario: User adds terminator characters
- **WHEN** `mpv.conf` contains `script-opts=kardenwort-anki_sentence_terminators=.!?;`
- **THEN** `;` SHALL be treated as an additional sentence terminator during the scan
- **AND** existing `.!?` behaviour SHALL be preserved

#### Scenario: User narrows terminators
- **WHEN** `mpv.conf` contains `script-opts=kardenwort-anki_sentence_terminators=.`
- **THEN** only `.` SHALL end a sentence — `!` and `?` SHALL be treated as ordinary characters

#### Scenario: Empty or missing value falls back to default
- **WHEN** `anki_sentence_terminators` is set to an empty string
- **THEN** the system SHALL behave as if the default `".!?"` was set

### Requirement: NUL Sanitization in Subtitle Loader
The subtitle parser SHALL strip any NUL bytes from subtitle text before storing, to prevent sentinel collisions in the joined context block.

#### Scenario: Subtitle text with embedded NUL
- **WHEN** a subtitle file contains a NUL byte in its text content
- **THEN** the loader SHALL remove that byte before storing the text in the subtitle table
- **AND** the rest of the subtitle text SHALL be preserved intact

### Requirement: Literal Context Extraction
The `SentenceSource` (context) field in exported Anki cards SHALL preserve the exact punctuation and spacing of the source subtitle by extracting substrings directly from the original text, rather than re-tokenizing and joining word lists.

#### Scenario: Complex punctuation in context
- **WHEN** a subtitle contains `Paketsortierung. [UMGEBUNG]`
- **THEN** the context extraction SHALL return the substring exactly as it appears in the source, including the space between the period and the bracket.

#### Scenario: Multi-line sentence preserves original spacing
- **WHEN** the sentence-scoping scan returns content that originally spanned three subtitle lines joined by `\0`
- **THEN** the `\0` sentinels SHALL be replaced by single spaces in the returned sentence
- **AND** no other whitespace normalization SHALL be applied

## REMOVED Requirements

### Requirement: Subtitle-Boundary Sentence Scoping
**Reason**: Caused the regression where `SentenceSource` was truncated to a single subtitle line even when the real grammatical sentence spanned multiple lines (see proposal.md trace for SRT 287-298). Period-anchored scoping with abbreviation skip handles both punctuated content (correctly extracts the full sentence) and unpunctuated YouTube auto-subs (no-terminator fallback returns the full joined block).

**Migration**: Replaced by `Punctuation-Anchored Sentence Scoping` plus `No-Terminator Fallback to Full Joined Context`. No user action required; re-exporting selections from punctuated SRTs will produce fuller `SentenceSource` values; YouTube auto-sub exports continue to work via the fallback.

### Requirement: Sentinel-Delimited Context Block
**Reason**: Spec text described the `\0` sentinel as the sentence-boundary mechanism; the mechanism remains (sentinels are still embedded in the joined block) but now serves only as a hint for the no-terminator fallback path. The behaviour is captured implicitly by `Punctuation-Anchored Sentence Scoping` (which scans across `\0`) and `No-Terminator Fallback to Full Joined Context` (which uses `\0` to size the block).

**Migration**: No-op for callers; the joined-block construction in `dw_anki_export_selection` is unchanged.
