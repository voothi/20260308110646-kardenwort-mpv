## Context

The `kardenwort-mpv` script uses a TSV file to store Anki highlights. With the introduction of "Advanced Indexing" (fragmented logical anchor grounding), the cost of parsing this file has increased significantly. Periodic sync timers (`anki_sync_period`) and frequent track changes trigger full re-loads of the TSV, causing unnecessary CPU spikes even when no data has changed.

## Goals / Non-Goals

**Goals:**
- Implement a lightweight change detection mechanism for the TSV database.
- Bypass expensive parsing loops (regex and index building) if the file content matches the in-memory state.
- Maintain zero external dependencies (pure Lua).
- Ensure 100% correctness: never skip a reload if the file has actually changed.

**Non-Goals:**
- Implementing cryptographic hashing (MD5/SHA) via external utilities (per user preference for minimal dependencies).
- Persisting file signatures between mpv restarts (in-memory session state is sufficient).
- Optimizing total TSV parsing time (the speed of the loop itself is out of scope).

## Decisions

### 1. Fingerprinting Method: MTime + Size
- **Decision**: Use a combination of file **Modification Time** (`mtime`) and **Size** as a proxy for a content hash.
- **Rationale**: Cryptographic hashing (MD5) would require calling `CertUtil` or `PowerShell`, which adds an external dependency and subprocess overhead. `mtime + size` is extremely fast and caught by `mp.utils.file_info` in a single system call.
- **Alternatives**: Pure Lua MD5 (too slow for large files), Subprocess hashing (dependency rejected).

### 2. State Storage: Transient FSM
- **Decision**: Store `ANKI_DB_MTIME` and `ANKI_DB_SIZE` in the `FSM` table.
- **Rationale**: Storing these in memory is sufficient to prevent the "reload-loop" during a single media session. 

### 3. "Safe" State Update
- **Decision**: Update the fingerprint variables only **after** the `FSM.ANKI_HIGHLIGHTS` table has been successfully populated with new data.
- **Rationale**: If parsing fails mid-way, the fingerprint remains "stale" (mismatch), ensuring the script will attempt a full reload again on the next tick instead of erroneously thinking the empty/failed state is "current".

## Risks / Trade-offs

- **[Risk] Metadata Collision**: A file content change that preserves exactly the same size and the same mtime (sub-second resolution) could be missed. 
  - **Mitigation**: Modern filesystems (NTFS/ext4) have high-resolution timestamps, and TSV appends (new highlights) always change the file size.
- **[Risk] State Desync**: If `FSM.ANKI_HIGHLIGHTS` is cleared externally but the fingerprint remains, a reload might be skipped.
  - **Mitigation**: Any logic that clears the path (`FSM.ANKI_DB_PATH`) now also resets fingerprints to `0`, forcing a reload.
