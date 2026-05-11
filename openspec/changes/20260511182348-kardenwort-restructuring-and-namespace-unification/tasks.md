## 1. Preparation & Infrastructure

- [ ] 1.1 Update `tests/ipc/mpv_session.py` to target `scripts/kardenwort/main.lua` and use script-name `kardenwort`.
- [ ] 1.2 Update `tests/ipc/mpv_ipc.py` to replace `kardenwort_core` with `kardenwort` in all `script-message-to` calls.
- [ ] 1.3 Perform a global search and replace in the `tests/` directory for `kardenwort_core` -> `kardenwort`.

## 2. Filesystem Restructuring

- [ ] 2.1 Create directory `scripts/kardenwort/`.
- [ ] 2.2 Move `scripts/kardenwort/main.lua` to `scripts/kardenwort/main.lua`.
- [ ] 2.3 Move `scripts/kardenwort_utils.lua` to `scripts/kardenwort/utils.lua`.
- [ ] 2.4 Move `scripts/resume_last_file.lua` to `scripts/kardenwort/resume.lua`.
- [ ] 2.5 Move `script-opts/anki_mapping.ini` to the repository root.

## 3. Core Logic Refactoring

- [ ] 3.1 Update `main.lua` to include `package.path` adjustment for the new subdirectory.
- [ ] 3.2 Update `main.lua` to replace all `[Kardenwort]` log prefixes with `[Kardenwort]`.
- [ ] 3.3 Update `main.lua` to replace `user-data/Kardenwort/` with `user-data/kardenwort/`.
- [ ] 3.4 Update `main.lua` to use `options.read_options(Options, "kardenwort")` and update relevant script-opts prefixes.
- [ ] 3.5 Update `main.lua` to look for `anki_mapping.ini` in the repository root.

## 4. Configuration & Binding Updates

- [ ] 4.1 Update root `input.conf` to use `script-binding kardenwort/` and `script-message-to kardenwort`.
- [ ] 4.2 Update `mpv.conf` to reflect any changed script-opts names (e.g., `kardenwort-sec_pos_bottom`).

## 5. Verification & Cleanup

- [ ] 5.1 Run the full acceptance test suite (`pytest`) to verify all 160+ tests pass with the new name.
- [ ] 5.2 Update `README.md` with the new installation instructions and breaking change notice.
- [ ] 5.3 Update `project-terminology-and-historicity/spec.md` with the new legacy mappings.


