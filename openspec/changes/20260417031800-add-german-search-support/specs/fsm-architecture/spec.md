## ADDED Requirements

### Requirement: European Character Search Support
The Search Mode input grabber SHALL support the entry of German umlauts and the eszett character, along with their uppercase variants, by including them in the forced key binding whitelist.

#### Scenario: User types German characters in search field
- **WHEN** FSM.SEARCH_MODE is true and the user presses 'ä', 'ö', 'ü', 'ß', 'Ä', 'Ö', 'Ü', or 'ẞ'
- **THEN** THE OSD SHALL capture these characters, append them to FSM.SEARCH_QUERY, and update the search results dynamically.
