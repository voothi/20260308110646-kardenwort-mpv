## MODIFIED Requirements

### Requirement: Ctrl+MMB Commit
The Drum Window SHALL commit the accumulated `ctrl_pending_set` to a saved Anki export when the user Ctrl+MMB-clicks any word already in the set.

#### Scenario: Successful commit of a multi-word set
- **WHEN** `ctrl_pending_set` contains two or more words (potentially from different subtitle lines)
- **AND** the user Ctrl+MMB-clicks a word that is a member of `ctrl_pending_set`
- **THEN** the system SHALL sort the accumulated words in document order (by line index, then word index), join them with a single space, and pass the resulting term string to the standard Anki export pipeline
- **AND** the context window supplied to the context-extraction function SHALL span from the earliest-selected line (first in document order) to the latest-selected line (last in document order), each padded by `anki_context_lines` lines on either side, ensuring the composed term is always locatable within the supplied context
- **AND** the export timestamp SHALL be set to the `start_time` of the earliest-selected line (first in document order)
- **AND** `ctrl_pending_set` SHALL be cleared
- **AND** the committed words SHALL subsequently be rendered by the visual highlight engin in the correct saved state. If the words form a contiguous block, they are rendered orange; if they are non-contiguous, they are assigned the special split-word color (e.g., purple).

#### Scenario: Ctrl+MMB on non-member falls back to plain MMB
- **WHEN** `ctrl_pending_set` is non-empty (or even empty)
- **AND** the user Ctrl+MMB-clicks a word that is NOT in `ctrl_pending_set`
- **THEN** the system SHALL treat the event identically to a plain MBTN_MID single click: export only the word under the cursor (or commit any active LMB drag selection)
- **AND** `ctrl_pending_set` SHALL NOT be modified

#### Scenario: Commit with single-word set
- **WHEN** `ctrl_pending_set` contains exactly one word
- **AND** the user Ctrl+MMB-clicks that word
- **THEN** the system SHALL export it as a single-word term, identical in result to a plain MMB single-click export
