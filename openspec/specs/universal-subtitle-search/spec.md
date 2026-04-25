## ADDED Requirements

### Requirement: Independent Search Overlay
The system SHALL provide a dedicated search overlay (`search_osd`) that can be summoned independently of the Drum Window.

#### Scenario: Summoning search
- **WHEN** the user presses `Ctrl+F`
- **THEN** the system SHALL display the search bar and capture keyboard input into the search buffer.

### Requirement: Multi-Byte UTF-8 Input Handling
The search system SHALL correctly process multi-byte characters, including Cyrillic, for both input and deletion.

#### Scenario: Deleting a Russian character
- **WHEN** the user presses Backspace on a Russian character in the search bar
- **THEN** the system SHALL correctly identify the multi-byte sequence and remove the entire character.

### Requirement: Mouse-Interactive Result List
The search overlay SHALL support mouse-based selection of search results using OSD-coordinate hit-testing.

#### Scenario: Clicking a search result
- **WHEN** the user clicks on an item in the search results dropdown
- **THEN** the system SHALL jump to the corresponding time in the media.
