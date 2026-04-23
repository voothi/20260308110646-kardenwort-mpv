# Tasks: Universal Navigation Reliability

## 1. Logic Promotion
- [x] Export `cmd_dw_seek_delta` as `lls-seek_prev` and `lls-seek_next`
- [x] Register script-bindings in `lls_core.lua`
- [x] Remove window-state checks from core seeking logic

## 2. Configuration Integration
- [x] Update `input.conf` to use `script-binding lls_core/lls-seek_prev` for `a`/`ф`
- [x] Update `input.conf` to use `script-binding lls_core/lls-seek_next` for `d`/`в`
- [x] Verify multi-layout support (EN/RU) in `input.conf`

## 3. Validation
- [x] Verify "one-tap" jump reliability in standard playback
- [x] Verify "one-tap" jump reliability in Drum Window
- [x] Confirm no regressions in seeking accuracy
