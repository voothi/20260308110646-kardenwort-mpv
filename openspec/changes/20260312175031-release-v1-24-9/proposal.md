## Why

This change formalizes the Search HUD UX Enhancements introduced in Release v1.24.9. To provide a professional-grade searching experience, it was necessary to implement standard keyboard shortcuts found in modern terminal and text-editing environments. This update introduces Bash-style word deletion to allow users to quickly correct or modify their search queries without the friction of repeated backspaces.

## What Changes

- Implementation of **Bash-Style Deletion (`Ctrl+W`)**: A new hotkey that deletes the entire word (or whitespace block) to the left of the cursor.
- Introduction of **Selection-Prioritized Deletion**: If text is actively selected in the search HUD, `Ctrl+W` will delete the selection range first, following standard UI behavior.
- Enforcement of **Dual-Layout Parity**: Both `Ctrl+W` (English) and `Ctrl+Ц` (Russian) are mapped to the same deletion logic to maintain the suite's layout-agnostic standard.
- Implementation of `delete_word_before_cursor()` using the existing `get_word_boundary` utility.

## Capabilities

### New Capabilities
- `search-ux-optimization`: A set of keyboard-driven interaction patterns that align the search HUD with professional text-editing standards.
- `word-based-deletion-logic`: The ability to algorithmically identify and remove word-sized chunks of text from a buffer based on boundary detection.

### Modified Capabilities
- `universal-subtitle-search`: Enhanced with more efficient text manipulation controls.

## Impact

- **Operational Speed**: Faster query modification for power users familiar with terminal shortcuts.
- **Workflow Consistency**: Brings the search experience into alignment with other text-centric components of the acquisition suite.
- **Accessibility**: Symmetrical Russian layout support ensures a seamless experience for all primary users.
