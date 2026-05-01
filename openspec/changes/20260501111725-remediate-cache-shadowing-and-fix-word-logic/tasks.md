## 1. Remediate Scoping Errors

- [x] 1.1 Remove the `local` keyword from `DRUM_DRAW_CACHE` initialization (around line 2918) to bind it to the module-scope forward declaration.
- [x] 1.2 Remove the `local` keyword from `DW_DRAW_CACHE` initialization (around line 3232) to bind it to the module-scope forward declaration.
- [x] 1.3 Delete the redundant and unoptimized `is_word_char` definition (around line 1395) to restore the optimized global version.

## 2. Harden Invalidation Logic

- [x] 2.1 Update `flush_rendering_caches` to include `DRUM_DRAW_CACHE.is_drum = false` to ensure mode transitions trigger a cache mismatch.

## 3. Verification

- [x] 3.1 Verify that toggling Drum mode (`cmd_toggle_drum`) results in an immediate OSD refresh without stale frames.
- [x] 3.2 Verify that runtime configuration changes (via `script-opts`) correctly trigger `flush_rendering_caches` and update the UI instantly.
- [x] 3.3 Ensure that `is_word_char` O(1) performance is active for interactive word selection in the Drum Window.
