## ADDED Requirements

### Requirement: Split-Term Multi-Word Highlighting
The visual highlighting system SHALL support non-contiguous subset matching for multi-word terms imported from the TSV database (e.g., terms that contain spaces). If the constituent words of a registered multi-word term are detected scattered but fully present within a specific localized context boundary (such as the same subtitle element/line), those words SHALL be highlighted with a distinctive "split select color" to signify their association.

#### Scenario: Contiguous highlighting takes precedence
- **WHEN** a multi-word TSV term exists that can be matched as a single exact, contiguous string within the text
- **THEN** it SHALL be rendered in the standard saved orange highlight.

#### Scenario: Successful application of the split highlight
- **WHEN** a multi-word TSV term (like "mache auf") exists in the TSV
- **AND** both "mache" and "auf" appear separated within the same subtitle text block
- **THEN** both individual words SHALL be styled using the `split_select_color` (which defaults to a purple color if unset).

#### Scenario: Incomplete presence disables split highlight
- **WHEN** a multi-word TSV term exists in the TSV (e.g., "mache auf")
- **AND** only one of the constituent words ("mache") is present in the subtitle line while the others are absent
- **THEN** no split highlight SHALL be applied to that single word.

### Requirement: Configurable Split Selection Color
The user SHALL be able to configure the specific hex color used for split-term highlighting via their player configuration.

#### Scenario: Custom split select color application
- **WHEN** the user provides `split_select_color=#123456` in `mpv.conf`
- **THEN** the rendering system uses this specific color instead of the default purple hex for split words.
