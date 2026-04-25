## Why

This change formalizes the Universal Subtitle Search introduced in Release v1.24.0. To enhance the immersion experience, users require the ability to rapidly locate specific dialogue or phrases across the entire media file. This update introduces a dedicated search architecture that bridges the gap between text-based lookup and synchronized video navigation, complete with clipboard support and mouse interaction.

## What Changes

- Implementation of a **Universal Search Architecture**: A dedicated `search_osd` overlay that operates independently of the Drum Window, providing a standalone search bar.
- Implementation of **Robust Multi-Byte Input Handling**: Full support for UTF-8 and Cyrillic characters in the query buffer, including precise backspace logic for multi-byte deletion.
- Integration with the **System Clipboard**: Using PowerShell (`Get-Clipboard`) to allow users to paste external text directly into the search bar via `Ctrl+V`.
- Implementation of **Synchronized Playback Jumps**: Navigation from search results now uses `seek absolute+exact` to ensure the media engine synchronously updates all active tracks.
- Introduction of a **Mouse Interaction Engine** for search results: Users can now click on the OSD dropdown items using `MBTN_LEFT` to navigate instantly.

## Capabilities

### New Capabilities
- `universal-subtitle-search`: A high-performance search system that allows for rapid, fuzzy-matched navigation through subtitle data.
- `synchronized-context-jumps`: A navigation strategy that enforces synchronous track alignment during non-linear playback jumps.
- `search-clipboard-integration`: A mechanism for bridging the player's internal state with the external system clipboard for text input.

### Modified Capabilities
- None (Major feature addition).

## Impact

- **Search Efficiency**: Near-instant location of any phrase in the media file.
- **Workflow Integration**: Ability to copy text from dictionaries or browser and search within the subtitle stream.
- **Visual Accuracy**: Synchronized seeking ensures that jumping to a search result always renders the correct primary and secondary subtitles.
