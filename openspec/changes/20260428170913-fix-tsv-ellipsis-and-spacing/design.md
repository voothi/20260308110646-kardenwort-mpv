# Design: TSV Ellipsis and Spacing Fix

## Context
The system uses a "Smart Joiner" (`compose_term_smart`) to reconstruct terms from tokens. Currently, this joiner is unaware of existing whitespace within tokens, leading to doubled spaces when original spacing is preserved. Additionally, the elliptical joiner uses a raw `...` string which the smart joiner incorrectly treats as punctuation that should be joined without a preceding space.

## Goals / Non-Goals

**Goals:**
- Achieve strictly space-padded ellipses (` ... `) in TSV output.
- Eliminate redundant space injection in multi-word terms.
- Ensure the code strictly follows the `smart-joiner-service` and `anki-export-mapping` specifications.

**Non-Goals:**
- Changing the underlying tokenization logic.
- Modifying how highlights are stored in the database.

## Decisions

### 1. Whitespace-Aware Smart Joiner
The `compose_term_smart` function will be updated to skip space injection if:
- The current word ends with whitespace.
- The next word starts with whitespace.

This allows tokens that already include their own padding (like our new ellipsis) or original source spaces to pass through without being doubled by the joiner's default "add a space" rule.

### 2. Space-Padded Ellipsis Token
The token injected during non-contiguous selection reconstruction (`ctrl_commit_set`) will be changed from `"..."` to `" ... "`. 

### 3. Rationale for Combined Approach
By combining a space-padded token with a whitespace-aware joiner, we solve two problems at once:
- The ellipsis gets its required padding.
- Original text spacing (which may contain multiple spaces or tabs) is preserved exactly as-is, while adjacent words still get the standard single-space separator.

## Risks / Trade-offs
- **Risk**: If a token consists *only* of whitespace, the joiner might skip spaces around it. However, since the joiner's purpose is to join words, whitespace tokens are typically already intended as separators.
