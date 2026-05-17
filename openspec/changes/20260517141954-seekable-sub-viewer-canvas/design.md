## Context

To provide a seamless, standalone subtitle-reading workspace, we designed the "Kardenwort Sub Viewer". However, virtual generators like `av://lavfi` are treated as continuous, unindexed real-time live feeds by `mpv`, which breaks all seeking operations (leading to player lockouts and `Seek failed` warnings). 

## Goals / Non-Goals

**Goals:**
- Provide a physical, seekable, black H.264 canvas file (`black.mp4`) that registers a standard playable timeline.
- Enable dynamic OSD timeline clipping (`--length`) to automatically match the precise duration of the active subtitle file.
- Ensure the standalone sub-viewer binary asset is committed and bundled directly into distribution archives without requiring external dependencies (like `ffmpeg`).
- Restrict interactive keyboard bindings strictly to the active Drum Window state to prevent focus and key hijacking when the DW is closed.

**Non-Goals:**
- Supporting high-framerate rendering (the canvas is a static black screen rendering at 1 frame per second).
- Converting subtitle files directly into embedded video hardsub files.

## Decisions

### 1. Pre-generated Standalone Canvas File
* **Decision**: Generate and commit a static `black.mp4` file directly to Git under `scripts/sub-viewer/black.mp4`.
* **Rationale**: Initially, we attempted on-the-fly generation using system `ffmpeg`. However, end users might not have `ffmpeg` installed. Committing a super-compressed 10-hour baseline file (only 886 KB) guarantees a zero-dependency setup out-of-the-box.

### 2. Dynamic Timeline Clipping (`--length`)
* **Decision**: Parse the timestamp of the very last subtitle block at startup and supply it to `mpv` via `--length={last_end + 2.0}`.
* **Rationale**: Even though `black.mp4` has a maximum 10-hour headroom, showing a 10-hour seekbar for a 15-minute video looks unpolished. Dynamically limiting the length shapes the player to the exact millimeter of the target subtitle track.

### 3. FSM Keyboard Hook Segregation
* **Decision**: Restrict keyboard capturing hooks to `need_kb = dw_on` (exclusive of `osd_on`).
* **Rationale**: When only OSD interactivity is needed (mouse hovering/clicks), capturing the entire keyboard hijacked default keys (like `z`/`x`). Restricting keyboard control to the Drum Window guarantees default hotkeys behave normally in all other states.

## Risks / Trade-offs

- **Risk**: Hardcoded 10-hour canvas limit.
  - *Mitigation*: 10 hours represents vast headroom exceeding standard movies or compiled shows. If an extreme edge case occurs, the viewer gracefully falls back to the virtual `av://lavfi` rendering.
- **Risk**: Storing binary `.mp4` in Git.
  - *Mitigation*: The H.264 stream is compressed to 1 fps at CRF 51, keeping the entire file size under 900 KB—smaller than many image assets.
