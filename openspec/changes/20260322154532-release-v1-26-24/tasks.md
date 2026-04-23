# Tasks: Isotropic Mouse Hit-Testing

## 1. Math Reconstruction
- [x] Analyze hit-test drift in non-16:9 aspect ratios
- [x] Implement height-derived `scale_isotropic` factor
- [x] Re-anchor X-axis math to `ow / 2` and OSD `960`

## 2. Validation
- [x] Verify selection accuracy in standard 16:9 window
- [x] Verify selection accuracy in narrow (8:9) snapped window
- [x] Verify accuracy across different physical screen resolutions
- [x] Confirm no regressions in vertical (Y-axis) hit-testing
