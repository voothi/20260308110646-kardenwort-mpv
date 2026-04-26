## ADDED Requirements

### Requirement: OSD-Agnostic Track Loading
The system SHALL index all dialogue lines from external subtitle files regardless of their character set or language, ensuring that both primary and secondary tracks are fully resident in memory.

#### Scenario: Loading Russian ASS Translation
- **WHEN** an ASS subtitle track containing Cyrillic characters is loaded.
- **THEN** the system SHALL NOT filter out these lines during the ingestion phase.
- **AND** the `Tracks.sec.subs` table SHALL contain all dialogue entries for use in translation copy and tooltip rendering.

## MODIFIED Requirements

### Requirement: Robust Karaoke Merging
The system SHALL correctly merge identical subtitle text fragments (karaoke tokens) into a single dialogue block, even when they are separated by interleaved translation tracks, across all supported file formats (ASS and SRT).

#### Scenario: Merging interleaved karaoke
- **WHEN** loading any supported subtitle file (ASS or SRT) with alternating tracks.
- **THEN** identical raw text entries found within a 10-entry backward window SHALL be merged into one.
