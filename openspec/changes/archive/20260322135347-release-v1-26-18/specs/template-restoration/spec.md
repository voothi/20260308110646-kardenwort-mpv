# Spec: Template Restoration

## Context
Users need guidance on common customization tasks via pre-defined templates.

## Requirements
- Restore commented-out examples in `mpv.conf` and `input.conf`.
- Label templates explicitly as `(Template)`.
- Include templates for:
    - Language priorities (`secondary-sub-lang`).
    - Visibility toggles.
    - Font scaling overrides.

## Verification
- Confirm that `mpv.conf` contains labeled template sections.
- Verify that templates are commented out by default to avoid unintended behavior.
