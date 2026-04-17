## 1. Update Search Whitelist

- [x] 1.1 Locate `manage_search_bindings` in `scripts/lls_core.lua`.
- [x] 1.2 Append `äöüßÄÖÜẞ` to the `chars` string to enable German character input.

## 2. Verification

- [ ] 2.1 Start mpv with a subtitle track and toggle Search Mode (`Ctrl+F`).
- [ ] 2.2 Verify that German umlauts and the eszett can now be typed into the search query.
- [ ] 2.3 Ensure that searching for terms with these characters correctly filters and highlights the results.
