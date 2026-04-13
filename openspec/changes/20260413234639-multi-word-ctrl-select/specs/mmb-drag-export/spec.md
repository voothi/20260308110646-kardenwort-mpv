## MODIFIED Requirements

### Requirement: Single-Click Selection Commitment (SCM)
A single click of the MMB over an existing multi-word selection SHALL export the entire selection rather than clearing it. This behavior SHALL only apply when the Ctrl modifier is NOT held; if Ctrl is held, the event is routed to the `ctrl-multiselect` commit handler instead.

#### Scenario: Committing an existing LMB selection (plain MMB)
- **WHEN** there is an active selection (red) in the Drum Window
- **AND** the user clicks MMB within that selection range
- **AND** `ctrl_held` is false
- **THEN** the entire existing selection SHALL be exported (turns orange and saves to Anki)

#### Scenario: Ctrl+MMB on selection member routes to accumulator commit
- **WHEN** there is an active selection (red) in the Drum Window
- **AND** the user Ctrl+MMB-clicks a word within the selection range
- **AND** that word is a member of `ctrl_pending_set`
- **THEN** the event SHALL be routed to the `ctrl-multiselect` commit handler; the red selection SHALL NOT be exported by this event

#### Scenario: Ctrl+MMB on selection non-member falls back to plain MMB
- **WHEN** there is an active selection (red) in the Drum Window
- **AND** the user Ctrl+MMB-clicks a word within the selection range
- **AND** that word is NOT a member of `ctrl_pending_set`
- **THEN** the behavior SHALL be identical to plain MMB: the entire existing red selection SHALL be exported
