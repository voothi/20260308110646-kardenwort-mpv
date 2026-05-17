## Why

To support dual-subtitle language immersion without needing a real video file, users want to read and interact with subtitle files directly in mpv using Kardenwort. Previously, virtual generated media sources like `av://lavfi` were completely unseekable in mpv (causing `Seek failed` errors), which blocked timeline navigation, card reviews, and interactive translations. This change integrates a physical, highly optimized black background canvas (`black.mp4`) that enables 100% perfect, native seekability across the entire subtitle timeline without relying on live generation or external video files.

## What Changes

- **New Subtitle Viewer**: Added `scripts/sub-viewer/viewer.py` to launch `mpv` with dynamic dual-subtitle loading, dynamic timeline bounding (`--length`), and `--no-resume-playback` to ensure clean startup.
- **Tracked Seekable Canvas**: Added a highly optimized 10-hour seekable black video file (`scripts/sub-viewer/black.mp4`) to the project so it is packaged natively in the distribution build.
- **Dynamic Canvas Setup**: Enhanced `scripts/_tools/sub-viewer/install.py` to create the Windows "Send to" shortcut and dynamically verify the seekable canvas.
- **Build & Deploy Integration**: Ensured `scripts/deploy/build_distribution.py` and `scripts/deploy/deploy_distribution.py` automatically package and copy `black.mp4` recursively since `"scripts"` is in the build `INCLUDE_PATHS`.

## Capabilities

### New Capabilities
- `sub-viewer`: Interactive seekable subtitle-only immersion mode in mpv using Kardenwort.

### Modified Capabilities
- `reliable-subtitle-seeking-custom-logic`: Bounding and seeking subtitles when playing virtual timelines.

## Impact

- `scripts/_tools/sub-viewer/viewer.py` (New launcher utility)
- `scripts/_tools/sub-viewer/install.py` (Shortcut registration and dynamic check)
- `scripts/_tools/sub-viewer/black.mp4` (New 10-hour black video asset, ~886 KB)
- `scripts/_tools/deploy/build_distribution.py` & `scripts/_tools/deploy/deploy_distribution.py` (Distribution build payload copy verified)
- `.gitignore` (Track `black.mp4` file)
