## 1. Mode Matrix and Contract

- [ ] 1.1 Add/confirm spec deltas for `fsm-architecture` with explicit `srt`/`dm`/`dw` ownership and transition constraints.
- [ ] 1.2 Add/confirm spec deltas for `coordinated-input-system` to align keybinding activation with mode ownership.

## 2. Command-Level Guardrails

- [x] 2.1 Guard `cmd_cycle_copy_mode` so it mutates only in `dw`.
- [x] 2.2 Guard `cmd_toggle_copy_ctx` so it mutates only in `dw`.

## 3. Binding Activation Isolation

- [x] 3.1 Restrict `update_interactive_bindings()` so plain `srt` does not activate DW interaction bindings.
- [ ] 3.2 Verify `dm` and `dw` retain expected keyboard/mouse parity for add/pair/select/tooltip/search paths.

## 4. Ignore-Key Hardening

- [ ] 4.1 Add newly encountered accidental keys to `input.conf` under a dedicated section.
- [ ] 4.2 Add/adjust acceptance tests to ensure ignored keys do not mutate mode-owned state.

## 5. Verification

- [ ] 5.1 Run targeted acceptance tests for mode transitions and DW-only mutation guards.
- [ ] 5.2 Document residual edge cases and follow-up key-ignore candidates.
