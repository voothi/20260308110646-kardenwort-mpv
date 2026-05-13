# Proposal: Search Algorithm Test Coverage

## Purpose
The search algorithm in Kardenwort is complex, involving multi-dimensional relevance scoring with various bonuses (exact match, sequential order, compactness, start-of-sentence). While structural tests exist, they only verify the presence of logic in the source code. This proposal aims to implement comprehensive functional acceptance tests that validate the actual behavior of the algorithm using IPC diagnostic hooks.

## What Changes
- Implement a new acceptance test suite `tests/acceptance/test_20260513121332_search_algorithm_nuances.py`.
- Define a specialized SRT fixture `tests/fixtures/20260513121332-search-nuances.srt` with edge cases for ranking.
- Utilize the `test-set-search-query` IPC hook to trigger the algorithm and verify the resulting `SEARCH_RESULTS` state.

## Capabilities

### New Capabilities
- `search-algorithm-validation`: Functional verification of the multi-dimensional search scoring engine.

### Modified Capabilities
- None (Requirement-level behavior remains the same, this is purely for testing).

## Impact
- `scripts/kardenwort/main.lua`: No changes expected, unless bugs are found during testing.
- `tests/acceptance/`: New test file.
- `tests/fixtures/`: New fixture file.
