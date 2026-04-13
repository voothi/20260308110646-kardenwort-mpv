## Context

Currently, the styling parameters for the three main script-driven HUDs (Drum Mode `c`, Drum Window `w`, and Tooltips) are inconsistently defined. For example, Drum Mode lacks an explicit `bg_opacity` setting for its background boxes, while Drum Window uses hardcoded text alpha. This prevents a truly unified interface where a user can, for instance, set a single transparency level for all "frames" in the application.

## Goals / Non-Goals

**Goals:**
- Implement a symmetrical "Pro" styling schema across all three HUD modes.
- Provide explicit script-level control over background box transparency (`\4a`) for every mode.
- Unify parameter naming in `Options` and `mpv.conf` (e.g., transitioning `dw_tooltip_*` to `tooltip_*`).
- Categorize and document these settings in `mpv.conf` for ease of use.

**Non-Goals:**
- Do not attempt to override native MPV subtitle (`srt`) rendering via Lua; standard `sub-*` properties in `mpv.conf` will remain the source of truth for "Normal Mode" but will be documented for parity.

## Decisions

- **Parameter Unification**: All modes will support the following standard variables in the `Options` table:
  - `font_name`, `font_size`, `bold`, `border_size`, `shadow_offset`
  - `bg_color`, `bg_opacity` (mapping to `\4c` and `\4a`)
  - `text_color`, `text_opacity` (mapping to `\1c` and `\1a`)
  
- **Mode Prefixes**:
  - `drum_` (Drum Mode `c`)
  - `dw_` (Drum Window `w`)
  - `tooltip_` (Tooltip system - renamed from `dw_tooltip_`)

- **Renderer Refactor**: The `draw_drum`, `draw_dw`, and `draw_dw_tooltip` functions will be updated to explicitly inject these tags into their ASS strings. This removes the dependency on global OSD defaults for these visual properties.

- **Defaults Sync**: Defaults will be synchronized to `bg_opacity = "60"` (ASS Hex) and `text_color = "CCCCCC"` / `"FFFFFF"` across the board to match the new Dark Theme aesthetic.

- **Font Normalization**: The Drum Window (`w`) font size is normalized to **`38`** to visually match the perceptual weight of the **`34`** proportional font used in Drum Mode (`c`).

- **Documentation Preservation**: During the `mpv.conf` reorganization, detailed calibration notes (e.g., `vline_h_mul`, `sub_gap_mul`) and alternative styling presets (`MODE 1/2`) will be meticulously preserved and updated to reflect the new variable schema, ensuring no instructional entropy.

## Risks / Trade-offs

- [Risk] Breaking existing user `mpv.conf` settings due to renamed variables (e.g., `dw_tooltip` -> `tooltip`).
  → Mitigation: Keep the `dw_tooltip_` prefix in `lls_core.lua` fallbacks for one version cycle if necessary, but the user explicitly requested "Unify the interface," so a clean break in the config for the sake of schema purity is acceptable here. We will provide a clear `mpv.conf` example.
