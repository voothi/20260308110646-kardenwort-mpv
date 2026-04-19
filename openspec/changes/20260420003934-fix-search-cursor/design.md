## Context

The global search functionality in `lls_core.lua` uses a custom OSD overlay. Currently, when the search query is empty, the `draw_search_ui` function renders a placeholder string `Search...|`. The `|` symbol represents the active input cursor. Due to the way alpha tags (`{\1a&HAA&}`) are applied, the cursor is at the end of the text.

## Goals / Non-Goals

**Goals:**
- Move the cursor symbol (`|`) to the beginning of the placeholder text.
- Ensure the cursor remains fully opaque and the placeholder text remains dimmed.

**Non-Goals:**
- Implementing real-time cursor movement within the placeholder.
- Modifying the styling or behavior of the search results dropdown.

## Decisions

### 1. Cursor Positioning in `display_query`
We will reorder the components of the `display_query` string in the `#q_table == 0` block of `draw_search_ui`.
- **Old Order**: `[Alpha:Dimmed]Search...[Alpha:Opaque]|`
- **New Order**: `|[Alpha:Dimmed]Search...[Alpha:Opaque]`

**Rationale**: Prepending the cursor allows it to inherit the default (opaque) alpha from the initial formatting or previous OSD state, making it stand out as the active focal point.

### 2. Alpha Tag Retention
We will retain the `{\1a&H00&}` tag at the end of the string to ensure a "clean exit" for the alpha channel, preventing styling leakage if other elements are appended.

## Risks / Trade-offs

- **[Risk] Visual Inconsistency** → The cursor might look slightly different depending on the font's character spacing at the start vs end. **Mitigation**: Standardizing on the `|` character which is vertically symmetrical.
