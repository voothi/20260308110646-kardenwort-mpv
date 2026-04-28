# Proposal: Fix TSV Ellipsis and Spacing Logic
<!-- Context: 20260428165923, 20260428171653, 20260428171824, 20260428172619 -->

## Problem
TSV export for non-contiguous (paired) selections currently produces inconsistent spacing. Specifically:
1. Ellipsis markers (`...`) are often joined without spaces (e.g., `she's...putting`), violating the "space-padded ellipsis" requirement.
2. Contiguous multi-word selections sometimes observe "extra spaces" because the smart joiner adds a space even when the original token already includes one.

## What Changes
1. **Ellipsis Padding**: Update the elliptical injection logic to use an explicit space-padded string (`" ... "`).
2. **Whitespace Awareness**: Enhance the `compose_term_smart` joiner to detect existing whitespace at token boundaries, preventing the injection of redundant spaces.
3. **Spec Alignment**: Update the `smart-joiner-service` specification to explicitly define these behaviors in words, ensuring strict control for future implementations.

## Capabilities

### Modified Capabilities
- `smart-joiner-service`: Strictly define space-padded ellipsis behavior and whitespace-aware joining.
- `anki-export-mapping`: Align with the clarified elliptical spacing requirements.

## Impact
- **Affected Code**: `scripts/lls_core.lua` (`compose_term_smart`, `ctrl_commit_set`).
- **Affected Specs**: `openspec/specs/smart-joiner-service/spec.md`, `openspec/specs/anki-export-mapping/spec.md`.
- **System**: Improves TSV readability and consistency for Anki mining and immersion logs.

## Context
- **Requirement Source**: 20260428165923 (Reported spacing inconsistencies)
- **Constraint Definition**: 20260428171824 (Mandate single space and padded ellipsis)
- **Review**: 20260428172619 (Big model architecture review)
- **Documentation**: 20260428171653 (Walkthrough relocation)
