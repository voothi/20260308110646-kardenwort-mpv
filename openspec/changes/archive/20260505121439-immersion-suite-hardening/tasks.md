# Tasks: Immersion Engine Hardening

## 1. Core State Machine & Padding Hardening

- [x] 1.1 Move `FSM` and `Tracks` table definitions to the top of `lls_core.lua` to prevent global nil reference errors during initialization.
- [x] 1.2 Implement the `IMMERSION_MODE` state (`MOVIE` vs `PHRASE`) with a toggle bound to `Shift+o` (O/Щ).
- [x] 1.3 Update `get_effective_boundaries` to support seamless handover in `MOVIE` mode (`End = Next_Start - Pad`).
- [x] 1.4 Implement the "Jerk-Back" overlap repeat logic in `master_tick` for `PHRASE` mode.
- [x] 1.5 Introduce `FSM.JUST_JERKED_TO` sentinel to prevent visual flickering and focus-backsliding during overlaps.

## 2. Navigation & Autopause Stability

- [x] 2.1 Implement `MANUAL_NAV_COOLDOWN` (500ms) to suspend smart logic during manual seeking (`a`, `d`, `Enter`).
- [x] 2.2 Harden `get_center_index` to prioritize the next subtitle's padded start when the previous sentinel expires.
- [x] 2.3 Explicitly reset `FSM.last_paused_sub_end` in all manual seek handlers to ensure Autopause re-triggers correctly.
- [x] 2.4 Update `tick_autopause` with a `-0.1s` overshoot buffer to prevent missing pause frames.

## 3. Secondary Subtitle Filter

- [x] 3.1 Refactor `cmd_cycle_secondary_sid` to iterate through the `track-list` and filter for `external` tracks only.
- [x] 3.2 Update OSD messaging to display the current track language/label and a count of hidden unsupported internal tracks.

## 4. Parameterization & Documentation

- [x] 4.1 Migrate hardcoded thresholds (`nav_cooldown`, `nav_tolerance`, `autopause_overshoot`) to the `Options` table.
- [x] 4.2 Move the `Shift+o` toggle binding to the global initialization block and parameterize the shortcut via `key_cycle_immersion_mode`.
- [x] 4.3 Restructure `mpv.conf` to group all Immersion Engine parameters into a single logical section with detailed documentation.
- [x] 4.4 Remove all transient `Diagnostic.debug` calls and clean up implementation artifacts.
