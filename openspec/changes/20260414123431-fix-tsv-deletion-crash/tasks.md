## 1. Safety Wrapping TSV State Loading

- [ ] 1.1 Locate the Drum Window initialize and file loading routines (e.g. in `lls_core.lua` or `kardenwort.lua` `init_tsv_state` or `open_drum_window`).
- [ ] 1.2 Implement a robust file existence verification check before parsing (using `io.open`).
- [ ] 1.3 Add a fallback path that writes the standard ANKI header map to a recreated file if it is missing or empty.

## 2. Drum Window Resiliency Integration

- [ ] 2.1 Update the Drum Window `render_drum_window` or related state logic to check if a valid data set was successfully loaded.
- [ ] 2.2 Add error messaging (`mp.osd_message`) when TSV reading encounters a fatal failure.
- [ ] 2.3 Prevent `FSM.DRUM_WINDOW` state transition if valid rows cannot be initialized.

## 3. Empty File Robustness

- [ ] 3.1 Verify robust handling of empty rows without nil reference crashes in highlighting and TSV parsing sequences. 
- [ ] 3.2 Ensure the script falls back gracefully, retaining operations on the rest of video/subs without locking the UI.
