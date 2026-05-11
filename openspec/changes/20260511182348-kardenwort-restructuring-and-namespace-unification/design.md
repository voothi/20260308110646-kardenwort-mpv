## Context

The current architecture uses a flat `scripts/` directory with legacy `kardenwort_` (Language Learning Suite) naming conventions. This leads to namespace pollution and poor discoverability of key configurations like Anki field mappings. The IPC test suite also relies on these hardcoded strings, making a manual rename risky without a structured plan.

## Goals / Non-Goals

**Goals:**
- **Encapsulation**: Move all Lua logic into the `scripts/kardenwort/` directory.
- **Identity Unification**: Replace the `Kardenwort` acronym with `kardenwort` globally.
- **Config Discoverability**: Elevate `anki_mapping.ini` to the repository root.
- **Test Parity**: Ensure 100% of acceptance tests pass after the rename.
- **Keybinding Efficiency**: Ensure script-bindings are concise (e.g., `kardenwort/toggle`).

**Non-Goals:**
- **Feature Addition**: No new functional features will be added during this refactor.
- **Platform Expansion**: The focus remains on mpv for Windows.

## Decisions

### 1. Directory-Based Namespace (`scripts/kardenwort/`)
We will use a subdirectory instead of a single file in the root `scripts/` folder.
- **Rationale**: Mpv loads directories containing `main.lua` as a single script. This allows us to keep `utils.lua`, `resume.lua`, and future modules neatly tucked away.
- **Namespace Selection**: We chose `kardenwort` (Option B) over `kardenwort-mpv` to keep keybindings shorter (`kardenwort/` vs `kardenwort-mpv/`).

### 2. Standardized Entry Point (`main.lua`)
`kardenwort/main.lua` will be renamed to `main.lua`.
- **Rationale**: This is the idiomatic way to define a directory-based mpv script. It simplifies the script name in the logs and binding tables.

### 3. Global Prefix Migration
- **Log Prefix**: `[Kardenwort]` -> `[Kardenwort]`
- **IPC Script Name**: `kardenwort_core` -> `kardenwort`
- **User-Data Prefix**: `user-data/Kardenwort/` -> `user-data/kardenwort/`
- **Options Identity**: `Kardenwort` -> `kardenwort` (affects the `script-opts/` file name).

### 4. Config Elevation
`anki_mapping.ini` will move from `script-opts/` to the repository root.
- **Rationale**: This is a high-traffic configuration file. Placing it at the root makes it immediately visible to new users and simplifies the onboarding process.

## Risks / Trade-offs

- **[Risk] Total Keybinding Breakage** → **Mitigation**: The project's `input.conf` will be updated simultaneously. A "Breaking Changes" section will be added to the top of the README.
- **[Risk] IPC Test Failure** → **Mitigation**: The `mpv_ipc.py` and `mpv_session.py` helpers will be updated first to target the new script name, ensuring the infrastructure is ready before the logic moves.
- **[Risk] Lua Path Resolution** → **Mitigation**: Inside `main.lua`, `package.path` will be adjusted using `mp.get_script_directory()` to ensure `require 'utils'` and `require 'resume'` work regardless of where the project is installed.

