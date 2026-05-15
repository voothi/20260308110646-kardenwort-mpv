"""
Feature ZID: 20260515131351
Test Creation ZID: 20260515131351
Feature: Help HUD runtime safety
Requirement: F1/help toggle must not crash and must flip HELP_MODE.
"""

import time


class TestHelpHudRuntime:
    """Ensures Help HUD toggles ON/OFF through runtime message path."""

    def _toggle_help_and_get_state(self, ipc):
        ipc.command(['script-message-to', 'kardenwort', 'test-help-toggle'])
        time.sleep(0.2)
        ok = ipc.get_property('user-data/kardenwort/test_help_toggle_ok')
        err = ipc.get_property('user-data/kardenwort/test_help_toggle_error')
        state = ipc.get_property('user-data/kardenwort/test_help_mode')
        return ok, err, state

    def test_help_toggle_roundtrip(self, mpv):
        """Toggle Help HUD twice and verify ON then OFF states."""
        ok1, err1, state1 = self._toggle_help_and_get_state(mpv.ipc)
        assert ok1 == "1", f"first toggle failed: {err1}"
        assert state1 == "ON"

        ok2, err2, state2 = self._toggle_help_and_get_state(mpv.ipc)
        assert ok2 == "1", f"second toggle failed: {err2}"
        assert state2 == "OFF"
