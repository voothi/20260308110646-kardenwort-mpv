"""
Feature ZID: 20260515112708
Test Creation ZID: 20260515112708
Feature: Dynamic Help HUD Normalization
Acceptance tests for professional shortcut notation and UTF-8 Cyrillic mapping.
Requirement: normalize_key_display logic.
"""

import time
import pytest

class TestHelpNormalization:
    """Verifies that raw key names are correctly normalized for the Help HUD."""

    def _get_normalized(self, ipc, key):
        ipc.command(['script-message-to', 'kardenwort', 'test-normalize-key-display', key])
        time.sleep(0.2)
        return ipc.get_property('user-data/kardenwort/test_normalization')

    def test_lowercase_latin_passthrough(self, mpv):
        """Lowercase Latin keys should remain unchanged."""
        assert self._get_normalized(mpv.ipc, "a") == "a"
        assert self._get_normalized(mpv.ipc, "z") == "z"

    def test_uppercase_latin_expansion(self, mpv):
        """Uppercase Latin keys must expand to Shift+lowercase."""
        assert self._get_normalized(mpv.ipc, "A") == "Shift+a"
        assert self._get_normalized(mpv.ipc, "S") == "Shift+s"

    def test_ctrl_combination_expansion(self, mpv):
        """Ctrl combinations with uppercase must expand correctly."""
        assert self._get_normalized(mpv.ipc, "Ctrl+A") == "Ctrl+Shift+a"
        assert self._get_normalized(mpv.ipc, "Ctrl+S") == "Ctrl+Shift+s"
        # Already lowercase should NOT expand
        assert self._get_normalized(mpv.ipc, "Ctrl+a") == "Ctrl+a"

    def test_cyrillic_lowercase_passthrough(self, mpv):
        """Lowercase Cyrillic keys should remain unchanged."""
        assert self._get_normalized(mpv.ipc, "ф") == "ф"
        assert self._get_normalized(mpv.ipc, "я") == "я"

    def test_cyrillic_uppercase_expansion(self, mpv):
        """Uppercase Cyrillic keys must expand to Shift+lowercase."""
        assert self._get_normalized(mpv.ipc, "Ф") == "Shift+ф"
        assert self._get_normalized(mpv.ipc, "Я") == "Shift+я"
        assert self._get_normalized(mpv.ipc, "Ё") == "Shift+ё"

    def test_cyrillic_ctrl_combination_expansion(self, mpv):
        """Ctrl combinations with uppercase Cyrillic must expand correctly."""
        assert self._get_normalized(mpv.ipc, "Ctrl+Ф") == "Ctrl+Shift+ф"
        assert self._get_normalized(mpv.ipc, "Ctrl+Я") == "Ctrl+Shift+я"

    def test_redundant_shift_cleanup(self, mpv):
        """Shift+Uppercase should be normalized to Shift+lowercase."""
        assert self._get_normalized(mpv.ipc, "Shift+S") == "Shift+s"
        assert self._get_normalized(mpv.ipc, "Shift+Ф") == "Shift+ф"

    def test_complex_notation_reliability(self, mpv):
        """Ensure multi-modifier combinations are handled."""
        assert self._get_normalized(mpv.ipc, "Ctrl+Alt+S") == "Ctrl+Alt+Shift+s"
        assert self._get_normalized(mpv.ipc, "Ctrl+Alt+Ф") == "Ctrl+Alt+Shift+ф"
