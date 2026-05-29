## 1. Config surface

- [ ] 1.1 Add `fit_subtitle_to_audio = false` entry (with a comment block explaining the trade-off — longer output, no audio overlap) to [scripts/_tools/sub-tts/config.ini.template](scripts/_tools/sub-tts/config.ini.template) under `[tts_settings]`.
- [ ] 1.2 Confirm the local [scripts/_tools/sub-tts/config.ini](scripts/_tools/sub-tts/config.ini) does not need to be edited (key is optional with safe `false` default via `config_bool` fallback).

## 2. Planner implementation

- [ ] 2.1 Add a pure function `plan_subtitle_shifts(synthesis_results, ffmpeg_path) -> shift_plan` to [scripts/_tools/sub-tts/sub_tts.py](scripts/_tools/sub-tts/sub_tts.py) that implements the single-forward-pass accumulated-drift algorithm from [design.md](design.md) §Decision 2. The returned `shift_plan` is a list of ints (drift_ms per cue index, length = number of successfully-synthesized cues).
- [ ] 2.2 Add `apply_shift_plan(synthesis_results, shift_plan) -> shifted_results` that returns a new list where each cue dict is replaced with a copy whose `start_ms` and `end_ms` are increased by the corresponding `shift_plan` entry. Cues beyond `len(shift_plan)` retain their original timing.
- [ ] 2.3 Make sure the planner uses `get_wav_duration_ms` *once per cue* and caches the result on the returned plan to avoid re-probing in `build_audio_placement_plan`.

## 3. Pipeline wiring

- [ ] 3.1 Extend `process_srt()` signature with `fit_subtitle_to_audio_override=None` and `canonical_shift_plan=None` parameters (mirrors `keep_lang_postfix_override` pattern).
- [ ] 3.2 After `adjust_speed_for_cues()` returns, resolve the effective `fit_subtitle_to_audio` value: CLI override → config `tts_settings.fit_subtitle_to_audio` → `False`.
- [ ] 3.3 If `fit_subtitle_to_audio` is True and `canonical_shift_plan is None` (first file in invocation), call `plan_subtitle_shifts(...)` and return the resulting plan from `process_srt()` (extend return type to `(success: bool, shift_plan: list[int] | None)`).
- [ ] 3.4 If `fit_subtitle_to_audio` is True and `canonical_shift_plan is not None` (subsequent file), skip planning and apply the canonical plan directly via `apply_shift_plan`.
- [ ] 3.5 If `fit_subtitle_to_audio` is False, leave the existing flow untouched (no planner, no shifted results) and return `(success, None)`.
- [ ] 3.6 In `build_audio_placement_plan`, suppress the "N synthesized cue(s) exceed the next subtitle start" warning for cues whose `overflow_ms` is zero after shifting (current code already only counts >0 overflows; verify the threshold and add a log_info line when the planner produced shifts so the operator sees something happened).
- [ ] 3.7 Update `main()` to thread a single `shift_plan` variable across the `srt_files` loop: assign on first successful run, pass into every subsequent `process_srt()` call. Reset to `None` if `fit_subtitle_to_audio` is False so subsequent runs are independent.

## 4. CLI surface

- [ ] 4.1 In `parse_args()`, add `--fit-subtitle-to-audio` (`action="store_true"`, `default=None`) and `--no-fit-subtitle-to-audio` (`action="store_false"`, `dest="fit_subtitle_to_audio"`) following the existing `--keep-lang-postfix` / `--no-keep-lang-postfix` pattern.
- [ ] 4.2 In `main()`, pass `args.fit_subtitle_to_audio` into `process_srt()` as `fit_subtitle_to_audio_override`.

## 5. Logging

- [ ] 5.1 When the planner runs (first file), emit `log_info("Fitting subtitles to audio: N cue(s) shifted, total drift X.XXs")` after planning completes. N counts non-zero entries; total drift = max(shift_plan) (last cumulative value).
- [ ] 5.2 When a subsequent file replays a canonical plan, emit `log_info(f"Applying canonical shift plan from {first_filename}")`.
- [ ] 5.3 When a subsequent file's cue count differs from the canonical plan length, emit `log_warn(f"{filename}: cue count {N} differs from canonical {M}; shifting overlap only")`.

## 6. Unit tests

- [ ] 6.1 In [tests/unit/test_20260526195053_sub_tts_pipeline.py](tests/unit/test_20260526195053_sub_tts_pipeline.py), add `test_plan_subtitle_shifts_no_overflow` covering the "WAV shorter than window" case → returns all-zero plan.
- [ ] 6.2 Add `test_plan_subtitle_shifts_single_overflow` covering the spec scenario "Shift planner moves overflowing cue's successor" (cue 1 start 1000ms WAV 3000ms, cue 2 start 2000ms → cue 2 shifts to 4000ms, plan = [0, 2000]).
- [ ] 6.3 Add `test_plan_subtitle_shifts_accumulated_drift` covering the spec scenario "Shift planner accumulates drift across cues" (cue 1 0/1500, cue 2 1000/1500, cue 3 2000 → plan = [0, 500, 1000]).
- [ ] 6.4 Add `test_plan_subtitle_shifts_never_pulls_earlier` verifying that an early under-running cue does not reduce subsequent shift values once drift is positive.
- [ ] 6.5 Add `test_apply_shift_plan_mismatch_prefix` confirming that when `len(synthesis_results) > len(shift_plan)`, trailing cues keep original timing.
- [ ] 6.6 Stub `get_wav_duration_ms` (e.g. via monkeypatch on the module) in all the above tests so they run without FFmpeg.

## 7. Acceptance / manual verification

- [ ] 7.1 Run the existing test suite to confirm no regression (`python -m pytest tests/unit/test_20260526195053_sub_tts_pipeline.py -v`).
- [ ] 7.2 Run the pipeline against a real overflow-prone SRT file with the flag OFF, save the output, then run again with `--fit-subtitle-to-audio`. Confirm the second output is longer and contains no overlapping speech in audible spot-checks at the cues that overflowed.
- [ ] 7.3 Run the pipeline with two paired SRT files (`lesson.en.srt` `lesson.ru.srt`) via `--sendto --fit-subtitle-to-audio` and confirm both output MP4s have identical durations and identical cue-by-cue audio start times.

## 8. Documentation

- [ ] 8.1 If [scripts/_tools/sub-tts/README.md](scripts/_tools/sub-tts/README.md) exists, add a short subsection documenting the new flag, the trade-off (longer output, no overlap), and the multi-file lockstep behavior. If no README exists, skip.
- [ ] 8.2 No CLAUDE.md update needed (the change is self-contained in the tool directory).
