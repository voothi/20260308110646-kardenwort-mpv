## 1. Engine Update

- [ ] 1.1 Update nesting level algorithm in `lls_core.lua` to calculate intersection depth for split term bounding boxes.
- [ ] 1.2 Modify the highlight rendering generation code in `lls_core.lua` to apply alpha-channel/gradient shading to `split_select_color` highlights based on their calculated nesting depth, matching the behavior of contiguous multi-word terms.
