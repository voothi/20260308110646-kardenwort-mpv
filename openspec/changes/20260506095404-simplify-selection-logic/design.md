# Design: Simplify Selection Logic via FSM State

## Architecture
The FSM will now explicitly track the sorted state of the Pink Set.

### FSM Extensions
- `FSM.DW_CTRL_PENDING_LIST`: A sorted array of `{line, word}` objects representing the active Pink Set.

### Synchronized Update Flow
```mermaid
graph TD
    A[Input: Toggle Word] --> B[Update FSM.DW_CTRL_PENDING_SET Map]
    B --> C[Call sync_ctrl_pending_list]
    C --> D[Iterate Map]
    D --> E[Collect into List]
    E --> F[Sort List by Document Order]
    F --> G[Update FSM.DW_CTRL_PENDING_LIST]
```

### Simplified Copy Priority
```lua
function get_clipboard_text_smart()
    -- 1. Pink Set (Pre-sorted in FSM)
    if #FSM.DW_CTRL_PENDING_LIST > 0 then
        return prepare_export_text({type="SET", members=FSM.DW_CTRL_PENDING_LIST}, ...)
    end
    
    -- 2. Yellow Selection
    -- ... (Range / Pointer)
    
    -- 3. Context / Fallback
    -- ...
end
```

## Implementation Details
- **Sync Trigger**: `sync_ctrl_pending_list` is called at the end of `ctrl_toggle_word` and any function that clears the set.
- **Redundancy Removal**: `ctrl_commit_set` is refactored to use `FSM.DW_CTRL_PENDING_LIST` directly.
