# Proposal: Fix Strict Highlight Grounding

## Context
When a user selects a specific instance of a word that appears multiple times in the same subtitle segment (e.g., the second "gleich" in a sentence), the highlighting engine was incorrectly highlighting all instances of that word. This occurred because the "Global Anki" mode logic had a leaky fuzzy fallback that matched any occurrence within the same sentence context if strict grounding was unavailable or failed.

## Objectives
- Eliminate "highlight bleed" for identical terms in the same context.
- Ensure 100% precise, index-based grounding for all new manual selections.
- Maintain compatibility with legacy cards that lack grounding metadata.

## What Changes
- Implement strict grounding verification in `calculate_highlight_stack` that blocks fuzzy fallbacks when an index is present and "Anki Global" mode is OFF.
- Update the single-word click handler in the Drum Window (Mode W) to generate an `advanced_index` (grounding info) formatted as `LineOffset:WordIndex:TermPos`.

## Capabilities

### Modified Capabilities
- `highlighting`: Requirements updated to strictly enforce index-based grounding for local selections to prevent spurious matches on duplicate terms.

## Impact
- `lls_core.lua`: Update coordinate extraction and stack calculation.
- User Experience: Improved visual precision and confidence during media mining.
