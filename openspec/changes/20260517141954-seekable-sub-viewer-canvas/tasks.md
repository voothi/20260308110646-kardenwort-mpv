## 1. Sub-Viewer Canvas Setup

- [x] 1.1 Add `black.mp4` to `.gitignore` exclusions (remove ignore rule)
- [x] 1.2 Stage `black.mp4` file in Git
- [x] 1.3 Update `install.py` to generate `black.mp4` with ffmpeg fallback if missing

## 2. Dynamic Timeline Bounding

- [x] 2.1 Implement `get_last_sub_end` parser in `viewer.py` to find the last subtitle timestamp
- [x] 2.2 Add `--length` argument dynamically when launching `mpv` to clip timeline to subtitle duration

## 3. Keyboard Interactivity Fix

- [x] 3.1 Update `scripts/kardenwort/main.lua` to restrict `need_kb` strictly to `dw_on` state

## 4. Build System Verification

- [x] 4.1 Verify `scripts/deploy/build_distribution.py` packages the `black.mp4` asset
- [x] 4.2 Verify `scripts/deploy/deploy_distribution.py` copies the `black.mp4` asset
