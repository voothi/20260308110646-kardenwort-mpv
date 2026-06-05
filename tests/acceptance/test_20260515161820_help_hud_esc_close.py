"""
Feature ZID: 20260515161820
Test Creation ZID: 20260515161820
Feature: Help HUD ESC close behavior
Requirement: ESC must close Help HUD when it is open.
"""

import time


class TestHelpHudEscClose:
    """Ensures cmd_dw_esc closes the Help HUD cleanly."""

    def test_help_hud_closes_on_esc(self, mpv):
        ipc = mpv.ipc
        try:
            ipc.command(['set_property', 'user-data/kardenwort/test_help_esc_ok', ''])
            ipc.command(['set_property', 'user-data/kardenwort/test_help_esc_error', ''])
            ipc.command(['set_property', 'user-data/kardenwort/test_help_mode', ''])
        except Exception:
            pass

        ipc.command(['script-message-to', 'kardenwort', 'test-help-close-esc'])
        
        ok = ""
        err = ""
        state = ""
        deadline = time.time() + 5.0
        while time.time() < deadline:
            try:
                ok = ipc.get_property('user-data/kardenwort/test_help_esc_ok')
                if ok != "":
                    err = ipc.get_property('user-data/kardenwort/test_help_esc_error')
                    state = ipc.get_property('user-data/kardenwort/test_help_mode')
                    break
            except Exception:
                pass
            time.sleep(0.1)
        else:
            ok = ipc.get_property('user-data/kardenwort/test_help_esc_ok')
            err = ipc.get_property('user-data/kardenwort/test_help_esc_error')
            state = ipc.get_property('user-data/kardenwort/test_help_mode')

        assert ok == "1", f"ESC close path failed: {err}"
        assert state == "OFF"
