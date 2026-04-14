## 1. Engine Update

- [x] 1.1 Update `Option` defaults in `lls_core.lua` to include `anki_split_depth_1/2/3` with appropriate purple shades.
- [x] 1.2 Update nesting level algorithm in `lls_core.lua` to calculate intersection depth for split term bounding boxes.
- [x] 1.3 Modify the highlight rendering generation code in `lls_core.lua` to select between `anki_split_depth_1/2/3` based on the calculated nesting depth, matching the behavior of contiguous multi-word terms.
- [x] 1.4 Add the new split depth options to `mpv.conf` for user visibility and customization.
