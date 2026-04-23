## 1. Migration Verification

- [ ] 1.1 Verify `find_fuzzy_span` implementation in `lls_core.lua`
- [ ] 1.2 Confirm compactness bonus calculation logic (Ultra-Compact +150, Compact +50)
- [ ] 1.3 Verify that span-based scoring correctly prioritizes intra-word matches
- [ ] 1.4 Test search results with common "scattered" character patterns to ensure they are de-prioritized
- [ ] 1.5 Confirm O(N) performance of the span finder during real-time typing
