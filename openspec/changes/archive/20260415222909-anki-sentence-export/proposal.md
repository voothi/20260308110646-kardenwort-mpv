## Why

Currently, all exported items are formatted uniformly as single words, regardless of the selection sequence length. This causes issues when importing into Anki, as multi-word selections (sentences or phrases) cannot be appropriately mapped to sentence-specific Anki note templates. By defining a configurable word count threshold and allowing different export formatting templates for words and sentences (similar to how it was implemented in Kardenwort's config), we can ensure that exported fields are processed correctly when imported into Anki.

## What Changes

- Add a parameter in the configuration file to define the threshold number of words that constitutes a "sentence" (e.g., 3 words or more).
- Introduce conditional branch logic during the TSV export to format the output differently depending on whether the selection meets the sentence length threshold.
- Allow template configuration profiles for both words and sentences (based on kardenwort's `.word` and `.sentence` structure) in the config to structure the TSV rows suitably for their respective Anki models.

## Capabilities

### New Capabilities
- `sentence-export-formatting`: Introduces conditional formatting rules and templates for TSV record generation based on the length of the selected text, differentiating between isolated words and sentences.

### Modified Capabilities
- `anki-export-mapping`: Expands the existing export functionality to support dynamic output profiles (such as `.word` vs `.sentence` mapping equivalents).

## Impact

- **Configuration Files:** The settings structure will have new variables defining sentence length thresholds and formatting templates.
- **TSV Export Module:** The logic that writes to the record file will evaluate the text length against the configurable threshold and switch between serialization templates.
- **Anki Workflow:** The generated TSV formatting profile will better align with dual Anki workflows, distinguishing between concise vocabulary cards and contextual sentence cards.
