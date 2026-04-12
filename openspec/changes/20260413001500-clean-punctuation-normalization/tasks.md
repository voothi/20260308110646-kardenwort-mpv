## 1. Core Implementation

- [x] 1.1 Implement boundary isolation in `format_sub` (Drum renderer)
- [x] 1.2 Implement boundary isolation in `draw_dw` (Window renderer)
- [x] 1.3 Implement boundary isolation in `cmd_dw_copy` (Capture engine)
- [x] 1.4 Implement Adaptive Continuity (is_phrase check for Full Highlighting)

## 2. Verification

- [x] 2.1 Verify clean highlights for single words (`Bühne.`) 
- [x] 2.2 Verify continuous highlights for phrases (`Fechten, Bogen`)
- [x] 2.3 Verify clean capture (no trailing punctuation in clipboard)
- [x] 2.4 Validate UTF-8 integrity (German Umlaute preserved as words)
