## Why

The application currently freezes during middle-click Anki export if the mouse pointer lands in the space between words or on lines containing only metadata tags. This is caused by an infinite loop in the string search logic when handling empty cleaned terms. Additionally, a general review identified several performance bottlenecks and stability risks in the core script.

## What Changes

- **Freeze Guard**: Implement safety checks in the context extraction engine to prevent infinite loops when processing empty or whitespace-only terms.
- **Enhanced Export Logic**: Harden the Anki export pipeline to validate terms after ASS tag and whitespace stripping.
- **Stability Hardening**: Update all recursive and `while` string search patterns to ensure mandatory forward progress.
- **Performance Optimization**: Introduce layout caching for the Drum Window to reduce redundant OSD calculations during mouse interaction.
- **TSV Handling Efficiency**: Optimize favorites (TSV) updates to avoid full file reloads for single-item additions.

## Capabilities

### New Capabilities
- `export-engine-hardening`: Implementation of validation and progress guards for the Anki export and string search engines.
- `drum-window-performance`: Introduction of layout caching and optimized hit-testing for the Drum Window.

### Modified Capabilities
- `mmb-drag-export`: Update the middle-click export requirement to include validation of the "cleaned" term to avoid empty captures.

## Impact

- `scripts/lls_core.lua`: Significant changes to the export and layout rendering logic.
- `script-opts/lls.conf`: Potential new options for performance tuning.
