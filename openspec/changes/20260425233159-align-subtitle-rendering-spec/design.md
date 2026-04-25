## Context

The v1.50.0 compliance audit enforced a "Global Suppression" requirement which broke ASS subtitle rendering. The current implementation in `lls_core.lua` has been refactored to use track-aware suppression logic. We need to formalize this design to ensure future compliance audits recognize the track-specific flags as the correct implementation pattern.

## Goals / Non-Goals

**Goals:**
- Formalize the use of `pri_use_osd` and `sec_use_osd` flags in `master_tick`.
- Define the precedence of ASS native rendering over OSD rendering for those tracks.
- Maintain strict suppression for the Drum Window (`dw_active`).

**Non-Goals:**
- Changing the OSD rendering logic itself (e.g., adding ASS tag support to OSD).
- Modifying the Drum Window layout.

## Decisions

- **Independent Visibility Calculation**: `master_tick` shall calculate `target_pri_vis` and `target_sec_vis` independently based on track type (ASS vs SRT) and user visibility preferences (`native_sub_vis`).
- **Signature Update**: The `tick_drum` function signature is updated to accept both track flags, allowing it to selectively render only those tracks that have been successfully "supressed" at the native level.
- **Spec Overhaul**: The `subtitle-rendering` specification is updated to replace the "Global Suppression" requirement with a more granular "Track-Aware Suppression" model.

## Risks / Trade-offs

- **Visual Overlap**: There is a minor risk of visual overlap if native ASS subtitles and OSD SRT subtitles are both positioned at the same screen location. This is mitigated by the existing `secondary-sub-pos` logic which users can adjust.
- **Consistency**: The system will now have "hybrid" rendering states (Native + OSD). This is a trade-off made to preserve styling and font integrity for complex subtitle tracks.
