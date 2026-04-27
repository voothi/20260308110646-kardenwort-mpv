## Context

The `lls_core.lua` script contains a comprehensive `Options` table for configuring various aspects of the Language Learning Suite (LLS). However, several of these options were missing from the global `mpv.conf` file, making them difficult for users to customize without editing the script directly. Furthermore, a duplicate entry for `book_mode` existed in the script's configuration table.

## Goals / Non-Goals

**Goals:**
- Synchronize `mpv.conf` with `lls_core.lua` to ensure all script options are user-configurable.
- Improve configuration discoverability by adding descriptive comments for interactive and scrolling settings.
- Remove redundant code from the core script.

**Non-Goals:**
- Implementing new features or changing the logic of existing options.
- Refactoring the entire options handling system.

## Decisions

- **Direct Synchronization**: Added 6 missing options to `mpv.conf` using the `script-opts-append=lls-<key>=<value>` syntax.
- **Categorization**: Grouped the new options into their corresponding functional blocks (Drum Mode and Drum Window) within `mpv.conf`.
- **Explanatory Comments**: Added comments for `osd_interactivity` and `dw_scrolloff` to explain their behavior, as these are critical for UI interaction and navigation.
- **Deduplication**: Removed the second instance of `book_mode` from the `Options` table in `lls_core.lua` to avoid confusion and potential state conflicts.

## Risks / Trade-offs

- **Configuration Priority**: Options set in `mpv.conf` via `script-opts-append` will override the script's internal defaults. This is the intended behavior for user customization.
- **Conflict with lls.conf**: If a user has a separate `script-opts/lls.conf` file, mpv's option resolution rules will apply. Since this repository manages the full configuration suite, maintaining everything in `mpv.conf` is consistent with the existing project structure.
