# Proposal: Centralized Config & Styling (v1.26.18)

## Problem
Script parameters were previously hardcoded in `lls_core.lua`, making it difficult for users to customize behavior without modifying code. Furthermore, configuration files (`mpv.conf`, `input.conf`) lacked a consistent visual structure, reducing readability and scannability.

## Proposed Change
Migrate all script-level parameters to the main `mpv.conf` using `script-opts`, standardize the visual styling of all configuration files, and restore helpful documentation templates.

## Objectives
- Enable full script customization from `mpv.conf` via `script-opts-append`.
- Standardize configuration file headers, subsection markers, and spacing.
- Provide documented templates for common user customizations.
- Ensure the core script remains stable with local fallback options.
- Maintain multi-layout support (English/Russian) in `input.conf`.

## Key Features
- **Centralized Script Options**: All `lls_core.lua` parameters moved to `mpv.conf`.
- **Styling Standardization**: Consistent header width (75 chars) and subsection formatting.
- **Template Restoration**: Labeled templates for language priorities and scaling overrides.
- **Lua Options Fallback**: Preserved local `Options` table for robustness.
