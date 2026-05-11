## 1. Preparation & Infrastructure

- [x] 1.1 Update `tests/ipc/mpv_session.py` to target `scripts/kardenwort/main.lua` and use script-name `kardenwort`.
- [x] 1.2 Update `tests/ipc/mpv_ipc.py` to replace `kardenwort_core` with `kardenwort` in all `script-message-to` calls.
- [x] 1.3 Perform a global search and replace in the `tests/` directory for `kardenwort_core` -> `kardenwort`.

## 2. Filesystem Restructuring

- [x] 2.1 Create directory `scripts/kardenwort/`.
- [x] 2.2 Move `scripts/kardenwort/main.lua` to `scripts/kardenwort/main.lua`.
- [x] 2.3 Move `scripts/kardenwort_utils.lua` to `scripts/kardenwort/utils.lua`.
- [x] 2.4 Move `scripts/resume_last_file.lua` to `scripts/kardenwort/resume.lua`.
- [x] 2.5 Move `script-opts/anki_mapping.ini` to the repository root.

## 3. Core Logic Refactoring

- [x] 3.1 Update `main.lua` to include `package.path` adjustment for the new subdirectory.
- [x] 3.2 Update `main.lua` to replace all `[Kardenwort]` log prefixes with `[Kardenwort]`.
- [x] 3.3 Update `main.lua` to replace `user-data/Kardenwort/` with `user-data/kardenwort/`.
- [x] 3.4 Update `main.lua` to use `options.read_options(Options, "kardenwort")` and update relevant script-opts prefixes.
- [x] 3.5 Update `main.lua` to look for `anki_mapping.ini` in the repository root.

## 4. Configuration & Binding Updates

- [x] 4.1 Update root `input.conf` to use `script-binding kardenwort/` and `script-message-to kardenwort`.
- [x] 4.2 Update `mpv.conf` to reflect any changed script-opts names (e.g., `kardenwort-sec_pos_bottom`).

## 5. Verification & Cleanup

- [x] 5.1 Run the full acceptance test suite (`pytest`) to verify all 160+ tests pass with the new name.
- [x] 5.2 Update `README.md` with the new installation instructions and breaking change notice.
- [x] 5.3 Update `project-terminology-and-historicity/spec.md` with the new legacy mappings.
