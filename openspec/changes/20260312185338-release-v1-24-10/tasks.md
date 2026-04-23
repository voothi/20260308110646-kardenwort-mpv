## 1. Migration Verification

- [ ] 1.1 Verify relevance scoring point tiers (1000/800/500/100) in `lls_core.lua`
- [ ] 1.2 Confirm `table.sort` logic uses `score` DESC and `index` ASC
- [ ] 1.3 Verify `utf8_to_lower` implementation and Cyrillic character mapping table
- [ ] 1.4 Test search relevance by performing queries with multiple match types
- [ ] 1.5 Validate case-insensitive search for capitalized Russian words
- [ ] 1.6 Confirm performance stability during result sorting on large subtitle files
