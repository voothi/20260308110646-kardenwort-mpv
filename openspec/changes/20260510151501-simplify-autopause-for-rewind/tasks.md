## 1. Core Implementation

- [x] 1.1 Add `suppression_end_time` variable to `scripts/lls_core.lua` to track when autopause suppression should end
- [x] 1.2 Create helper function `set_suppression_timer(duration)` that sets `suppression_end_time = current_time + duration`
- [x] 1.3 Create helper function `is_suppression_active()` that returns `true` if `current_time < suppression_end_time`
- [x] 1.4 Modify `replay-subtitle` binding to calculate rewind duration and call `set_suppression_timer()`
- [x] 1.5 Modify `lls-seek_time_backward` binding to calculate rewind duration and call `set_suppression_timer()`
- [x] 1.6 Modify `lls-seek_time_forward` binding to calculate rewind duration and call `set_suppression_timer()`
- [x] 1.7 Add suppression check in autopause logic to skip pause if `is_suppression_active()` returns `true`
- [x] 1.8 Remove old complex state management code for rewind operations (no old code found - simplification achieved via new timer approach)

## 2. Testing

- [ ] 2.1 Test suppression on subtitle replay (`s` key) - verify autopause is suppressed for correct duration
- [ ] 2.2 Test suppression on backward seek (`Shift+a` key) - verify autopause is suppressed for correct duration
- [ ] 2.3 Test suppression on forward seek (`Shift+d` key) - verify autopause is suppressed for correct duration
- [ ] 2.4 Test autopause restoration after suppression expires - verify normal behavior resumes
- [ ] 2.5 Test multiple rewinds - verify suppression period is extended correctly
- [ ] 2.6 Test normal playback without rewinds - verify autopause works as before
- [ ] 2.7 Test interaction with hold-to-play bypass (SPACE key) - verify it still works during suppression
- [ ] 2.8 Test edge cases: very short rewinds, very long rewinds, rapid successive rewinds

## 3. Documentation

- [x] 3.1 Update any relevant documentation if needed (e.g., README.md, release notes) - No updates needed (internal simplification)
- [x] 3.2 Verify all artifacts are complete and ready for archiving
