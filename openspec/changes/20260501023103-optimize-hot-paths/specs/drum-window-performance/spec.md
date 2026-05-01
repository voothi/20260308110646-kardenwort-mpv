## ADDED Requirements

### Requirement: Split-Match Cache Invalidation on TSV Reload
When `load_anki_tsv()` replaces `FSM.ANKI_HIGHLIGHTS` with freshly parsed data, the system SHALL clear the `__split_valid_indices` cache on all loaded subtitle objects in both `Tracks.pri.subs` and `Tracks.sec.subs`.

#### Scenario: External TSV modification triggers reload
- **WHEN** the periodic sync timer detects that the TSV file has been modified externally (mtime/size changed) and triggers a full re-parse
- **THEN** every subtitle object's `__split_valid_indices` field SHALL be set to `nil`, forcing `calculate_highlight_stack` to recompute split matches on the next evaluation

#### Scenario: No-op reload (fingerprint unchanged)
- **WHEN** the periodic sync timer runs but the TSV file fingerprint (mtime + size) has not changed
- **THEN** no cache flushing SHALL occur (the existing `__split_valid_indices` caches remain valid)
