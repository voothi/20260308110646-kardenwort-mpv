## Context

Searching for specific vocabulary during immersion often requires quick adjustments to the search query. Power users who use terminal-based tools are accustomed to `Ctrl+W` for word deletion. This release brings that efficiency to the search HUD.

## Goals / Non-Goals

**Goals:**
- Implement `Ctrl+W` word deletion.
- Ensure the feature works in both English and Russian layouts.
- Integrate deletion with the existing selection system.

## Decisions

- **Logic Hook**: The `delete_word_before_cursor()` function is added. It checks for an active selection first. If none exists, it calls `get_word_boundary` with a `backward` flag to find the start of the word to the left of the cursor.
- **Key Mappings**:
    - `Ctrl+W` (EN) and `Ctrl+Ц` (RU) are explicitly bound within the `search_osd` key-capture logic.
- **Tag Management**: The new binding is tagged with "search-delete-word" to ensure it is cleanly removed when the search HUD closes, preventing accidental word deletion in other player modes.

## Risks / Trade-offs

- **Risk**: Conflict with native browser or system `Ctrl+W` (often "Close Window").
- **Mitigation**: These bindings are scoped strictly to the `search_osd` input capture state, meaning they only fire when the search HUD is actively focused.
