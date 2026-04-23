# Design: Isotropic Mouse Hit-Testing

## System Architecture
The coordinate translation logic in `lls_core.lua` is updated to correctly map physical mouse events to the virtual OSD coordinate space.

### Components
1.  **Coordinate Translator (`dw_get_mouse_osd`)**:
    - Calculates the scaling factor `scale_isotropic = physical_height / 1080`.
    - Maps the Y-coordinate: `virtual_y = physical_y / scale_isotropic`.
    - Maps the X-coordinate: `virtual_x = 960 + (physical_x - physical_width / 2) / scale_isotropic`.
2.  **OSD Anchor**:
    - Assumes the Drum Window text is rendered centered at OSD X=960.

## Implementation Strategy
- **Isotropic Factor**: Derived from the window height to match `libass` behavior.
- **Center-Relative Math**: By subtracting the physical center (`ow / 2`) and then adding the virtual center (`960`), the logic correctly handles horizontal offsets even when the window is narrow.
- **Verification Loop**: Test in extreme aspect ratios (e.g., 4:3, 1:1, 21:9) to ensure the hit-test grid perfectly overlays the rendered text.
