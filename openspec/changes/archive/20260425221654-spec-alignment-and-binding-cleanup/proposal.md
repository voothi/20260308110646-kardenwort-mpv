## Why

Following a comprehensive code compliance audit, two minor discrepancies were identified: the temporal gap threshold in the `inter-segment-highlighter` specification does not match the actual implementation (which uses 60s for better recall), and several redundant key bindings exist in `lls_core.lua` that are already handled by `input.conf`. This change synchronizes the documentation with the code and cleans up the script.

## What Changes

- **Spec Alignment**: Update the `inter-segment-highlighter` specification to reflect the 60.0s temporal gap threshold used by the Anki highlighter.
- **Code Cleanup**: Remove redundant `mp.add_forced_key_binding(nil, ...)` calls for Book Mode in `lls_core.lua`.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `inter-segment-highlighter`: Updating the temporal proximity requirement from 1.5s to 60s.

## Impact

- **Specification Integrity**: Ensures that future audits correctly identify the 60s threshold as compliant.
- **Script Cleanliness**: Reduces visual noise and redundant logic in `lls_core.lua`.
