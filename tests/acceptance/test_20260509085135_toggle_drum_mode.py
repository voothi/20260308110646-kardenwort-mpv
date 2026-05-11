"""
Feature ZID: 20260509085135
Test Creation ZID: 20260509085637
Feature: Toggle Drum Mode
"""

# Spec: openspec/changes/20260502165659-implement-spec-driven-testing/specs/automated-acceptance-testing/spec.md
# Scenario: Simulating a keypress
import time
from tests.ipc.mpv_ipc import query_kardenwort_state


def test_toggle_drum_mode(mpv):
    mpv.ipc.command(['script-binding', 'kardenwort/toggle-drum-mode'])
    time.sleep(0.1)  # one tick (~50 ms) for state to propagate
    state = query_kardenwort_state(mpv.ipc)
    assert state['drum_mode'] == 'ON'




