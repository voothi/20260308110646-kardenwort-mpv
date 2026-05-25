## Context

Sub Viewer now supports text-first reading workflows, including paired EN/RU inputs. In this path, generated SRT cues feed directly into the same rendering and tokenization stack used by DW, DM, and tooltip surfaces. Recent regressions showed that break-marker representation (`\N` vs real newline) and newline boundary spacing were not normalized consistently, causing:

- legacy-style break markers to leak into generated `.srt` files,
- synthetic spacing around forced wraps,
- visible DW/DM/tooltip divergence for the same subtitle payload,
- and a startup compile interruption when a local helper pushed Lua chunk-local declarations beyond limits.

## Goals / Non-Goals

**Goals:**

- Standardize reader generation to output valid SRT newline semantics (real line breaks, no ASS marker serialization).
- Ensure escaped/legacy break markers are normalized consistently before rendering/tokenization paths consume text.
- Remove synthetic spaces introduced at newline boundaries so hyphen-adjacent and wrap-adjacent text remains stable.
- Define startup-safety expectations so text-normalization additions cannot regress script load viability.
- Capture these behaviors in unit and spec-level regression contracts.

**Non-Goals:**

- No redesign of DW/DM wrapping algorithms or hit-zone geometry.
- No change to reader duration heuristic policy.
- No change to language-priority or role-order logic for paired text selection.

## Decisions

### Decision: Reader Serialization Uses Real Newlines

Reader cue serialization is treated as SRT output, not ASS output. Wrapped lines are joined with literal newline characters, and files MUST not emit `\N` as cue payload.

Alternative considered: keep `\N` for compatibility with internal ASS paths. Rejected because it couples disk format semantics to renderer internals and reintroduced cross-mode parsing drift.

### Decision: One Break-Marker Normalization Contract Across Render Paths

Escaped inline markers from source text (`\N`, `\n`, `\h`) are normalized before tokenization and text-prep in shared rendering/copy/search pathways.

Alternative considered: normalize only in Sub Viewer generation. Rejected because existing/legacy subtitle files may still contain escaped markers and must render consistently without requiring regeneration.

### Decision: Trim Whitespace Around Forced Line Boundaries

Normalization removes artificial boundary padding around newline transitions to prevent conversion to doubled spaces during `newline -> space` text preprocessing.

Alternative considered: preserve boundary spaces exactly as typed. Rejected because parser-generated boundaries are synthetic and degraded visual consistency.

### Decision: Keep Helper Scope Compile-Safe

Text-normalization helper placement must respect Lua chunk-local limits, favoring non-local declaration when local-budget pressure is high.

Alternative considered: strict local-only helper policy. Rejected because this can produce startup compile failure (`main function has more than 200 local variables`) in large monolithic script chunks.

## Risks / Trade-offs

- [Risk] Normalizing escaped markers may alter edge-case content where users intentionally wanted literal `\N` text.  
  Mitigation: normalize only known break-marker forms and keep all other text verbatim.

- [Risk] Trimming newline boundary whitespace may slightly alter raw textual fidelity for malformed inputs.  
  Mitigation: constrain trimming to whitespace directly adjacent to forced newline boundaries.

- [Risk] Non-local helper scope can increase accidental call-site reach.  
  Mitigation: keep helper name narrowly scoped by function purpose and maintain unit/spec regression coverage.
