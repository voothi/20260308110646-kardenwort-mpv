## Context

The Kardenwort-mpv ecosystem relies on tight integration between `mpv` key bindings and external dictionary tools (GoldenDict). Users often switch between English and Russian keyboard layouts, which breaks traditional `mpv` key bindings that are character-literal based. Previously, users had to manually configure dual bindings (e.g., `Shift+e Shift+у`), which was error-prone and incomplete.

## Goals / Non-Goals

**Goals:**
- Implement a layout-agnostic binding layer that automatically expands English shortcuts to Russian ones.
- Ensure the GoldenDict trigger (outbound Virtual Keys) is layout-independent by providing a comprehensive VK mapping for Cyrillic.
- Support multi-hotkey configuration for triggers to increase reliability.

**Non-Goals:**
- Dynamic layout detection (the system will bind both layouts simultaneously).
- Support for layouts other than English (QWERTY) and Russian (ЙЦУКЕН).

## Decisions

- **Static Mapping Table**: Use a predefined `EN_RU_MAP` to translate A-Z and common punctuation characters.
- **Sequential Binding**: The `bind` and `parse_and_collect` functions will now accept a single key string and expand it into a list of keys to be registered with `mp.add_key_binding`.
- **Shift Casing Redundancy**: To mitigate OS-level differences in how Shift+Cyrillic is reported, the system will bind both the lowercase and uppercase versions of the Cyrillic equivalent when a `Shift` modifier is detected.
- **Comprehensive VK Mapping**: The `vk_codes` table for GoldenDict triggers is expanded to cover all alphanumeric keys and their Russian counterparts, mapping them to the same physical Virtual Key code.

## Risks / Trade-offs

- **Binding Pollution**: Registering multiple keys for the same action increases the number of active bindings in `mpv`, though this is negligible for performance.
- **Layout Collisions**: If a user has a custom layout that differs significantly from standard ЙЦУКЕН, the automatic mapping might not match their physical keys.
