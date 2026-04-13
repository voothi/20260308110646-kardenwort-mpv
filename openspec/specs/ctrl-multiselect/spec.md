## ADDED Requirements

### Requirement: Ctrl+LMB Word Accumulation
The Drum Window SHALL accumulate individually-clicked words into a pending Ctrl-select set when the user clicks with LMB while holding the Ctrl modifier key. Each click SHALL toggle the target word's membership: clicking an already-accumulated word removes it; clicking a new word adds it.

#### Scenario: First Ctrl-click starts accumulation
- **WHEN** the user holds Ctrl and clicks LMB on a word in the Drum Window that is not already in the pending set
- **THEN** the word SHALL be added to the `ctrl_pending_set` accumulator and rendered in the pending yellow color (`ctrl_select_color`)

#### Scenario: Ctrl-click on already-accumulated word removes it
- **WHEN** the user holds Ctrl and clicks LMB on a word that is already in `ctrl_pending_set`
- **THEN** the word SHALL be removed from the accumulator and its yellow highlight SHALL disappear

#### Scenario: Ctrl+LMB does NOT trigger drag selection
- **WHEN** the user holds Ctrl and presses LMB
- **THEN** the existing drag-selection (red highlight) SHALL NOT be initiated; accumulator logic takes full precedence

### Requirement: Ctrl-Pending Visual Indicator
Words in the `ctrl_pending_set` SHALL be rendered with a distinct yellow pending-highlight color, visually separate from the red drag-selection and orange saved highlights.

#### Scenario: Yellow pending color applied
- **WHEN** one or more words are in `ctrl_pending_set`
- **THEN** each such word SHALL be wrapped in the ASS color tag corresponding to `ctrl_select_color` (default `#FFE066`) during the next Drum Window render pass

#### Scenario: Yellow cleared on set discard
- **WHEN** the Ctrl key is released and no Ctrl+MMB commit has occurred
- **THEN** `ctrl_pending_set` SHALL be emptied and the yellow highlights SHALL disappear from all affected words on the next render pass

### Requirement: Ctrl+MMB Commit
The Drum Window SHALL commit the accumulated `ctrl_pending_set` to a saved Anki export when the user Ctrl+MMB-clicks any word already in the set.

#### Scenario: Successful commit of a multi-word set
- **WHEN** `ctrl_pending_set` contains two or more words
- **AND** the user Ctrl+MMB-clicks a word that is a member of `ctrl_pending_set`
- **THEN** the system SHALL sort the accumulated words in document order (by line index, then word index), join them with a single space, and pass the resulting term string to the standard Anki export pipeline
- **AND** `ctrl_pending_set` SHALL be cleared
- **AND** the committed words SHALL subsequently be rendered in the standard saved orange highlight

#### Scenario: Ctrl+MMB on non-member falls back to plain MMB
- **WHEN** `ctrl_pending_set` is non-empty (or even empty)
- **AND** the user Ctrl+MMB-clicks a word that is NOT in `ctrl_pending_set`
- **THEN** the system SHALL treat the event identically to a plain MBTN_MID single click: export only the word under the cursor (or commit any active LMB drag selection)
- **AND** `ctrl_pending_set` SHALL NOT be modified

#### Scenario: Commit with single-word set
- **WHEN** `ctrl_pending_set` contains exactly one word
- **AND** the user Ctrl+MMB-clicks that word
- **THEN** the system SHALL export it as a single-word term, identical in result to a plain MMB single-click export

### Requirement: Ctrl-Set Discard on Modifier Release
The system SHALL automatically discard the pending `ctrl_pending_set` whenever the Ctrl key is released without a preceding Ctrl+MMB commit.

#### Scenario: Discard on Ctrl release
- **WHEN** the user releases the Ctrl key
- **AND** no Ctrl+MMB commit has been issued since the last Ctrl-press
- **THEN** `ctrl_pending_set` SHALL be emptied and yellow highlights SHALL be cleared on the next render pass

### Requirement: Configurable Pending Selection Color
The system SHALL expose a `ctrl_select_color` configuration key in `mpv.conf` to allow the user to override the default yellow pending highlight color.

#### Scenario: Custom color applied
- **WHEN** `ctrl_select_color` is set in `mpv.conf` (e.g., `ctrl_select_color=#FFD700`)
- **THEN** the Ctrl-pending highlight SHALL use that color instead of the default `#FFE066`

#### Scenario: Default color used when key absent
- **WHEN** `ctrl_select_color` is not present in `mpv.conf`
- **THEN** the system SHALL default to `#FFE066` for the pending highlight color
