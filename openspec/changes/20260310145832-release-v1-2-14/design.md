## Context

As the project matured, the initial focus on "learning" felt too academic and narrow. The user's actual behavior centered on the efficient consumption and "immersion" in content. Standardizing these terms ensures the documentation matches the user's mental model and the project's true capabilities.

## Goals / Non-Goals

**Goals:**
- Replace "Learning/Study" with "Acquisition/Immersion" across all text artifacts.
- Explicitly state the "Consumption" mission in `README.md`.
- Clarify the separation between data preparation and immersion playback.

## Decisions

- **Terminology Audit**: A global search and replace is executed on `README.md`, `mpv.conf`, `release-notes.md`, `analyze_repo.py`, and standard reports to enforce the "Acquisition Suite" identity.
- **Workflow Bifurcation**: The documentation is restructured to define "Immersion" as the playback phase. It clarifies that this suite is for the *convenient consumption* of subtitles, while complex file preparation (e.g., track syncing) remains an external prerequisite.
- **YouTube Case Study**: Added documentation explaining how "Drum Mode" and "Smart Spacebar" specifically solve the "flickering context" problem prevalent in YouTube auto-generated captions.

## Risks / Trade-offs

- **Risk**: Confusion for existing users familiar with the old terminology.
- **Mitigation**: Standardized terminology is applied consistently, and the "Acquisition" pivot is highlighted in the release notes.
