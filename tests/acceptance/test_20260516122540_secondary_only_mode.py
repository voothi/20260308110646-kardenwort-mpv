"""
Feature ZID: 20260516121530
Test Creation ZID: 20260516122540
Feature: Secondary Only Mode
"""

import time
from tests.ipc.mpv_session import MpvSession
from tests.ipc.mpv_ipc import query_kardenwort_state

def test_toggle_secondary_only_mode_functional(mpv_dual):
    """
    Verify that toggle-secondary-only correctly sets the SEC_ONLY_MODE state.
    """
    # 1. Initial State: Both visible, SEC_ONLY_MODE=OFF
    state = query_kardenwort_state(mpv_dual.ipc)
    assert state['sec_only_mode'] is False
    assert state['native_sub_vis'] is True
    assert state['native_sec_sub_vis'] is True
    sid_before = int(mpv_dual.ipc.get_property('sid') or 0)
    
    # 2. Toggle ON
    mpv_dual.ipc.command(['script-binding', 'kardenwort/toggle-secondary-only'])
    time.sleep(0.1)
    state = query_kardenwort_state(mpv_dual.ipc)
    assert state['sec_only_mode'] is True
    # Contract: mode ON forces both visibility flags true and selects a secondary track.
    assert state['native_sub_vis'] is True
    assert state['native_sec_sub_vis'] is True
    sec_sid_after_on = int(mpv_dual.ipc.get_property('secondary-sid') or 0)
    assert sec_sid_after_on > 0
    assert sec_sid_after_on != int(mpv_dual.ipc.get_property('sid') or 0)
    
    # 3. Toggle OFF
    mpv_dual.ipc.command(['script-binding', 'kardenwort/toggle-secondary-only'])
    time.sleep(0.1)
    state = query_kardenwort_state(mpv_dual.ipc)
    assert state['sec_only_mode'] is False
    # Contract: mode OFF returns to normal master-on state without corrupting track selection.
    assert state['native_sub_vis'] is True
    assert state['native_sec_sub_vis'] is True
    assert int(mpv_dual.ipc.get_property('sid') or 0) == sid_before
    assert int(mpv_dual.ipc.get_property('secondary-sid') or 0) == sec_sid_after_on

def test_toggle_secondary_only_requires_secondary_track():
    """
    Verify that toggle-secondary-only is ignored if no secondary track is available.
    """
    # Use a custom session with sub-auto=no to ensure only one track exists
    session = MpvSession(
        video='tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.mp4',
        subtitle='tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.en.srt',
        extra_args=['--pause', '--sub-auto=no'],
    )
    session.start()
    try:
        # Ensure a primary track is selected
        session.ipc.command(['set_property', 'sid', 1])
        time.sleep(0.1)
        
        state = query_kardenwort_state(session.ipc)
        assert state['sec_only_mode'] is False
        
        session.ipc.command(['script-binding', 'kardenwort/toggle-secondary-only'])
        time.sleep(0.1)
        state = query_kardenwort_state(session.ipc)
        
        # Should remain False because only one track exists
        assert state['sec_only_mode'] is False
    finally:
        session.stop()


def test_shift_c_blocked_while_secondary_sub_only_on(mpv_dual):
    """
    While Secondary Sub Only mode is ON, Shift+C (cycle secondary subtitle track)
    must be blocked to avoid contradictory "Secondary Sub: OFF" state overlays.
    """
    ipc = mpv_dual.ipc

    ipc.command(['script-binding', 'kardenwort/toggle-secondary-only'])
    time.sleep(0.1)
    state = query_kardenwort_state(ipc)
    assert state['sec_only_mode'] is True

    sid_before = int(ipc.get_property('secondary-sid') or 0)
    assert sid_before > 0

    ipc.command(['script-binding', 'kardenwort/cycle-sec-sid'])
    time.sleep(0.1)
    sid_after = int(ipc.get_property('secondary-sid') or 0)
    assert sid_after == sid_before
