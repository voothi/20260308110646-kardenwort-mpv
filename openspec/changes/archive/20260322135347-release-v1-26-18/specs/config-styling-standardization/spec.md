# Spec: Config Styling Standardization

## Context
A consistent visual structure in configuration files improves user maintenance and readability.

## Requirements
- Standardize major headers to `# ===========================================================================` (75 chars).
- Standardize subsections to `# --- Title ---`.
- Normalize vertical spacing (e.g., single blank line between properties, double blank line between major sections).
- Apply these rules to both `mpv.conf` and `input.conf`.

## Verification
- Visually inspect `mpv.conf` and `input.conf` for uniform header width.
- Confirm all subsections use the standardized marker style.
