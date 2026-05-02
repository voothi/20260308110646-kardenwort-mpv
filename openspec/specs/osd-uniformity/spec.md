# Specification: Rendering Uniformity

## Overview
All OSD overlays must exhibit identical visual properties (brightness, sharpness, and layering) to ensure a premium, unified user experience.

## Standardized Tags
The following ASS tags are mandatory for all LLS renderers:

| Tag | Purpose | Standard |
|-----|---------|----------|
| `\1c` | Primary Color | Use `{\1c&H[COLOR]&}` to explicitly target the primary text layer. |
| `\3c` | Border Color | Standardized border color for all overlays. |
| `\q2` | Wrap Style | Enforced "No Wrap" for all list-based and context-based displays. |
| `\vsp` | Spacing | Support for `{\vsp%g}` for fine-tuned vertical adjustment. |

## Opacity and Alpha
All transparency settings must be processed through the `calculate_ass_alpha` utility to ensure consistent interpretation of the `00-FF` (hex) scale across `\1a`, `\3a`, and `\4a`.

## Transparency Management

### Requirement: Alpha Context Synchronization
The rendering engine SHALL preserve global `bg_opacity` settings across all OSD layers by explicitly restoring the background alpha context after every surgical tag injection.

#### Scenario: Navigating with transparent background
- **WHEN** the `dw_bg_opacity` is set to a non-zero value (semi-transparent)
- **THEN** all rendered subtitle lines SHALL maintain their intended transparency even when containing high-intensity interactive highlights.

### Requirement: Uniform Active Subtitle Alignment
The active subtitle color SHALL be unified across all modes following the historical transition from Blue to White.

#### Scenario: Rendering Active Subtitles
- **WHEN** a subtitle line becomes active for playback or navigation
- **THEN** it SHALL be rendered in `White (BGR: FFFFFF | RGB: #FFFFFF)`
