## 1. Core Logic Refactoring

- [x] 1.1 Implement `get_relative_word` recursive segment peeker
- [x] 1.2 Implement `Adaptive Temporal Window` (0.5s/word scaling)
- [x] 1.3 Relax segment adjacency threshold to 1.5s
- [x] 1.4 Implement `Windowed Sequence Matching` (±3 word context)
- [x] 1.5 Implement `Semantic Self-Verification` for multi-sentence blocks

## 2. Rendering & Performance

- [x] 2.1 Update `format_sub` and `draw_dw` to pass full subtitle context
- [x] 2.2 Implement `Lazy Pre-Caching` for highlight terms and word lists
- [x] 2.3 Optimize cleaning loop to remove redundant text processing

## 3. Verification & Guardrails

- [x] 3.1 Verify high-speed news broadcast highlights (125.100 capture)
- [x] 3.2 Verify no-latency mouse selection through caching
- [x] 3.3 Validate Global Mode precision (no word-bleed for 'nur/die')
