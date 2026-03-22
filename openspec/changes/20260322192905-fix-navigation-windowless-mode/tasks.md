# Tasks: Fix Navigation in Windowless Mode

## Script Updates
- [x] **Export Bindings**: Add `mp.add_key_binding` calls for `lls-seek_prev` and `lls-seek_next` in `lls_core.lua`.
- [x] **Register Functions**: Ensure `cmd_dw_seek_delta` is correctly mapped to these bindings.

## Configuration Updates
- [x] **Global Mapping**: Replace `sub-seek` with `script-binding` for `a`/`d` in `input.conf`.
- [x] **Russian Mapping**: Replace `sub-seek` with `script-binding` for `ф`/`в` in `input.conf`.

## Verification
- [x] **Windowless Mode**: Verify immediate navigation response after autopause.
- [x] **Drum Window Mode**: Verify navigation still works as expected inside the Drum Window.
