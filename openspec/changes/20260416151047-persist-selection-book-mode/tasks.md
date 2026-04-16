## 1. Core Logic Update

- [ ] 1.1 Locate `cmd_dw_seek_delta` in `scripts/lls_core.lua`.
- [ ] 1.2 Wrap selection state reset logic in a check for `not FSM.BOOK_MODE`.

## 2. Verification

- [ ] 2.1 Verify selection persistence during `a`/`d` seeks with Book Mode ON.
- [ ] 2.2 Verify selection still resets during `a`/`d` seeks with Book Mode OFF (standard behavior).
