## ADDED Requirements

### Requirement: DW Draw Path MUST Tolerate Partial Layout Cache Entries
DW rendering SHALL tolerate subtitle `layout_cache` entries produced by non-draw paths that omit draw-only fields.

#### Scenario: Partial entry fallback to full draw entry
- **WHEN** `dw_build_layout` receives a subtitle whose cached entry lacks required draw fields (`height`, mapping metadata, or sub index)
- **THEN** the renderer SHALL rebuild a full draw entry before aggregation
- **AND** the render tick SHALL complete without nil indexing or arithmetic failures.

### Requirement: ensure_sub_layout Compatibility Metadata
The navigation layout helper SHALL provide enough metadata to remain compatible with draw-path reuse.

#### Scenario: Height-compatible entry from ensure_sub_layout
- **WHEN** `ensure_sub_layout` creates or refreshes `sub.layout_cache.entry`
- **THEN** the entry SHALL include a numeric `height` derived from active DW font and line geometry
- **AND** any caller that requires additional draw fields SHALL be able to detect and rebuild safely.
