## 1. Configuration Updates

- [x] 1.1 Add `sentence_word_threshold` configuration key to `anki_highlighter_settings.ini` (default value 3).
- [x] 1.2 Update settings parser in the Lua export processing script to correctly load and utilize the `sentence_word_threshold` parameter.

## 2. Profile Parsing Logic

- [x] 2.1 Refactor the `anki_mapping.ini` parser function to identify, read, and store separate mapping arrays for `[fields]`, `[fields.word]`, and `[fields.sentence]`.
- [x] 2.2 Implement a profile fetching mechanism that attempts to fetch designated profiles (`.word` or `.sentence`) but robustly falls back to `[fields]` when specific formatting blocks are absent.

## 3. TSV Export Implementation

- [x] 3.1 Update the TSV record construction logic to calculate the exact word length of the highlighted sequence being exported.
- [x] 3.2 Add conditional branching to classify if the sequence qualifies as a word or a sentence depending on the user's `sentence_word_threshold`.
- [x] 3.3 Apply the accurately resolved Anki mapping profile definition array during TSV row construction over the prior singular mapped output.

## 4. Verification

- [x] 4.1 Execute a test export with an isolated vocabulary word (e.g., length < 3) to verify `[fields.word]` profile behavior.
- [x] 4.2 Execute a test export with a continuous multi-word sequence (e.g., length >= 3) to verify correct switching to the `[fields.sentence]` profile formatting.
- [x] 4.3 Remove or comment out `.sentence` and `.word` blocks in `anki_mapping.ini` to safely verify the fallback sequence onto `[fields]`.
