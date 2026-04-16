## 1. Core Logic Update

- [x] 1.1 Locate `cmd_dw_seek_delta` in `scripts/lls_core.lua`.
- [x] 1.2 Remove the selection state reset logic entirely from `cmd_dw_seek_delta` (previously wrapped in Book Mode check).

## 2. Verification

- [x] 2.1 Verify selection persistence during `a`/`d` seeks with Book Mode ON.
- [x] 2.2 Verify selection persistence during `a`/`d` seeks with Book Mode OFF.
