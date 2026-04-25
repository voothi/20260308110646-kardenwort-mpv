# Spec: Global Navigation Bindings

## Context
Exposing internal functions as script-bindings allows for more flexible and reliable key-to-command mapping.

## Requirements
- Register `lls-seek_prev` and `lls-seek_next` using `mp.add_key_binding`.
- These bindings must trigger the high-precision `cmd_dw_seek_delta` logic.
- Ensure the bindings are available immediately upon script initialization.

## Verification
- Use `mpv --input-test` to verify the bindings are recognized.
- Manually trigger the bindings via the console (`script-binding lls_core/lls-seek_next`) and verify the video jumps to the next subtitle.
