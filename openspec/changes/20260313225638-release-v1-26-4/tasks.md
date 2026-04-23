## 1. Migration Verification

- [ ] 1.1 Verify that `has_cyrillic`, `is_word_char`, and `build_word_list` are hoisted to the top of `lls_core.lua`
- [ ] 1.2 Confirm nil-safety guards in all base text functions
- [ ] 1.3 Verify `.ass` Dialogue parser includes the `has_cyrillic` exclusion check
- [ ] 1.4 Confirm that toggling the Drum Window no longer produces "OPEN/CLOSED" OSD messages
- [ ] 1.5 Validate that mixed-language `.ass` files correctly filter Cyrillic lines in the Drum Window
