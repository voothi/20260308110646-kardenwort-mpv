## 1. Copy Source Consistency

- [ ] 1.1 Ensure export source selection is resolved once from `COPY_MODE` and consumed by `POINT`, `RANGE`, and `SET` paths.
- [ ] 1.2 Validate mode `B` behavior in dual-subtitle sessions for manual yellow/pink selections and no-selection fallback.

## 2. UTF-8 Preview Safety

- [ ] 2.1 Keep DW/Context preview truncation character-safe for multibyte strings.
- [ ] 2.2 Route runtime preview formatting through a shared builder to avoid duplicate string logic.

## 3. Regression Coverage

- [ ] 3.1 Add acceptance coverage for UTF-8 truncation boundary behavior.
- [ ] 3.2 Add acceptance coverage for preview string integrity (no mojibake artifacts).
- [ ] 3.3 Validate Lua syntax and execute targeted pytest subset for the new tests.

## 4. Documentation and Traceability

- [ ] 4.1 Record change rationale, decisions, and capability deltas in OpenSpec artifacts.
- [ ] 4.2 Keep implementation and test references aligned with proposal/design/spec outputs.
