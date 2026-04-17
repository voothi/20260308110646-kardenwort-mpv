## Why

Users cannot currently type German umlauts (ä, ö, ü) or the eszett (ß) in the search field because they are missing from the input whitelist. This prevents searching for German terms containing these characters, which is a major friction point for German language learners who are the primary users of this tool.

## What Changes

- **Update Search Whitelist**: Modify the character whitelist in `manage_search_bindings` to include German umlauts (`ä`, `ö`, `ü`, `Ä`, `Ö`, `Ü`) and the eszett (`ß`, `ẞ`).
- **Consistent Keyboard Binding**: Ensure that these characters are correctly mapped to `mp.add_forced_key_binding` so they are captured by the search input buffer while Search Mode is active.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `fsm-architecture`: Extend the "Search Mode Hijack" requirement to explicitly support common European/German characters in the input grabber.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (specifically the character whitelist in `manage_search_bindings`).
- **User Experience**: Critical fix for German searching; no impact on performance or existing English/Russian search capabilities.
