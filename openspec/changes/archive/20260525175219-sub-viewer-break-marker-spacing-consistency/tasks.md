## 1. Sub Viewer Reader Serialization

- [x] 1.1 Replace ASS-style `\N` cue serialization in reader generation with native SRT newline output.
- [x] 1.2 Ensure single-file and paired-file text conversion paths emit newline-based cue payloads only.
- [x] 1.3 Add unit regression coverage asserting generated reader cues do not contain serialized `\N`.

## 2. Rendering Path Normalization Consistency

- [x] 2.1 Introduce shared escaped break-marker normalization for subtitle text processing paths used by DW/DM/tooltip/copy/search.
- [x] 2.2 Normalize forced-break boundary spacing to avoid synthetic double spaces after newline-to-space preprocessing.
- [x] 2.3 Preserve hyphenated token integrity under normalized break-marker flows.

## 3. Startup Stability And Validation

- [x] 3.1 Resolve Lua startup compile regression caused by chunk-local overflow in text-normalization helper placement.
- [x] 3.2 Add targeted viewer unit regressions for spacing integrity and hyphenated paired EN/RU cue preservation.
- [x] 3.3 Run focused regression validation for the newly added viewer tests.
