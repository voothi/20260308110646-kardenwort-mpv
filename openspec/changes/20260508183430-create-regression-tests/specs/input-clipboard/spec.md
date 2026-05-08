## ADDED Requirements

### Requirement: Input - Layout-Agnostic Hotkeys and False Positive Prevention
Hotkeys must work across different keyboard layouts and avoid false positive triggers as per archives 20260503212729 and 20260503203618.

#### Scenario: Layout-Agnostic Binding
- **WHEN** pressing a mapped key (e.g., `ё` for Russian layout mapped to `` ` ``).
- **THEN** the corresponding command must be executed correctly.

#### Scenario: False Positive Prevention
- **WHEN** a key is pressed that is a subset or partial match of a complex binding.
- **THEN** it should not trigger the complex binding unintentionally.

### Requirement: Clipboard - Reliability and Selection Priority
Clipboard operations must be reliable and prioritize active selections as per archives 20260503131410 and 20260502211505.

#### Scenario: Selection Priority in Context Copy
- **WHEN** a selection exists and a copy command is issued.
- **THEN** the selection should be copied instead of the whole subtitle context.
