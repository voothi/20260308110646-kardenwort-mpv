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

## 4. Reader Workflow Hardening

- [x] 4.1 Add plain text reader conversion for `.txt/.md/.rst/.log` inputs
- [x] 4.2 Support paired text selection as dual subtitle tracks
- [x] 4.3 Align paired cues by line index with mismatch-safe blank padding
- [x] 4.4 Reuse primary cue timing for secondary paired output
- [x] 4.5 Implement deterministic role ordering (`1,2,3`; `en,de,ru`)
- [x] 4.6 Add Subtitle Edit-inspired duration estimation heuristics
- [x] 4.7 Implement conflict output routing to ZID subdirectory for generated reader `.srt`

## Discussion Anchors
- `20260517144548`
- `20260517155418`
- `20260517155733`
- `20260517160256`
- `20260517162045`
- `20260517162358`
- `20260517163403`
- `20260517164300`
