## Context

The system previously used a unified `compose_term_smart` function for both OSD display and Anki mining. While suitable for UI where standard typography is preferred (e.g., no space before periods), it introduced regressions in mining data by stripping meaningful spaces and multiplying whitespaces when used with tokens already containing spaces.

## Goals / Non-Goals

**Goals:**
- Decouple mining term construction from the "smart" joiner logic.
- Restore literal, token-based concatenation for Anki exports.
- Ensure the gap ellipsis ` ... ` is always space-padded as per old version behavior.

**Non-Goals:**
- Replacing the `compose_term_smart` function for OSD display.
- Adding complex regex-based post-processing to the text.

## Decisions

### 1. Manual Token Concatenation for Mining
Instead of passing a token list to a joiner function, the mining loop now manually builds the string by iterating through tokens.
- **Rationale**: This allows for surgical control over the spacing between words and the insertion of gap markers.
- **Alternative**: Modifying `compose_term_smart` to handle a "literal" flag. This was rejected as it would overcomplicate the service and risk side-effects in the UI.

### 2. Space-Aware Tokenization
The system continues to use `build_word_list_internal(..., true)` during mining.
- **Rationale**: This preserves the original spacing from the source subtitle stream, ensuring that hyphenated words or multi-space formatting is respected.

## Risks / Trade-offs

- **Risk**: Double spaces in the source subtitle will now appear in Anki (unlike the smart joiner which would collapse them).
- **Mitigation**: This is considered a feature (literal accuracy) rather than a bug, as it respects the source text's intent.
