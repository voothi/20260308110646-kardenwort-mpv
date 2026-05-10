# Playback Mechanism Review (Autopause ON, PHRASE/MOVIE)

Date: 2026-05-11
Source anchors: docs/conversation.log (especially 20260509130838, 20260509132307, 20260510215546, 20260510224931)

## 1) Accepted Terms (Shared Vocabulary)

- Card: one subtitle item (start, end, text).
- Active Card: subtitle that engine currently treats as main focus (`ACTIVE_IDX`).
- Raw Card Window: original SRT timing without extra padding.
- Padded Window: card timing extended by padding options (`audio_padding_start`, `pause_padding`).
- PHRASE mode: pause-oriented mode using padded boundaries.
- MOVIE mode: gapless handover mode, no extra overlap rewind logic.
- Natural Progression: normal forward move from current card to next when current expires.
- Jerk-Back: a backward snap to next card padded start (PHRASE overlap behavior).
- Rewind Transit: temporary period after `Shift+a/d` or repeat-like jump where user is intentionally moving.
- Transit Inhibit: `TIMESEEK_INHIBIT_UNTIL`; while active, autopause and jerk behavior are suppressed for cross-card transit.

## 2) Your Requirement in One Sentence

When playback crosses into another subtitle because of manual rewind/navigation (`Shift+a/d`, repeat `s`), behavior must be smooth like MOVIE (no repeated overlap audio, no jerks), but if movement stays inside the same subtitle, Autopause ON must still stop at the subtitle end normally.

## 3) How Mechanism Works Now (Plain Language)

1. Engine continuously decides which subtitle is active.
2. In normal PHRASE playback, subtitle boundaries are padded and autopause can stop at boundary end.
3. During rewind transit, engine sets a temporary inhibit flag.
4. While inhibit is active:
- it avoids boundary pause events caused only by passing overlap zones,
- and suppresses PHRASE jerk-back overlap correction.
5. After transit is truly finished, inhibit clears and normal PHRASE behavior resumes.

## 4) Visual Diagrams (Non-Programmer)

### A) Normal PHRASE (No Manual Rewind)

```text
Time --->

Card N:      [==========raw==========]
Card N+1:                     [==========raw==========]
PHRASE pad:   <----extra----> and pause-at-end logic enabled

Result: controlled stop at card end (Autopause ON).
```

### B) Manual Rewind Transit (Expected Smooth)

```text
User presses Shift+a/d or triggers repeat navigation
           |
           v
  [Transit Inhibit ON temporarily]
           |
           +--> no overlap pause
           +--> no PHRASE jerk-back
           +--> handover feels like MOVIE

Transit ends -> inhibit OFF -> back to normal PHRASE rules.
```

### C) Split Rule You Asked For

```text
If jump stays inside SAME card:
  keep Autopause ON normal stop at this card end.

If jump crosses to OTHER card:
  temporary MOVIE-like smooth handover (no repetitions/jerks).
```

## 5) Why We Kept Breaking Things

- Two valid goals conflict unless explicitly separated:
1) PHRASE strict boundary behavior.
2) MOVIE-like smoothness during manual cross-card transit.
- Previous fixes sometimes globally changed PHRASE behavior instead of only transit behavior.

## 6) Final Rule Contract (for implementation)

R1. Inside-card rewind: do NOT disable normal autopause.
R2. Cross-card rewind: enable transit inhibit to suppress overlap pauses and jerk-back.
R3. Clear inhibit only after transit is truly over (not by fixed timer alone).
R4. Never let a stale inhibit survive unrelated manual jumps.

## 7) Scope Boundary (to avoid regressions)

Must NOT change:
- default PHRASE behavior during ordinary forward playback,
- MOVIE mode behavior,
- Drum Window selection/rendering logic.

Can change:
- transit gating conditions,
- inhibit set/clear hygiene,
- boundary check branch for inside-card vs cross-card moves.

## 8) Ready-to-Use Acceptance Checklist

- Case A: Autopause ON + PHRASE, rewind inside current card -> stops normally at end.
- Case B: Autopause ON + PHRASE, rewind across cards -> smooth transition, no repeated overlap chunk.
- Case C: Repeat `s` in overlap-sensitive area -> same split behavior as A/B.
- Case D: after transit, normal PHRASE pauses resume.

---

If this document matches your intent, we use it as the single source of truth before the next code edit.
