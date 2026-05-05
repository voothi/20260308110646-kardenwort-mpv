# Proposal: Filtered Secondary Subtitle Cycle

## Problem Statement
The Kardenwort immersion suite's secondary subtitle cycle (`Shift+c`) currently includes all available tracks, including built-in (embedded) tracks that are not externally parseable by the suite's advanced logic. This causes user confusion when "unsupported" tracks appear in the rotation. Additionally, mpv conflicts arise when attempting to select the same track for both primary and secondary subtitles, leading to a "stuck" cycle.

## Proposed Solution
Refine the `cycle-sec-sid` logic to:
1. **Filter for External Tracks Only**: Restrict the cycle to external `.srt` or `.ass` files that can be parsed for Autopause, Drum Mode, and clipping.
2. **Dynamic Primary Exclusion**: Automatically skip the track that is already active as the primary subtitle (`sid`) to prevent mpv selection conflicts.
3. **Informative OSD**: Provide specific feedback in the OSD about the number of built-in tracks hidden from the cycle.

## Scope
- Modify `cmd_cycle_sec_sid` in `scripts/lls_core.lua`.
- Update OSD rendering logic for track cycling.
- Ensure compatibility with existing track-list properties.
