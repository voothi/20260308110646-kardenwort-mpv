## Why

AI agents currently risk "hallucinating" color values due to the ASS (BGR) and Web (RGB) hex notation flip and lack a central "Ground Truth" for the project's evolving terminology. This change establishes a formal standard for project terminology, historical renamings, and color representation to ensure 100% consistency in both automated and manual development.

## What Changes

- **Standardized Thesaurus**: Formalizes domain-specific terms like "Warm Path," "Cool Path," and "Surgical Highlighting."
- **Evolutionary Pivot Table**: Creates a linkable historical map for renamings (e.g., Blue → White active subtitles, Yellow → Gold cursors).
- **Dual-Notation Color Standard**: Mandates that all color specifications provide both RGB and BGR values to eliminate rendering ambiguity.
- **Spec Consolidation**: Updates existing UI and highlighting specifications to align with the new canonical naming and color standards.

## Capabilities

### New Capabilities
- `standardized-terminology-and-historicity`: Establishes the canonical thesaurus, historical mapping ledger, and dual-notation color standards as the project's "Ground Truth."

### Modified Capabilities
- `window-highlighting-spec`: Update highlight requirements to use dual-notation (RGB/BGR) and canonical color names (Gold/Orange/Pink/Purple).
- `search-ui-styling`: Synchronize search HUD styling requirements with the new terminology and color standards.
- `osd-uniformity`: Ensure uniform rendering requirements respect the new color-space mappings.

## Impact

- **Documentation**: All `openspec/specs/` files will now adhere to a unified terminology and color-naming convention.
- **AI Agents**: Future agentic workflows will have a reliable historical mapping to interpret legacy ZIDs and user requests correctly.
- **Configuration**: `mpv.conf` and `lls_core.lua` options will be updated to reflect the canonical naming.
