## 1. Spec and Doc Alignment

- [ ] 1.1 Verify `drum-scroll-sync` delta spec reflects zero-scrolloff clamping and compact viewport safety semantics.
- [ ] 1.2 Verify `config-documentation` delta spec documents `kardenwort-drum_scrolloff` scope and default-zero behavior.
- [ ] 1.3 Verify `README.md` and `mpv.conf` wording aligns with the new spec language.

## 2. Cache-Compatibility Documentation

- [ ] 2.1 Validate the new `dw-layout-cache-compatibility-guards` capability captures both guard-and-rebuild behavior and `ensure_sub_layout` compatibility metadata.
- [ ] 2.2 Cross-check documented requirements against implemented `dw_build_layout` and `ensure_sub_layout` behavior in `scripts/kardenwort/main.lua`.

## 3. Regression Coverage Documentation

- [ ] 3.1 Validate `automated-acceptance-testing` delta spec requires log-based crash signature checks for `entry`/`height` nil failures.
- [ ] 3.2 Confirm acceptance test `test_20260513143307_dw_layout_cache_and_scrolloff_zero.py` is cited and mapped to the new regression requirements.

## 4. Change Readiness and Traceability

- [ ] 4.1 Run `openspec status --change 20260513145124-document-dm-dw-scrolloff-and-layout-cache-hardening` and confirm all apply-required artifacts are complete.
- [ ] 4.2 Append a concise ZID-linked summary to `docs/conversation.log` for release traceability.
