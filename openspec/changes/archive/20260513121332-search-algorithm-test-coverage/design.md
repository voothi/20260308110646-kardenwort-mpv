## Context
The Kardenwort search algorithm (`calculate_match_score`) uses a point-based system to rank results. Currently, this logic is only verified by structural tests (grepping source code). To ensure robustness, especially with Cyrillic characters and complex fuzzy patterns, functional tests are needed.

## Goals / Non-Goals

**Goals:**
- Implement a functional test suite for the search ranking algorithm.
- Verify exact matches, prefix/substring distinctions, sequential bonuses, and compactness bonuses.
- Ensure Cyrillic support is correctly handled in scoring.
- Use existing IPC infrastructure (`test-set-search-query`) to interact with the running script.

**Non-Goals:**
- Modifying the search algorithm itself (unless bugs are discovered).
- Testing the Search UI/OSD rendering (already covered or out of scope for this algorithmic focus).

## Decisions
- **Test Framework**: Use `pytest` with the existing acceptance test infrastructure.
- **Data Source**: Create a specialized SRT fixture `20260513121332-search-nuances.srt` with a curated set of strings to test various scoring combinations.
- **Verification Method**: Set the search query via IPC, then query the `user-data/kardenwort/state` property to inspect the `SEARCH_RESULTS` table. We will assert the order of the results (indices) matches the expected ranking.

## Risks / Trade-offs
- **IPC Latency**: Acceptance tests involve starting mpv and communicating via sockets. This is slower than unit tests but provides higher fidelity for Lua environment behaviors.
- **State Synchronization**: We must ensure `update_search_results()` is called and state is updated before reading the property. The `test-set-search-query` hook already triggers an update.
