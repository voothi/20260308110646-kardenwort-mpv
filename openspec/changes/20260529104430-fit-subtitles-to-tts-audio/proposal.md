## Why

In the current sub_tts pipeline, every cue's TTS audio is forced to fit inside its original subtitle window — first by the speed-fit stage (atempo / rubberband), then by anchoring assembly to the SRT start times. When the speed cap (`max_speed_factor`) cannot fully absorb an over-long synthesis, the cue audio bleeds into the next cue's start, two adjacent narrations get mixed, and intelligibility suffers. The current pipeline only reports this as a warning; it does not mitigate it.

For my own use of these MP4s as listening artifacts (foreign-language audio + translation pair), the highest-fidelity result is preserved when the audio keeps its natural pace and the *subtitle timeline* gives way to it — i.e., shift subsequent cues later by the overflow, instead of compressing the speech further. This change adds that behavior as an opt-in.

## What Changes

- Add a new opt-in mode: **fit-subtitles-to-audio** (default OFF). When ON, the pipeline shifts subsequent cues' `start_ms`/`end_ms` later by the overflow amount instead of leaving overflow as a passive warning. The total output duration grows accordingly.
- The new mode runs **after** per-cue TTS synthesis and **after** the existing speed-fit stage, but **before** audio assembly. The existing speed-fit stage remains active (so the new mode only shifts what speed-fit could not absorb).
- Add a new config key `tts_settings.fit_subtitle_to_audio` (bool, default `false`) and a matching CLI pair `--fit-subtitle-to-audio` / `--no-fit-subtitle-to-audio` (CLI overrides config; explicit `--no-…` overrides config).
- In multi-file SendTo mode, the **first** SRT file is canonical: shifts derived from its audio are applied identically to every subsequent file in the same invocation. This keeps en/ru (source/translation) pairs in lockstep on the same timeline. Cross-file structural divergence (different cue counts, different timestamps) is out of scope for this change — the first-file shift plan is replayed by **cue index position** onto the others, which is correct for synthetic translation pairs that share a timeline.
- The audio placement plan's `overflow_ms` semantics change when the new mode is on: after shifting, no cue should report nonzero overflow, and the existing overflow warning is suppressed for shifted cues.
- The output MP4 base-track duration calculation already accounts for `max(audio_end_ms, end_ms)` per cue, so it absorbs the shifted timeline naturally — no separate change to duration logic is required.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `sub-tts-pipeline`: adds a new opt-in mode to the **Timed audio assembly** requirement (shift-subsequent-cues behavior); extends the **Configuration file** requirement with a new key; extends the **CLI interface** requirement with new flags; extends the **Windows SendTo integration** scenarios to cover canonical-first-file shift propagation.

## Impact

- **Code**: [scripts/_tools/sub-tts/sub_tts.py](scripts/_tools/sub-tts/sub_tts.py) — new shift planner function between `adjust_speed_for_cues()` and `assemble_audio()`; `process_srt()` signature gains a `shift_plan` parameter (out for first file, in for subsequent files); `main()` learns to thread the plan across multiple SRT files in a single invocation; new CLI flags in `parse_args()`; new config key read.
- **Config**: [scripts/_tools/sub-tts/config.ini.template](scripts/_tools/sub-tts/config.ini.template) — add documented `fit_subtitle_to_audio = false` with a short usage note.
- **Tests**: extend [tests/unit/test_20260526195053_sub_tts_pipeline.py](tests/unit/test_20260526195053_sub_tts_pipeline.py) with shift-plan unit tests (no FFmpeg needed — operates on the timing plan only) and a multi-file lockstep test.
- **Docs**: README in `scripts/_tools/sub-tts/` if present.
- **No breaking changes**: default behavior (flag OFF) is byte-equivalent to current behavior.
