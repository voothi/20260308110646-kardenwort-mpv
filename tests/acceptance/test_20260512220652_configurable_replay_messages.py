"""
Feature ZID: 20260512215725
Test Creation ZID: 20260512220652
Feature: Configurable Replay Messages
"""

import os
import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state
from tests.ipc.mpv_session import MpvSession

def _robust_get_property(ipc, name, expected=None, attempts=20):
    for _ in range(attempts):
        try:
            val = ipc.get_property(name)
            if expected is None or expected in val:
                return val
        except: pass
        time.sleep(0.5)
    return ipc.get_property(name)

@pytest.mark.acceptance
def test_replay_message_formatting_off(mpv):
    """Verify replay message formatting in Autopause OFF mode."""
    ipc = mpv.ipc
    
    # 1. Set preconditions
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "autopause_default", "no"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "replay_count", "1"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "replay_ms", "2000"])
    ipc.command(["script-message-to", "kardenwort", "autopause-set", "OFF"])
    time.sleep(1.0)
    
    # 2. Trigger Replay via test-replay message
    ipc.command(["script-message-to", "kardenwort", "test-replay"])
    
    # 3. Verify OSD via diagnostic property
    osd_text = _robust_get_property(ipc, "user-data/kardenwort/last_osd", "Replay")
    assert "Replay: 2000ms" in osd_text, f"OSD message mismatch. Got: {osd_text}"

@pytest.mark.acceptance
def test_replay_message_formatting_off_multi(mpv):
    """Verify replay message formatting with multiple iterations in Autopause OFF."""
    ipc = mpv.ipc
    
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "replay_count", "3"])
    ipc.command(["script-message-to", "kardenwort", "autopause-set", "OFF"])
    time.sleep(1.0)
    
    ipc.command(["script-message-to", "kardenwort", "test-replay"])
    
    osd_text = _robust_get_property(ipc, "user-data/kardenwort/last_osd", "x3")
    assert "Replay: 2000ms x3" in osd_text, f"OSD message mismatch for multi-iteration. Got: {osd_text}"

@pytest.mark.acceptance
def test_replay_message_formatting_on(mpv):
    """Verify replay message formatting in Autopause ON mode."""
    ipc = mpv.ipc
    
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "replay_count", "1"])
    ipc.command(["script-message-to", "kardenwort", "autopause-set", "ON"])
    time.sleep(1.0)
    
    ipc.command(["script-message-to", "kardenwort", "test-replay"])
    
    osd_text = _robust_get_property(ipc, "user-data/kardenwort/last_osd", "Replaying")
    assert "Replaying segment: 2000ms" in osd_text, f"OSD message mismatch for Autopause ON. Got: {osd_text}"

@pytest.mark.acceptance
def test_replay_message_custom_template(mpv):
    """Verify that custom templates from mpv.conf (via script-opts) are honored."""
    ipc = mpv.ipc
    
    # Simulate mpv.conf override using test-set-option
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "replay_msg_format", "FLASHBACK: %mms (count=%c)"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "replay_count", "1"])
    ipc.command(["script-message-to", "kardenwort", "autopause-set", "OFF"])
    time.sleep(1.0)
    
    ipc.command(["script-message-to", "kardenwort", "test-replay"])
    
    osd_text = _robust_get_property(ipc, "user-data/kardenwort/last_osd", "FLASHBACK")
    assert "FLASHBACK: 2000ms (count=1)" in osd_text, f"Custom template failed. Got: {osd_text}"

@pytest.mark.acceptance
def test_replay_message_seconds(mpv):
    """Verify that %s placeholder correctly outputs seconds."""
    ipc = mpv.ipc
    
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "replay_ms", "2500"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "replay_msg_format", "Replay: %s sec"])
    ipc.command(["script-message-to", "kardenwort", "autopause-set", "OFF"])
    time.sleep(1.0)
    
    ipc.command(["script-message-to", "kardenwort", "test-replay"])
    
    osd_text = _robust_get_property(ipc, "user-data/kardenwort/last_osd", "sec")
    assert "Replay: 2.5 sec" in osd_text, f"Seconds placeholder failed. Got: {osd_text}"
