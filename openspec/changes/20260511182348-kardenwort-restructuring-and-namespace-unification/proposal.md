## Why

To unify the project identity under the **Kardenwort** brand and eliminate the legacy `LLS` (Language Learning Suite) terminology. This restructuring ensures namespace safety in mpv through directory-based script loading, improves configuration discoverability by centralizing files in the repository root, and standardizes the project's internal organization for professional distribution and maintainability.

## What Changes

- **BREAKING**: Move core logic into a directory-based namespace: `scripts/kardenwort/`.
- **BREAKING**: Rename `lls_core.lua` to `main.lua` (the primary entry point for the `kardenwort` script).
- **BREAKING**: Rename and integrate helper scripts:
    - `lls_utils.lua` -> `scripts/kardenwort/utils.lua`
    - `resume_last_file.lua` -> `scripts/kardenwort/resume.lua`
- **BREAKING**: Move `script-opts/anki_mapping.ini` to the repository root for better visibility.
- **BREAKING**: Update all script-message and script-binding targets from `lls_core` to `kardenwort`.
- **BREAKING**: Rename internal prefixes and properties:
    - Log prefix: `[LLS]` -> `[Kardenwort]`
    - User-data properties: `user-data/lls/` -> `user-data/kardenwort/`
    - Options identity: `lls` -> `kardenwort` (affects `script-opts/kardenwort.conf`)
- Update the full IPC test suite to target the new script name and message prefixes.
- Update all documentation and specifications to reflect the new canonical structure and terms.

## Capabilities

### New Capabilities
- `directory-based-scripting`: Formalizes the use of `scripts/<namespace>/main.lua` for multi-module isolation in mpv.

### Modified Capabilities
- `project-terminology-and-historicity`: Updating the canonical thesaurus and legacy mappings for the LLS -> Kardenwort transition.
- `modular-architecture`: Updating requirements to use the `scripts/kardenwort/` directory instead of `scripts/lib/`.
- `centralized-script-config`: Updating configuration override targets (e.g., `lls_core-` -> `kardenwort-`).

## Impact

- **Affected Code**: All Lua scripts, `input.conf`, and `anki_mapping.ini`.
- **Affected Systems**: The `pytest` IPC test suite (all 160+ acceptance tests).
- **Breaking Changes**: External keybindings and `mpv.conf` overrides referencing `lls_core` or `lls` will need to be updated by the user.
