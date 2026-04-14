## 1. Configuration Setup

- [x] 1.1 Add `split_select_color` configuration default (e.g., `#B088FF` purple) to the Kardenwort-mpv `mpv.conf` under the appropriate interface section.

## 2. Term Parsing Modification

- [x] 2.1 Update the TSV loading loop (likely in `lls_core.lua`'s `update_highlight_dict` or similar parsing logic) to detect multi-word terms (containing space) and cache them as arrays into a dedicated list or new `multiword_highlight_dict`.

## 3. Rendering Engine Integration

- [x] 3.1 Update the visual rendering loop (`build_word_tags` or similar logic in `lls_core.lua`) to capture the set of words in the current subtitle line/block.
- [x] 3.2 Add proximity scanning logic: if all components of a registered split-term appear within the current bounded text, flag those specific components.
- [x] 3.3 Apply the `split_select_color` ASS wrapper tag to words flagged as split-terms, ensuring standard orange highlights retain rendering precedence.
- [x] 3.4 Clear selection anchor and cursor immediately upon `Ctrl+MMB` commit to ensure the new highlight color is visible without moving the mouse.
