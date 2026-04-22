## 1. Migration Verification

- [x] 1.1 Verify removal of hardcoded `"c"` in `lls_core.lua` (around line 768)
- [x] 1.2 Confirm all script bindings in `lls_core.lua` use `nil` as the first argument
- [x] 1.3 Verify `scripts/old_copy_sub.lua` is removed from git tracking
- [x] 1.4 Validate `.gitignore` contains `__pycache__/`
