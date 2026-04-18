## Context

The highlighting engine for the Drum Window (Mode W) has evolved from simple string matching to a complex, multi-pass token-based system. Highlighting logic was previously documented across disparate archived changes. This specification change formalizes the expected visual output to eliminate ambiguity.

## Goals / Non-Goals

**Goals:**
- Provide a unified logical model for the "High-Recall Highlighter".
- Define the precedence for color overlays (Contiguous vs. Split vs. Mixed).
- Standardize punctuation coloring rules.
- Clarify inter-segment continuity limits (1.5s gap, 5-segment peek).

**Non-Goals:**
- This document does not describe the specific Lua implementation or performance optimizations.
- Support for ASS formatting (advanced subtitle styling) is explicitly restricted in this version. The highlighter will treat ASS tags as metadata or disable highlighting for complex drawing/positioning blocks to maintain rendering stability.

## Decisions

- **Hierarchy of Rendering:** The engine will prioritize "Phrase Continuity" over "Single-Word Isolation" when determining punctuation colors. This ensures that multi-word terms always appear as a solid visual block.
- **Unified Mixed State:** To avoid color-count explosion, all intersections (regardless of the specific mix of contiguous and split terms) are collapsed into a single "Mixed" palette. The depth within this palette is the sum of total matches, capped at 3.
- **Strict Neighborhood Anchoring:** To solve the "common word bleed" issue in global mode, any match must be verified against its recorded neighborhood. This logic is chosen over simple timestamp matching to allow users to see their saved terms in new contexts while ensuring accuracy.

## Risks / Trade-offs

- **Cognitive Load:** Having 9 distinct highlight hex codes (3 per palette) may be difficult for new users to distinguish. However, for the target power-user (language learners), this granularity is essential for distinguishing exact matches from fuzzy/split matches.
- **Context Loss:** The neighborhood check (±3 words) might fail if the subtitle translation varies significantly from the original recording. This is a targeted trade-off to ensure high-precision matching.
