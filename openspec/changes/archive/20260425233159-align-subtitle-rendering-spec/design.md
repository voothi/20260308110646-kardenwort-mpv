## Context

The v1.50.0 compliance audit enforced a "Global Suppression" requirement which broke ASS subtitle rendering by hiding all native tracks when OSD rendering was active for any track. To fix regression `20260425224611`, the implementation in `lls_core.lua` has been refactored to use track-aware suppression logic.

## Goals / Non-Goals

**Goals:**
- Fix regression `20260425224611` by restoring native rendering for ASS tracks.
- Formalize the use of `pri_use_osd` and `sec_use_osd` flags in `master_tick`.
- Maintain strict suppression for the Drum Window (`dw_active`).

**Non-Goals:**
- Changing the OSD rendering logic itself (e.g., adding ASS tag support to OSD).

## Decisions

- **Independent Visibility Calculation**: `master_tick` now calculates `target_pri_vis` and `target_sec_vis` independently. 
  - `pri_use_osd` is `true` only if the primary track is SRT and OSD styling is requested.
  - `sec_use_osd` is `true` only if the secondary track is SRT and OSD styling is requested.
- **Selective Rendering**: The `tick_drum` function now receives these flags as arguments and renders each track OSD block only if its corresponding `use_osd` flag is `true`.
- **Precedence**: ASS tracks are explicitly exempted from OSD rendering (`not Tracks.pri.is_ass`) and their native visibility is restored in `master_tick` via `mp.set_property_bool`.

## Risks / Trade-offs

- **Visual Overlap**: Native ASS subtitles and OSD SRT subtitles may overlap. Users are expected to use `secondary-sub-pos` or native ASS positioning to resolve this, which is the standard mpv behavior for multi-track consumption.
