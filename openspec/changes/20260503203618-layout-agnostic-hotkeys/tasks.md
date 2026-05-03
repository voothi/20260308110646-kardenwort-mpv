## 1. Engine Expansion

- [x] 1.1 Implement `EN_RU_MAP` for character translation.
- [x] 1.2 Create `expand_ru_keys` utility function.
- [x] 1.3 Expand `vk_codes` table in `fire_gd_trigger` to support Cyrillic characters.

## 2. Binding Integration

- [x] 2.1 Update `parse_and_collect` to use `expand_ru_keys` for Drum Window bindings.
- [x] 2.2 Update global `bind` helper in `register_global_copy_keys` for layout expansion.

## 3. Trigger Hardening

- [x] 3.1 Update trigger logic to iterate over all hotkeys in the configuration string.
- [x] 3.2 Ensure `Shift` modifier forces both lowercase and uppercase Cyrillic bindings.

## 4. Configuration Cleanup

- [x] 4.1 Update `mpv.conf` to use simplified single-layout bindings.
