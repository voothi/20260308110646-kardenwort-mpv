## Context

The Kardenwort-mpv project has transitioned through multiple color palettes and functional renamings (e.g., Reel → Drum, Yellow → Gold). Currently, these definitions are fragmented across `mpv.conf`, `lls_core.lua`, and OpenSpec artifacts. AI agents frequently struggle with the ASS (BGR) vs. Web (RGB) hex notation flip, leading to incorrect style recommendations.

## Goals / Non-Goals

**Goals:**
- Create a centralized "Ground Truth" for all project terminology and historical transitions.
- Standardize color specifications using a mandatory Dual-Notation (BGR | RGB) format.
- Update existing core script comments and configuration files to reflect the canonical thesaurus.

**Non-Goals:**
- Modifying the actual functional behavior of the rendering engine.
- Changing the current project colors (this task is about standardization, not restyling).
- Auditing third-party dependencies.

## Decisions

- **Linear Evolution Ledger**: A Markdown table in the project spec will track renamings by ZID, allowing the AI to follow identity chains (A → B → C).
- **Dual-Notation Hex Codes**: Every mention of a color hex in documentation or code comments must include both the BGR (mpv-native) and RGB (standard) values.
- **Thesaurus Integration**: Domain terms like "Warm Path" (Contiguous) and "Cool Path" (Split) will be formally mapped to their respective color values in the code.

## Risks / Trade-offs

- **Risk**: Potential for human error when manually calculating dual-notation hex values.
- **Trade-off**: The documentation becomes slightly more verbose due to the dual-notation requirement, but this is necessary for AI reliability.
