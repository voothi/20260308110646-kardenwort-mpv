# Change Request Interface (Single-Action Protocol)

Use this file before any implementation. Fill only one block per request.

## Block 1: Goal
- One sentence outcome:
- User-visible mode(s): (e.g., Autopause ON + PHRASE)
- Must feel like: (e.g., MOVIE-like smooth handover during cross-card rewind)

## Block 2: Exact Trigger
- Action key(s):
- Starts at time/card:
- Ends at time/card:
- Is this inside one card or cross-card?

## Block 3: Expected Behavior
- During action:
- At boundary crossing:
- After action ends:

## Block 4: Must Not Change
- [ ] Ordinary PHRASE forward playback
- [ ] MOVIE mode baseline
- [ ] Drum window UI behavior
- Other:

## Block 5: Acceptance (Pass/Fail)
- Scenario 1:
- Scenario 2:
- Scenario 3:

## Block 6: Execution Rule
- Single minimal patch area (file/function):
- No side refactors:
- Rollback point (commit/tag):

---

## Filled Example for Current Problem

- One sentence outcome:
  In Autopause ON + PHRASE, cross-card rewind is smooth like MOVIE; inside-card rewind still pauses normally at card end.
- Action key(s):
  Shift+a/d and repeat s.
- Split condition:
  Apply transit suppression only for cross-card moves.
- Must not change:
  Default PHRASE forward behavior.
- Patch area:
  `scripts/lls_core.lua` transit gating around `tick_autopause`, `cmd_seek_time`, and PHRASE jerk-back gate.
