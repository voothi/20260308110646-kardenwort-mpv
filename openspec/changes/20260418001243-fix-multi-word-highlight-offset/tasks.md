## 1. Implementation

- [ ] 1.1 Update `calculate_highlight_stack` in `scripts/lls_core.lua`. 
- [ ] 1.2 Modify Phase 2 index check to be offset-aware: `context_satisfied = (data.index == (target_l_idx - (term_offset - 1)))`.

## 2. Verification

- [ ] 2.1 Verify that multi-word phrases (e.g., "41 bis 45") highlight in a consistent Orange color in the Drum Window.
- [ ] 2.2 Confirm that words in the phrase no longer turn Purple (Split Match) if they are in sequence.
- [ ] 2.3 Verify that "bleed" prevention still works (identical phrases at different indices are not highlighted).
