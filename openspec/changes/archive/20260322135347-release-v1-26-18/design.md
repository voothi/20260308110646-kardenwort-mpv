# Design: Centralized Config & Styling

## System Architecture
The configuration system follows a hierarchical model where `mpv.conf` settings override script-level defaults via `mp.options.read_options`.

### Components
1.  **Configuration Hub (`mpv.conf`)**:
    - Centralized repository for all `script-opts`.
    - Uses `script-opts-append` to add settings for the `lls_core` script.
    - Follows a 75-character width header standard.
2.  **Input Map (`input.conf`)**:
    - Standardized formatting for keybindings.
    - Preserves dual-layout (EN/RU) support.
3.  **Options Loader (`lls_core.lua`)**:
    - Uses `mp.options` to merge external settings into the local `Options` table.

## Implementation Strategy
- **Header Standard**: `# ===========================================================================`
- **Subsection Standard**: `# --- Section Title ---`
- **Fallback Logic**: 
  ```lua
  local Options = {
      -- Hardcoded defaults here
  }
  mp.options.read_options(Options, "lls_core")
  ```
- **File Audit**: Manually adjust spacing and alignment in all `.conf` files to ensure a professional look.
