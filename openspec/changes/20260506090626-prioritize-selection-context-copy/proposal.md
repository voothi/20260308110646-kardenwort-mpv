# Proposal: Prioritize Selection in Context Copy

## Problem
Currently, the "Context Copy" mode (`FSM.COPY_CONTEXT == "ON"`) sometimes overrides manual selections in the Drum Window, or lacks clarity in its priority vs manual multi-word selections (Pink Set). Users want a strict priority hierarchy that allows them to "regulate" what is copied using the `Esc` key stages.

## Solution
Implement a multi-tier priority system in `get_clipboard_text_smart`:
1. **Pink Set** (Multi-word selection via Ctrl+Click)
2. **Yellow Range** (Range selection via Shift+Click or Drag)
3. **Yellow Pointer** (Single word selection via Click)
4. **Context Copy** (Surrounding dialogue if enabled)
5. **Standard Fallback** (Active line)

By following this hierarchy, users can use `Esc` to clear selections level by level until they reach the desired scope (from precise term to full context).

## Impact
- Improved precision for immersion workflows.
- Seamless interaction between Drum Window navigation and clipboard harvesting.
- Fully compatible with existing `Esc` stage logic.
