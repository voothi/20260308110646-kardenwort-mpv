## Purpose
Ensure dynamic border-style overrides prevent native background-box artifacts when custom OSD surfaces are active.
## Requirements
### Requirement: Scoped Border Override Activation
The system SHALL temporarily set `osd-border-style` to `outline-and-shadow` whenever custom UI surfaces require explicit native background suppression.

#### Scenario: Custom UI activation
- **WHEN** a custom OSD surface requiring border override becomes active
- **THEN** the system SHALL apply `outline-and-shadow` as the active border style.

### Requirement: Border Style Restoration
The system SHALL persist the prior border style and restore it after the override lifecycle ends.

#### Scenario: Custom UI deactivation
- **WHEN** the final active owner of the dynamic border override is released
- **THEN** the system SHALL restore the previously saved `osd-border-style` value.

### Requirement: Override Coverage Across Active OSD Text
While override is active, the override SHALL apply to OSD text events rendered by the managed custom UI surface.

#### Scenario: Background-box suppression during active override
- **GIVEN** global style is `background-box`
- **WHEN** the managed UI surface is rendered under active override
- **THEN** UI text SHALL render without native per-line black background boxes.

### Requirement: Tooltip Border-Style Ownership
The tooltip surface SHALL explicitly own its native border/background-box isolation policy while visible, instead of inheriting accidental behavior from the parent DW, DM, or SRT mode.

#### Scenario: Tooltip visible in DW
- **WHEN** the tooltip is visible while Drum Window is active
- **THEN** the tooltip SHALL render under the same custom UI border-style lifecycle as the Drum Window overlay
- **AND** closing or clearing the tooltip SHALL release only the tooltip's own override ownership without disturbing other active UI owners.

#### Scenario: Tooltip visible in DM
- **GIVEN** Drum Mode is active
- **AND** global `osd-border-style` is `background-box`
- **WHEN** the tooltip is displayed
- **THEN** the tooltip SHALL prevent native background-box leakage on its own text events
- **AND** the parent Drum Mode subtitle surface SHALL remain visually stable while the tooltip is visible.

#### Scenario: Tooltip style policy is deterministic
- **WHEN** tooltip rendering selects a border isolation policy
- **THEN** the selected policy SHALL be represented in one shared style context for the whole tooltip render
- **AND** the renderer SHALL NOT mix scoped override and in-band neutralization in conflicting ways for the same tooltip event.

### Requirement: Configurable Tooltip Native Box Policy
The system SHALL support an explicit tooltip native-box policy with an automatic default so advanced users can recover from platform-specific mpv/libass border-style behavior without mode-specific option sprawl.

#### Scenario: Automatic policy
- **GIVEN** `tooltip_native_box_policy` is unset or `auto`
- **WHEN** the tooltip is rendered
- **THEN** the system SHALL choose the policy that preserves DW-equivalent tooltip appearance without introducing native per-line boxes.

#### Scenario: Forced neutralization policy
- **GIVEN** `tooltip_native_box_policy` is `neutralize`
- **WHEN** the tooltip is rendered under global `background-box`
- **THEN** the renderer SHALL use in-band ASS tags to suppress native line boxes for tooltip text events.

#### Scenario: Forced override policy
- **GIVEN** `tooltip_native_box_policy` is `override`
- **WHEN** the tooltip is visible
- **THEN** the system SHALL use the scoped UI border override lifecycle for tooltip rendering.

