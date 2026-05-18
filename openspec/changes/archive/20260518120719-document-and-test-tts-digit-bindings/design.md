## Context

Currently, language learners using Kardenwort need a fast, low-friction method to trigger external Text-to-Speech (TTS) applications to synthesize and play back subtitle sentences. Digit keys (`1`..`8`) are ideal for single-press triggers but were occupied by standard MPV video adjustments. Furthermore, standard MPV hotkeys are susceptible to layout conflicts when the active keyboard layout is switched (e.g., between English and Russian). This design addresses these issues by remapping video adjustments to layout-independent letter keys, freeing up the digit keys, and implementing dynamic layout-independent TTS hotkey bindings that inject Virtual Keys (VK).

## Goals / Non-Goals

**Goals:**
- Free up digit keys `1`..`8` for script-level configuration by migrating video adjustments.
- Remap video adjustments to layout-independent letter keys (`o`/`p`/`k`/`l` and Cyrillic equivalents `щ`/`з`/`л`/`д`).
- Implement 8 configurable TTS hotkeys (`tts_hotkey_1`..`8`) and trigger keys (`key_tts_1`..`8`) in Kardenwort.
- Use programmatic layout-independent Virtual Key (VK) code injection to trigger external TTS tools.
- Integrate active TTS digit bindings dynamically into the F1 Help HUD.
- Establish robust regression tests checking configuration, unignores in `input.conf`, and key presence.

**Non-Goals:**
- Embedding a TTS synthesis engine directly inside the Lua script.
- Supporting more than 8 concurrent TTS voice channels.

## Decisions

### Decision 1: Remap Video Adjustments to Layout-Independent Letters
- **Approach**: Shift contrast, brightness, gamma, and saturation adjustments from `1`/`2`/`3`/`4` to `o`/`p`/`k`/`l` and Cyrillic counterparts `щ`/`з`/`л`/`д`.
- **Rationale**: Digit keys are extremely easy to reach and perfect for quick actions like voice playback (TTS). Video adjustments are less frequently used and are more suited to layout-independent mnemonic letters.

### Decision 2: Inject Virtual Key (VK) Codes Layout-Independently
- **Approach**: Leverage Kardenwort's Virtual Key injection system (originally used for GoldenDict) to map `tts_hotkey_1`..`8` to low-level Windows VK codes.
- **Rationale**: Normal MPV key emulation fails or acts unpredictably when the active OS keyboard layout differs from the bound layout. Injecting direct VK codes via Windows API ensures layout-agnostic external triggering.

### Decision 3: Selective Digit Unignoring in input.conf
- **Approach**: Ensure `input.conf` explicitly comments out or removes standard ignore directives for active digits (`2`..`5` by default) while ignoring inactive digits (`1`, `6`..`8`).
- **Rationale**: MPV has a default behavior where unmapped keys are ignored. Selective unignoring allows active digits to pass through to Kardenwort's Lua handlers without losing general keyboard layout integrity for other digits.

## Risks / Trade-offs

- **[Risk] Mnemonic Letter Collision**: Remapping video adjustments to letter keys could conflict with other user-defined bindings.
  - **Mitigation**: The letter keys chosen (`o`/`p`/`k`/`l` and `щ`/`з`/`л`/`д`) were verified to be unmapped or easily ignorable in Kardenwort's default configuration.
- **[Risk] VK Code Trigger Collision**: Low-level Windows VK injection might conflict with other system-wide hotkeys.
  - **Mitigation**: Using a highly specific modifier combintation (`Ctrl+Alt+Shift`) for standard TTS hotkeys prevents accidental triggers.
