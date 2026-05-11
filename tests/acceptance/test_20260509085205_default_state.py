"""
Feature ZID: 20260509085205
Test Creation ZID: 20260509085637
Feature: Default State
"""

# Spec: openspec/changes/20260502165659-implement-spec-driven-testing/specs/automated-acceptance-testing/spec.md
# Scenario: Querying playback state
import json
from tests.ipc.mpv_ipc import query_kardenwort_state


def test_default_state(mpv):
    state = query_kardenwort_state(mpv.ipc)
    assert state['playback_state'] in ('SINGLE_SRT', 'NO_SUBS')
    assert state['drum_mode'] == 'OFF'
    assert state['drum_window'] == 'OFF'
    assert state['dw_selection_count'] == 0




