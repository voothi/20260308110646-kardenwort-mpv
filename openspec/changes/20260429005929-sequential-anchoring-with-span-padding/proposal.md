# Proposal: Sequential Anchoring & Span Padding

## Problem
Previous iterations of the phrase generation logic for paired highlights (Mode D) suffered from three key issues:
1.  **Anchor Ambiguity**: The "closest-to-pivot" fallback could pick the wrong occurrence of a word (e.g., picking an earlier "six" instead of the intended later one) if multiple instances existed, leading to truncated spans.
2.  **Offset Misalignment**: Calculating word indices relative to `sent_start` failed because the `sentence` string was cleaned (stripped of leading whitespace/punctuation), causing a mismatch between character offsets and word positions.
3.  **Inflexible Truncation**: Wide spans were either returning the entire subtitle blob (too much context) or were cropped too tightly (no context around the extreme words).

## Objectives
- Implement **Sequential Forward Anchoring** to ensure picked words are found in the correct document order.
- Fix **Offset Mapping** by tracking the actual start of the cleaned sentence inside the source line.
- Introduce **Configurable Span Padding** to allow breathing room around wide selections while strictly respecting word limits.

## Proposed Changes
- **Anchoring**: Search for the first word near the pivot, then search for all subsequent words strictly forward from that position.
- **Truncation Logic**:
    - Pre-calculate `sentence_abs_start` before any synthetic modifications (like appending ".").
    - If the core span is wider than the limit, return the span plus a configurable `pad`.
- **Settings**: Add `anki_context_span_pad` to `Options` and `mpv.conf`.

## Success Criteria
- Paired highlights spanning long segments are captured correctly in order.
- Context extraction is robust against leading punctuation and synthetic sentence markers.
- Wide selections have a clean, padded crop rather than a paragraph dump.
