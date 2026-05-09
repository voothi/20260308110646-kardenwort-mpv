# Spec: openspec/changes/20260502165659-implement-spec-driven-testing/specs/automated-acceptance-testing/spec.md
# Scenario: Simulating a keypress
import time
from tests.ipc.mpv_ipc import query_lls_state


def test_toggle_drum_mode(mpv):
    mpv.ipc.command(['script-binding', 'lls_core/toggle-drum-mode'])
    time.sleep(0.1)  # one tick (~50 ms) for state to propagate
    state = query_lls_state(mpv.ipc)
    assert state['drum_mode'] == 'ON'
