## 1. Sub-Viewer Canvas Setup

- [x] 1.1 Add `black.mp4` to `.gitignore` exclusions (remove ignore rule)
- [x] 1.2 Stage `black.mp4` file in Git
- [x] 1.3 Update `install.py` to generate `black.mp4` with ffmpeg fallback if missing

## 2. Dynamic Timeline Bounding

- [x] 2.1 Implement `get_last_sub_end` parser in `viewer.py` to find the last subtitle timestamp
- [x] 2.2 Add `--length` argument dynamically when launching `mpv` to clip timeline to subtitle duration

## 3. Build System Verification

- [x] 3.1 Verify `scripts/_tools/deploy/build_distribution.py` packages the `black.mp4` asset
- [x] 3.2 Verify `scripts/_tools/deploy/deploy_distribution.py` copies the `black.mp4` asset
