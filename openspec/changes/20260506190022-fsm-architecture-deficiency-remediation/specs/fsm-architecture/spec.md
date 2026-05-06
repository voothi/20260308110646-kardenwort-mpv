## MODIFIED Requirements

### Requirement: Global Media Context Gatekeeping (MEDIA_STATE)
The system SHALL evaluate the current tracks loaded into `FSM.MEDIA_STATE` and adjust dependent capabilities accordingly to prevent renderer crashes and overlay conflicts.

#### Scenario: User loads an ASS tracking format
- **WHEN** track evaluation resolves an ASS-incompatible media context (`FSM.MEDIA_STATE` includes `ASS`)
- **THEN** the system SHALL force `FSM.DRUM = "OFF"` and `FSM.DRUM_WINDOW = "OFF"` in the same transition cycle
- **AND** it SHALL restore native subtitle visibility and position properties from FSM-owned desired state variables.

### Requirement: Specialized Input States (SEARCH_MODE & COPY_MODE)
The system SHALL explicitly track modal interfaces that hijack default keyboard bindings to ensure that user input is correctly routed to transient UI components without triggering core media playback or navigation actions.

#### Scenario: Search Mode Hijack
- **WHEN** `FSM.SEARCH_MODE == true`
- **THEN** it SHALL instantiate a dedicated input grabber, routing all configured search-character bindings away from native bindings into the Search Query buffer (`FSM.SEARCH_QUERY`)
- **AND** it SHALL render the `search_osd` overlay according to the visualization rules defined in the `search-system` spec
- **AND** playback-altering hotkeys SHALL remain suppressed while the modal grabber is active, except explicit search actions bound to modal navigation/commit.

#### Scenario: Search Enter commits selected result
- **WHEN** `FSM.SEARCH_MODE == true` and the user presses the configured Enter key
- **THEN** the system SHALL execute search-result commit behavior (seek to selected result and close or exit search mode)
- **AND** it SHALL NOT invoke native non-search Enter behavior during that modal action.

### Requirement: European Character Search Support
The Search Mode input grabber SHALL support the entry of German umlauts and the eszett character, along with their uppercase variants, by including them in the forced key binding whitelist and by removing those same bindings when search mode exits.

#### Scenario: User types German characters in search field
- **WHEN** `FSM.SEARCH_MODE` is true and the user presses `ä`, `ö`, `ü`, `ß`, `Ä`, `Ö`, `Ü`, or `ẞ`
- **THEN** the OSD SHALL capture these characters, append them to `FSM.SEARCH_QUERY`, and update the search results dynamically.

#### Scenario: Search mode exits cleanly
- **WHEN** `FSM.SEARCH_MODE` transitions from true to false
- **THEN** every forced binding created for search character input, including the German whitelist characters, SHALL be removed in the same lifecycle path
- **AND** no search-character forced binding SHALL remain active after modal exit.

### Requirement: Secondary Position Bounds via Configuration
Secondary subtitle positioning transitions SHALL respect configured FSM bounds rather than hardcoded constants.

#### Scenario: Cycling secondary subtitle position
- **WHEN** `cycle-secondary-pos` is triggered
- **THEN** the system SHALL toggle `secondary-sub-pos` between `Options.sec_pos_top` and `Options.sec_pos_bottom`
- **AND** overlap avoidance SHALL be achieved by validated configuration defaults (for example `sec_pos_bottom = 90` relative to primary `95`), not by implicit runtime clamping.

## ADDED Requirements

### Requirement: Esc Stage Contract Consistency
The system SHALL keep a deterministic staged-Esc contract for Drum Window selection state and ensure documentation and runtime behavior remain aligned.

#### Scenario: Esc peel-back order remains deterministic
- **WHEN** the user triggers `cmd_dw_esc` with active selection state
- **THEN** stage resolution SHALL peel back in order: Pink Set -> Yellow Range -> Yellow Pointer
- **AND** each stage SHALL be independently idempotent so repeated Esc presses do not reintroduce cleared state.

#### Scenario: No implicit window close in selection-stage Esc path
- **WHEN** no staged selection state remains
- **THEN** `cmd_dw_esc` SHALL not implicitly mutate unrelated window lifecycle state in the same command path unless explicitly specified by a separate requirement.

### Requirement: DOCKED Positioning Neutrality by Layout Ownership
In `DOCKED` mode, deterministic visual alignment SHALL be achieved by the dedicated DW layout/render pipeline owning final positioning decisions.

#### Scenario: DOCKED rendering uses deterministic layout ownership
- **WHEN** `FSM.DRUM_WINDOW == "DOCKED"`
- **THEN** the visual stream SHALL be rendered through the DW layout pipeline with deterministic anchors and wrapping rules
- **AND** positioning neutrality MAY be satisfied either by stripping conflicting positioning tags or by rendering paths that do not depend on source `\pos` / `\an` tags.
