## MODIFIED Requirements

### Requirement: Purple Depth Calculation (Removed from rendering)
The `calculate_highlight_stack` function SHALL continue to compute and return `purple_depth` as an internal value, but rendering code SHALL NOT use `purple_depth` to select color shades. The `purple_depth` return value is deprecated for color selection purposes.

- **Rationale**: The footprint-based depth counter increments for adjacent non-nested groups, producing misleading darker shading on boundary words. Since correct structural nesting detection is too expensive per-token per-frame, depth-based shading for purple is removed entirely.
- **Color selection**: When `purple_stack > 0`, the rendering engine SHALL always use `Options.anki_split_depth_1` (or its fallback `"FF88B0"`), ignoring `purple_depth`.

#### Scenario: Adjacent non-nesting purple groups render flat
- **WHEN** two distinct split-match terms have spatial footprints that touch but do not nest
- **AND** a word in one group is adjacent to a word in the other group
- **THEN** both words SHALL render in the same flat `anki_split_depth_1` shade
- **AND** neither word SHALL be darkened relative to the other

#### Scenario: Orange+purple mix renders flat
- **WHEN** a word is covered by both an orange (contiguous) match and a purple (split) match
- **THEN** the rendering engine SHALL use `anki_mix_depth_1` (flat)
- **AND** SHALL NOT compute or use `mix_depth` based on `purple_depth`
