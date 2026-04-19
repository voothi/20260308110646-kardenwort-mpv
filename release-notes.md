# Release Notes - v1.42.2 (Dynamic Discovery & Precision Grounding)

**Date**: 2026-04-19
**Version**: v1.42.2
**Implementation ZIDs**: 20260419101025, 20260419104540, 20260419140508

## Highlights

### 📡 **Dynamic Media Source Discovery**
- **Automated URL Discovery**: Implemented a background scanner that searches for `.url`, `.txt`, and `.md` files in the media folder to automatically extract `SourceURL` metadata (e.g., YouTube links).
- **New Anki Field `source_url`**: Introduced the `source_url` keyword for Anki field mapping, enabling zero-touch metadata association for external media.
- **Resilient Background Sync**: URL discovery is integrated into the periodic synchronization loop with a file-path-aware cache that handles renamed or deleted source files without requiring a video restart.

### 🎯 **Precision Multi-Pivot Grounding**
- **Logical Coordinate System**: Transitioned from fragile single-index anchoring to a robust `LineOffset:WordIndex:TermPos` coordinate system for all highlights. This mathematically eliminates "highlight bleed" where common terms would incorrectly appear in unrelated scenes.
- **Temporal Epsilon Guard**: Implemented a mandatory +1ms offset in Anki exports to ensure anchoring coordinates always land safely within the intended subtitle segment, preventing boundary drift.
- **Configurable UI Tolerances**: Moved all hardcoded search windows and gap limits to user-tunable variables in `mpv.conf`, allowing for personalized balancing of recall vs. precision.

### 🎨 **Chromatic Selection Pairing & Visual Contrast**
- **"Warm vs. Cool" Selection Paths**: Overhauled the selection cursor theme to provide consistent chromatic feedback:
  - **Gold (#00CCFF)**: Used for contiguous selections, matching the resulting **Orange** database match.
  - **Neon Pink (#FF88FF)**: Used for split-phrase selections, matching the resulting **Purple** database match.
- **High-Intensity Contrast**: Optimized the hex values for the Orange and Brick palettes at 3rd-tier depth to ensure distinct separation even in high-intensity overlap scenarios.
- **Internal Sync & Docs**: Synchronized default script options with `mpv.conf` overrides and corrected legacy documentation that mislabeled the gold palette as "green."

### ⚡ **Engine Hardening & Optimization**
- **Recursive Grounded Maps**: Implemented recursive result caching and "lazy-parsing" for grounded coordinate maps to maintain 60fps UI performance during rapid scrolling and playback.
- **Stability Pass**: Finalized synchronization between the core `lls_core.lua` engine and user-facing configuration, resolving minor desyncs in default fallback behaviors.

---

# Release Notes - v1.40.2 (Strict Grounding & High-Fidelity Capture)

**Date**: 2026-04-18
**Version**: v1.40.2
**Implementation ZIDs**: 20260417112500, 20260418074913, 20260418183126, 20260418190735, 20260418194004, 20260418195829, 20260418211727, 20260418213707

## Highlights

### 🎯 **Strict Index-Based Grounding & Anchoring**
- **Logical Index Verification**: Implemented a mandatory `logical_idx` check for all subtitle highlights. This eliminates "highlight bleed" where common words (e.g., "die", "und") would incorrectly stay highlighted in unrelated segments.
- **Strict (Time, Index) Grounding**: Automated highlights are now anchored to their exact source occurrence, ensuring that Anki-exported terms only appear where they were originally mined when in local mode.
- **Pivot-Point Context Extraction**: Upgraded the context engine to use character-offset pivot points. This ensures the exporter captures the specific sentence containing your selection, even if identical words appear earlier in the track.

### 🎨 **Visual Priority & Phrase-Aware Styling**
- **Manual Overrides Automated**: Refactored the rendering loop to ensure manual focus (Bright Yellow) and persistent selections (Pale Yellow) always take visual precedence over database-driven highlights.
- **Phrase-Aware Punctuation**: Punctuation marks (commas, periods, brackets) that belong to a highlighted phrase now inherit the phrase's color, creating a cohesive visual block and improving reading flow.
- **Unified "Brick" Intersection**: Stabilized the Tri-Palette logic. Overlapping contiguous and split terms now correctly collapse into a unified "Brick" palette with up to 3 tiers of depth.

### 📋 **Verbatim Capture & Elliptical Selection**
- **Token-Weighted Range Extraction**: Migrated Ctrl+C and Anki exports to a scanner-based range extraction. This preserves all internal punctuation and original whitespace within your selection for 100% verbatim capture.
- **Elliptical Paired-Selection (` ... `)**: Introduced a specialized joiner for non-contiguous selections (e.g., German separable verbs). By injecting an ellipsis into the term, the engine now treats these as "Split-Only" targets, preventing distracting contiguous highlights on unrelated phrases.
- **Unicode Joiner (`compose_term_smart`)**: Unified all ad-hoc string reconstruction logic into a single, Unicode-aware formatter that correctly handles German, Russian, and English punctuation spacing.

### ⚙️ **Formal Spec-Driven Stabilization**
- **"Ground Truth" Compliance**: Completed a comprehensive overhaul to align the Drum Window behavior with the formal implementation-agnostic specification.
- **Robust Multi-Segment Stitching**: Hardened the sequence matching engine to bridge subtitle boundaries (up to 1.5s/5 segments) without visual flicker or gaps.
- **Final Regression Cleanout**: Resolved multiple syntax errors and logic desyncs in the OSD and window rendering loops, achieving 100% stability in Mode W.

---
