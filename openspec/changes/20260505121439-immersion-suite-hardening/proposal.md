# Proposal: Immersion Suite Hardening (v1.58.51)

## Problem
The previous subtitle immersion system suffered from several "Magnetic Snapping" and "Focus Stuck" issues when handling large pre-roll/post-roll audio padding. 
- In **Phrase Mode**, navigation between overlapping subtitles was erratic, often jumping back to the previous line.
- **Movie Mode** lacked a seamless handover mechanism, causing either audio gaps or unnecessary repetitions.
- **Secondary Subtitle Cycling** was cluttered with unsupported built-in tracks (e.g., DEU/ENG PGS tracks) that the script cannot render, confusing the user during track selection.
- Core behavioral constants (cooldowns, tolerances) were hardcoded magic numbers, preventing scientific tuning.

## Objective
To concrete the specification of a high-fidelity "Phrase Card" and "Cinematic Flow" engine that treats subtitles as independent, fully-audible fragments while maintaining a seamless viewing experience.

### Key Goals
1. **Deterministic State Machine**: Transition from proximity-based guessing to a sentinel-led FSM (`ACTIVE_IDX`).
2. **Dual-Mode Immersion**:
   - **PHRASE Mode**: Isolated card drilling with "Jerk-Back" overlap repeats.
   - **MOVIE Mode**: Gapless cinematic handover at padded boundaries.
3. **Filtered Track Selection**: Hardening `Shift+c` to only cycle through supported external subtitle tracks, hiding built-in metadata-only tracks.
4. **Scientific Parameterization**: Externalize all behavioral thresholds (`nav_cooldown`, `nav_tolerance`, `autopause_overshoot`) to `mpv.conf`.

## Proposed Solution
We have implemented a robust FSM that uses a "Sticky Sentinel" to protect the audio tail of the current line and a "Next-Sub Priority" logic to allow forward progress in gaps. This system ensures that every subtitle fragment is heard in full, with repeatable pre-rolls, without sacrificing navigation fluidity.

The implementation is verified against the `71bfa6a` baseline and confirmed to resolve all "stuck" and "jerking" regressions reported in the `20260505` development cycle.
