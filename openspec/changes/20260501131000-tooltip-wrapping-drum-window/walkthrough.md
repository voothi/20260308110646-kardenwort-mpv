# Technical Walkthrough: Tooltip Wrapping Engine

This document provides a surgical guide for the implementation of word-wrapping in the Drum Window tooltip, ensuring architectural parity with the `v1.58.0` hardening standards.

## 1. Intent: Architectural Parity
The core intention is to transition the tooltip from a "raw text dump" to a "structured layout block". This requires reusing the project's token-based layout heuristic to ensure that wrapping decisions (especially for Cyrillic and punctuation) are consistent across all OSD layers.

## 2. Surgical Anchors (Injection Points)

### Anchor A: Cache Invalidation
**Location**: `lls_core.lua` around **Line 2154** (inside `flush_rendering_caches`).
**Action**: Add the following to ensure the tooltip is cleared during track reloads or option updates:
```lua
dw_tooltip_osd.data = ""
dw_tooltip_osd:update()
DW_TOOLTIP_DRAW_CACHE = { target_idx = -1, osd_y = -1, version = -1 }
```

### Anchor B: Rendering Pipeline
**Location**: `lls_core.lua` between **Lines 3382 and 3389** (inside `draw_dw_tooltip`).
**Action**: Replace the simple `gsub` loop with a token-aware wrapping engine.

## 3. The Wrapping Invariant (Pseudocode)

The implementation MUST follow this logic to ensure $O(1)$ character-aware width calculations:

```lua
-- Constants for the engine
local max_w = 1400
local fs = Options.tooltip_font_size
local font_name = Options.tooltip_font_name
local space_w = dw_get_str_width(" ", fs, font_name)

-- Loop for each logical subtitle in the context range
for i = start_idx, end_idx do
    local tokens = get_sub_tokens(subs[i], true) -- Use rich tokens for verbatim fidelity
    local vlines = {}
    local current_line_tokens = {}
    local current_w = 0
    
    for _, t in ipairs(tokens) do
        local tw = dw_get_str_width(t.text, fs, font_name)
        local space = (#current_line_tokens > 0) and space_w or 0
        
        if current_w + space + tw > max_w and #current_line_tokens > 0 then
            table.insert(vlines, table.concat(current_line_tokens, " "))
            current_line_tokens = {t.text}
            current_w = tw
        else
            table.insert(current_line_tokens, t.text)
            current_w = current_w + space + tw
        end
    end
    if #current_line_tokens > 0 then 
        table.insert(vlines, table.concat(current_line_tokens, " ")) 
    end
    
    -- Store vlines for later height summation and join with \N
end
```

## 4. Edge Case Management
- **Alignment**: The entire block uses `\an6` (Right-Center). `\N` split lines SHALL automatically be right-aligned within the block by the ASS renderer.
- **Horizontal Overflow**: If a single token is wider than `1400px`, force the wrap *after* that token to ensure visibility.
- **Vertical Clamping**: Use the aggregate height of all visual lines to calculate `block_height` for the OSD centering logic.

## 5. Contractor Non-Negotiables
- **Verbatim Standard**: Use `get_sub_tokens(s, true)`. DO NOT apply automated whitespace cleaning.
- **Performance**: Implement `DW_TOOLTIP_DRAW_CACHE` to avoid re-calculating the wrap if `target_line_idx` and `osd_y` are unchanged.
- **Style**: Use `ipairs` for all loops and maintain standard indentation.
