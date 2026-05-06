## 1. Specification Hardening
- [ ] 1.1 Add requirement for dual-lane viewport synchronization (lower and upper lines scroll together under a shared manual offset policy).
- [ ] 1.2 Add requirement for synchronized highlight semantics across both lanes during manual scroll.
- [ ] 1.3 Add requirement defining wheel behavior outside subtitle hit zones (pass-through vs consume) with no ambiguity.

## 2. FSM Safety Clarification
- [ ] 2.1 Add requirement that drum scroll interactions do not directly mutate autopause transition state.
- [ ] 2.2 Add scenario coverage for `AUTOPAUSE ON/OFF` x `PHRASE/MOVIE` during manual scroll.

## 3. Regression Protocol
- [ ] 3.1 Add a comparison checklist against reference commit `4c634ed422844c475293dac07bad7d149e9f9df8`.
- [ ] 3.2 Define acceptance scenarios for primary-only, secondary-only, and dual-track subtitle configurations.
