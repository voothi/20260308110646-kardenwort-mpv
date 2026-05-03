# Spec: Calibration Mode

## Context
Tuning hit-test multipliers currently requires manual config editing. A visual feedback loop is needed for efficient calibration.

## Requirements

### Visual Debug Overlay
1.  **Toggle**: The user must be able to toggle "Calibration Mode" via a keybinding (proposed: `Shift+B` or via console command `lls-calibrate`).
2.  **Rendering**: When active, the system must render semi-transparent bounding boxes (Magenta/Cyan) over every interactable word in the current HUD (Drum Window or Drum Mode).
3.  **Real-Time Refresh**: Any change to calibration multipliers must trigger an immediate re-calculation and re-draw of the overlay.
4.  **Status OSD**: A persistent OSD label in the top-right must show the current values of `char_width`, `line_height`, and `vsp`.

### Live Adjustment
1.  **Keys**: The following keys must be captured during Calibration Mode:
    - `[` / `]`: Increment/Decrement `dw_char_width` by 0.001.
    - `{` / `}`: Increment/Decrement `dw_line_height_mul` by 0.01.
    - `Shift+[` / `Shift+]`: Increment/Decrement `dw_vsp` by 1.
2.  **Modal Input**: These keys must NOT trigger their normal actions while Calibration Mode is active.

### Persistence Engine
1.  **Save Action**: Pressing `ENTER` or `S` during Calibration Mode must save the current multipliers.
2.  **File Append**: The system must append the new settings to `mpv.conf` in a formatted block:
    ```conf
    # --- CALIBRATION [20260503010003] ---
    lls-dw_char_width=0.505
    lls-dw_line_height_mul=0.88
    lls-dw_vsp=2
    # ------------------------------------
    ```
3.  **Verification**: The system must verify the file is writable before attempting to save.

## Verification
1.  Activate Calibration Mode.
2.  Adjust `char_width` until the boxes perfectly align horizontally with word boundaries.
3.  Adjust `line_height` until the boxes perfectly align vertically with line height.
4.  Save and restart mpv; verify the new settings are active.
