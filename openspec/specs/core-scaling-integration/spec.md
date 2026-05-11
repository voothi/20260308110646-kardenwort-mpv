# Spec: Core Scaling Integration

## Context
Font scaling was previously handled by an external script, leading to fragmentation.

## Requirements
- Move logic from `fixed_font.lua` into `kardenwort/main.lua`.
- Subtitle tracks of type `.ass` must be automatically excluded from scaling logic.
- Standard `.srt` or text-based subtitles must be scaled based on the calculated compensation.

## Verification
- Confirm `scripts/fixed_font.lua` is deleted.
- Verify that `.srt` subtitles change size when the window is resized.
- Verify that `.ass` subtitles do NOT change size/position when the window is resized.

