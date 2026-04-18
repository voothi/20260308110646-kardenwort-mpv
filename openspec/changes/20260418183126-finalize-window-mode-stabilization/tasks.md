## 1. Unified Rendering Priorities

- [ ] 1.1 Implement Level 1 priority in draw_dw and draw_drum: Persistent Selection (Pale Yellow) must override all other states.
- [ ] 1.2 Implement Level 2 priority: Database Highlights (Orange/Purple/Brick) must be rendered if no persistent selection exists.
- [ ] 1.3 Implement Level 3 priority: Active Preview/Hover (Vibrant Yellow) must only be applied to base/unhighlighted words.
- [ ] 1.4 Update FSM.DW_CTRL_PENDING_SET lookup to correctly handle multi-subtitle selections.

## 2. Phrase-Aware Punctuation Coloring

- [ ] 2.1 Refactor the formatted_words collection loop to identify trailing or internal punctuation tokens.
- [ ] 2.2 Implement a "Phrase Continuity" check: If punctuation is preceded and followed by tokens with the same 	erm_key, apply the phrase color to the punctuation.
- [ ] 2.3 Ensure lone punctuation tokens (not bound to a phrase) remain unhighlighted per the specification.

## 3. High-Recall Hardening & Clean-up

- [ ] 3.1 Strict Index Grounding: Verify that all Local Mode highlights are anchored by source_index.
- [ ] 3.2 Global Neighborhood Pass: Verify that calculate_highlight_stack correctly applies the ±3 word neighbor verification for Global Mode.
- [ ] 3.3 Final Pass: Ensure get_center_index is reliably used for temporal grounding of split matches.
