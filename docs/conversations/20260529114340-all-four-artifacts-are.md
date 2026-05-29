---
aliases: 
  - All four artifacts are complete.
up: "[[conversation]]"
type: 
status: 
down: 
prev: 
next: 
same: 
project: 
area: 
tags: []
created: 2026-05-29
due: 
---

# All four artifacts are complete.

## Description


All four artifacts are complete.

Change ready: 20260529104430-fit-subtitles-to-tts-audio
Artifacts:

proposal.md — Why the change is needed, what changes, which capabilities are touched (sub-tts-pipeline modified, no new capabilities), impact summary.
design.md — Five decisions: where to insert the planner (between speed-fit and assembly), the accumulated-drift algorithm, multi-file lockstep by cue-index replay, config/CLI surface, logging. Includes risks and open questions.
specs/sub-tts-pipeline/spec.md — Delta with four MODIFIED requirements (Timed audio assembly, Configuration file, CLI interface, Windows SendTo integration), each carrying new scenarios for the shift planner and the canonical-first-file lockstep.
tasks.md — 8 task groups, 23 checkboxes covering config, planner, pipeline wiring, CLI, logging, unit tests, manual verification, and docs.
Default behavior unchanged: flag is opt-in. Multi-file SendTo locks translation files to the canonical first file's shift plan by cue index.

Run /opsx:apply (or ask me to implement) to start working through tasks.md.


## MOC.



## Notes


