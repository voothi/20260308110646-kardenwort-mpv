## 1. Migration Verification

- [ ] 1.1 Verify removal of hardcoded `"c"` in `lls_core.lua` (around line 768)
- [ ] 1.2 Confirm all script bindings in `lls_core.lua` use `nil` as the first argument
- [ ] 1.3 Verify `scripts/old_copy_sub.lua` is removed from git tracking
- [ ] 1.4 Validate `.gitignore` contains `__pycache__/`
