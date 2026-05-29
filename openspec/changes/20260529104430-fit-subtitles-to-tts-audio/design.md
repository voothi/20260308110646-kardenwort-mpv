## Context

The sub_tts pipeline currently runs four sequential stages per SRT file inside [process_srt()](scripts/_tools/sub-tts/sub_tts.py#L978-L1084):

1. **TTS synthesis** — [synthesize_all_cues()](scripts/_tools/sub-tts/sub_tts.py#L472-L510) renders each cue to its own WAV.
2. **Speed fitting** — [adjust_speed_for_cues()](scripts/_tools/sub-tts/sub_tts.py#L640-L751) trims silence and applies `atempo` / `rubberband` (capped by `max_speed_factor`) to fit each WAV into its subtitle window plus an optional `max_extra_gap_ms` lookahead into the following gap.
3. **Audio assembly** — [build_audio_placement_plan()](scripts/_tools/sub-tts/sub_tts.py#L758-L796) anchors each fitted WAV to its original `cue.start_ms` on a silent base track. Overflow into the next cue is *reported* as a warning and left to mix on top of the next cue's audio inside the `amix` filter.
4. **MP4 mux** — [mux_to_mp4()](scripts/_tools/sub-tts/sub_tts.py#L892-L925).

When `max_speed_factor` (default 2.0) cannot fully absorb a long synthesis, two narrations end up acoustically superimposed. The user's listening usage prefers preserving the source-language audio's natural pace over preserving the visual subtitle timeline — so the *timeline* should yield to the *audio*, not the other way around.

A canonical-timeline coupling also exists between sibling SRT files in the same SendTo invocation: when both `lesson.en.srt` and `lesson.ru.srt` are processed together, they are typically machine-generated translations sharing one timeline by cue index. The en (source) take is the highest-quality, most-listened-to track; the ru (translation) is auxiliary. If the en track's shifts and the ru track's shifts diverge, the two MP4s desync from each other and from any external player driving both. Coupling the timeline shifts to the first file fixes this for the common case.

## Goals / Non-Goals

**Goals:**
- Provide an opt-in mode where overflowing TTS audio shifts subsequent cues later instead of bleeding into them. Default behavior unchanged.
- Apply the same shifts in lockstep across all SRT files in one SendTo invocation, driven by the first (canonical) file.
- Keep the speed-fit stage in place so the shift planner only handles residual overflow that the speed cap could not absorb.
- Keep the existing timing plan unit-testable (no FFmpeg / Piper dependency at the planning layer).

**Non-Goals:**
- Cross-file structural reconciliation when the files have *different cue counts or different original timelines* (different number of subtitles, slightly different timestamps). Deferred to a follow-up. For this change, multi-file mode assumes the trivial-but-common case: the files share cue count and original timestamps and differ only in text content.
- Adaptive `max_speed_factor` tuning. The cap stays user-configured; the new mode only changes what happens *after* the cap.
- Backfilling silence gap recovery — when audio is shorter than the window, we do not pull the next cue earlier. We only shift later on overflow.
- Rewriting the source SRT file. The shifted timeline lives only inside the in-memory cue list during this run and influences only the assembled audio's placement.

## Decisions

### Decision 1: Run the shift planner between speed-fit and assembly, not inside either

Insert a pure function `apply_subtitle_shift_plan(synthesis_results) -> (shifted_results, shift_plan)` in [sub_tts.py](scripts/_tools/sub-tts/sub_tts.py) that runs after [adjust_speed_for_cues()](scripts/_tools/sub-tts/sub_tts.py#L640-L751) and before [assemble_audio()](scripts/_tools/sub-tts/sub_tts.py#L799-L885). It mutates a copy of each cue dict's `start_ms` / `end_ms` (it does **not** touch the underlying speed-fit results' WAV files or durations). The returned `shift_plan` is a list of `{cue_index, original_start_ms, shifted_start_ms, shift_ms}` rows used both for logging and for multi-file lockstep replay.

**Alternatives considered:**
- *Fold the shift into `adjust_speed_for_cues`* — rejected. That function decides per-cue speed in isolation; the shift is a sequential pass that needs the prior cue's audio_end_ms to compute the next cue's required start. Mixing them muddies the two concerns and breaks the existing unit tests for speed fitting.
- *Fold the shift into `build_audio_placement_plan`* — rejected. The placement plan is a pure read of cue timing → audio anchors; turning it into a writer would couple test fixtures for the visualization-only `overflow_ms` field to the shift logic.

### Decision 2: Algorithm — single forward pass, accumulated drift

```
drift = 0
for each cue i in order:
    cue[i].start_ms += drift          # apply prior accumulated drift first
    cue[i].end_ms   += drift
    audio_end       = cue[i].start_ms + cue[i].wav_duration_ms
    if i+1 < N:
        gap_required = audio_end - cue[i+1].original_start_ms - drift
        # ^ how much would cue i+1's *un-drifted* start need to move?
        if gap_required > 0:
            drift += gap_required
```

This guarantees `cue[i+1].start_ms >= audio_end_of_cue[i]` (no overlap) while never pulling cues earlier. Drift only grows. Producing `shift_plan[i] = drift_after_processing_cue_i` is the artifact replayed across sibling SRT files.

**Alternative considered:** Per-cue local shift (no accumulation) — rejected. If cue 3 overflows by 1s, cues 4 and 5 must each move 1s; per-local-shift requires recomputing on every cue and produces the same result with more arithmetic.

### Decision 3: Multi-file lockstep via cue-index replay

[main()](scripts/_tools/sub-tts/sub_tts.py#L1194-L1280) loops over `srt_files`. The first file's run produces a `shift_plan` (a list indexed by cue index). For each subsequent file, the planner is *skipped* — instead, the prior plan is replayed: `cue[i].start_ms += shift_plan[i]`, `cue[i].end_ms += shift_plan[i]`. If a later file has a different cue count, only the overlapping prefix is shifted; tail cues retain their original timing and a single warning is printed. This is the deferred-non-goal escape hatch — it degrades gracefully but does not pretend to solve cross-file divergence.

**Alternatives considered:**
- *Independent per-file planning* — rejected. Different audio durations per language (German is famously longer than English) would produce different drifts per file, desyncing the pair. The user's stated priority is that the source file is canonical and translations are auxiliary, which this directly encodes.
- *Plan from the longest file* — rejected. Requires synthesizing every file before deciding shifts, doubling latency and breaking the streaming-style per-file processing.

### Decision 4: Config + CLI surface

- New config key under existing `[tts_settings]`: `fit_subtitle_to_audio = false` (boolean, default false). Read via the existing [config_bool()](scripts/_tools/sub-tts/sub_tts.py#L539-L544) helper.
- New CLI flags following the same pattern as the existing `--keep-lang-postfix` / `--no-keep-lang-postfix`: `--fit-subtitle-to-audio` (`action="store_true"`, `default=None`) and `--no-fit-subtitle-to-audio` (`action="store_false"`, `dest="fit_subtitle_to_audio"`). `None` means "fall back to config"; True/False explicitly overrides.
- Threaded through `process_srt()` as `fit_subtitle_to_audio_override` (mirrors `keep_lang_postfix_override`).

### Decision 5: Logging

- One `log_info` line when the planner runs ("Fitting subtitles to audio: N cue(s) shifted, total drift Xs").
- The existing "N synthesized cue(s) exceed the next subtitle start" warning in [assemble_audio()](scripts/_tools/sub-tts/sub_tts.py#L812-L818) is suppressed for cues that were shifted (overflow should be ~0 after planning; any residual is noise from `get_wav_duration_ms` rounding).
- For sibling files in lockstep mode, log "Applying canonical shift plan from <first-file-name>: N cue(s) shifted".

## Risks / Trade-offs

- **Output length growth** → No mitigation needed; this is the intended trade-off. The user accepts a longer MP4 in exchange for clean, non-overlapping audio. Documented in the new config key's comment in `config.ini.template`.
- **Drift between paired MP4 and original video timestamps** → If the user later uses the MP4 as audio replacement against the *original* video, the shifted audio will desync. Mitigation: keep the flag opt-in and document that the resulting MP4 is for standalone listening, not for re-muxing against the source video.
- **Cue-count mismatch in multi-file mode** → Mitigated by replaying only the overlapping prefix and warning. Full solution deferred to a follow-up change.
- **Speed-fit cap interaction** → If a user sets `max_speed_factor = 1.0` (no speeding allowed) and enables the new flag, every cue with even minor overflow shifts. Drift could grow large. This is expected behavior — the user explicitly opted out of compression and into shifting. No safeguard added.
- **First-cue-failed-synthesis edge case** → If the first cue's WAV is missing, the planner treats its duration as 0 and produces no shift for cue 2. Same graceful degradation as the existing pipeline.

## Migration Plan

No migration. The flag defaults to `false` so existing config files and existing automation continue to produce byte-identical output. Users opt in by adding `fit_subtitle_to_audio = true` to their `config.ini` or passing `--fit-subtitle-to-audio` on the command line.

## Open Questions

- Should the lockstep shift plan also be written to a sidecar file (e.g., `<basename>.shifts.json`) so external tools can reuse it? Deferred — wait for a concrete need.
- Should the planner respect an upper bound on cumulative drift and fall back to overflow-warning behavior past that bound? Deferred — current design has no cap; revisit if drift values surprise users in practice.
