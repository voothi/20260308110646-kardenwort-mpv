## 1. Mining Logic Refactoring

- [x] 1.1 Revert `compose_term_smart` to original simple punctuation-aware joiner
- [x] 1.2 Implement literal token concatenation in mining loop (`lls_core.lua`)
- [x] 1.3 Add manual space-padded ellipsis (` ... `) injection for logical gaps

## 2. Verification

- [x] 2.1 Verify that mining non-contiguous words produces space-padded ellipses
- [x] 2.2 Verify that original subtitle spacing is preserved in the TSV output
- [x] 2.3 Ensure no regressions in UI/OSD display joining
