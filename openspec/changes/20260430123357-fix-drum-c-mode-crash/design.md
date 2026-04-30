## Context

Commit `81ee67b` introduced the `DRUM_DRAW_CACHE` to the `draw_drum` function to eliminate redundant calculation of hit-zones and string formatting for subtitles on each `master_tick` loop. The cache key includes configuration variables such as `lh_mul` and `vsp` which in `mpv.conf` can be defined as floating-point values (e.g. `0.87`). 
The initial cache implementation used `string.format` with `%d` for these variables. In Lua 5.3+, `%d` strictly requires integer values, resulting in a fatal script exception: `bad argument #2 to 'format' (number has no integer representation)`. The crash is caught by the wrapping `xpcall`, which then suppresses native subtitles (by design, since Drum Mode is "ON") but returns `""` for the OSD. This causes the screen to become completely blank when in Drum Mode.

## Goals / Non-Goals

**Goals:**
- Repair the string formatting in `draw_drum` to be resilient to float-based configuration values.
- Eliminate the Lua runtime crash.
- Restore Drum Mode subtitle visibility.

**Non-Goals:**
- Modifying or redesigning the caching strategy itself.
- Expanding the cache key to include temporal features like `time_pos` (which does not affect the layout output, since temporal changes manifest through the `center_idx`).

## Decisions

1.  **Format Specifier Replacement**:
    *   **Decision**: Switch from `%d` to `%g` for `lh_mul`, `vsp`, and `font_size` inside `draw_drum`'s `cache_key`.
    *   **Rationale**: The `%g` specifier cleanly handles both integers and floating-point values without producing trailing zeros, guaranteeing a consistent cache key footprint regardless of user configuration, and averting the type-coercion crash in Lua.
    *   **Alternatives Considered**: Use `tostring()`. While valid, `%g` inside `string.format` is slightly faster and syntactically cleaner when mixed with other arguments in a colon-delimited string.

## Risks / Trade-offs

- [Risk] Formatting changes could break cache invalidation. → **Mitigation**: `%g` maps the same semantic value uniquely (e.g., `1.5` -> `1.5`, `2` -> `2`). It will appropriately miss the cache only when the underlying value actually changes.
