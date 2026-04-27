# Specification: Rendering Uniformity

## Overview
All OSD overlays must exhibit identical visual properties (brightness, sharpness, and layering) to ensure a premium, unified user experience.

## Standardized Tags
The following ASS tags are mandatory for all LLS renderers:

| Tag | Purpose | Standard |
|-----|---------|----------|
| `\1c` | Primary Color | Use `{\1c&HFFFFFF&}` (Primary color tag) instead of `\c`. |
| `\3c` | Border Color | Standardized border color for all overlays. |
| `\q2` | Wrap Style | Enforced "No Wrap" for all list-based and context-based displays. |
| `\vsp` | Spacing | Support for `{\vsp%g}` for fine-tuned vertical adjustment. |

## Opacity and Alpha
All transparency settings must be processed through the `calculate_ass_alpha` utility to ensure consistent interpretation of the `00-FF` (hex) scale across `\1a`, `\3a`, and `\4a`.
