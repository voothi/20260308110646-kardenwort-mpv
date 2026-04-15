## Context

Currently, the Drum Window exports all selected text sequences using a single TSV formatting configuration, defined in `anki_mapping.ini` under the `[fields]` section. However, when users select multiple words (a phrase or sentence), they generally need these exported to a different Anki note type that provides more context compared to a simple individual vocabulary word. The original Kardenwort application accommodated this by separating export profiles into `.word` and `.sentence`. This change incorporates that concept into Kardenwort-mpv, allowing Anki field formatting layouts to adapt dynamically depending on the selected text volume.

## Goals / Non-Goals

**Goals:**
- Differentiate between vocabulary words and sentences based on a configurable word-count threshold.
- Allow independent configuration of the exported TSV layouts for words and sentences using distinct blocks in the mapping definition.
- Guarantee backwards compatibility safely for users with a standard `anki_mapping.ini` file via fallback mechanisms.

**Non-Goals:**
- Supporting more than two categories (e.g., intermediate phrases).
- Changing the low-level string construction mechanisms for TSV escaping.

## Decisions

1. **Threshold Configuration:**
   - **Decision:** Introduce a setting in the configuration file (e.g., `sentence_word_threshold = 3`) defining the minimum sequence length to consider a highlighted segment a "sentence."
   - **Rationale:** Hardcoding limits prevents users from fully controlling the threshold. Since token lengths and semantic structures vary wildly by language, the user must dictate this variable.

2. **Template Branching Structure:**
   - **Decision:** Update `anki_mapping.ini` parsing to detect and prioritize `[fields.word]` and `[fields.sentence]` groups over the default group.
   - **Alternatives:** Continue using a single group but require complex inline conditionals. This was rejected because Kardenwort syntax logic is easier to read simply with dedicated configuration sections.

3. **Graceful Fallback Logic:**
   - **Decision:** If a condition requires `[fields.sentence]` but it doesn't exist, the system must securely fall back to the default `[fields]` mapping.
   - **Rationale:** Prevents breaking existing installs that haven't been migrated to the new config template format.

## Risks / Trade-offs

- **[Risk]** Word-counting logic could be unpredictable for complex tokens or ideographic texts.
  → **Mitigation:** Evaluate string token size accurately by referencing the Drum selection sequence queue size, which strictly correlates with user intent instead of applying loose regex spaces counting.

- **[Risk]** Missing entries in existing `anki_mapping.ini` leading to empty TSV lines.
  → **Mitigation:** Ensure fallback logic handles missing dictionary groups effectively.
