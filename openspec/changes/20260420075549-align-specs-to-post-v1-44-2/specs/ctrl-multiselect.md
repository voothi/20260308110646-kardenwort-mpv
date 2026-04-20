## ADDED Requirements

### Requirement: Persistent Selection Accumulator (Cool Path)
The paired selection set SHALL persist indefinitely across modifier releases and navigation to support minimalist input devices (e.g., remotes).
- **Persistence**: Releasing the pairing key MUST NOT clear the `ctrl_pending_set`.
- **Explicit Discard**: The system SHALL provide a dedicated `Ctrl+ESC` gesture to clear the persistent set.

### Requirement: Multi-Pivot Term Composition
Upon commit (Add action), the system SHALL sort the accumulated tokens in document order (Line, then Word index) and join them using the smart-joiner-service.
- **Coordinates**: The exporter MUST generate a coordinate map in the format `LineOffset:WordIndex:TermPos` for every word in the selection.
- **Punctuation**: Internal dashes or slashes MUST be preserved within the final term.
- **Context Padding**: The extracted context window SHALL span from the earliest to the latest selected line, each padded by `anki_context_lines` lines.

### Requirement: Harmonic "Warm vs. Cool" Chromatics
The system SHALL use distinct chromatic paths to signal interaction mode.
- **Cool Path (Paired)**: Pending set rendered in **Neon Pink (#FF88FF)**.
- **Warm Path (Contiguous)**: Focus/Range rendered in **Gold (#00CCFF)**.
- **Resulting Matches**: Saved contiguous terms render Orange; non-contiguous render Purple.
