## ADDED Requirements

### Requirement: source_url Anki Field Mapping
Discovered media source URLs SHALL be made available for Anki exports via a standardized `source_url` keyword.
- **Behavior**: The exporter MUST populate the mapped Anki field with the discovered URL (if cached) during minden row generation.
