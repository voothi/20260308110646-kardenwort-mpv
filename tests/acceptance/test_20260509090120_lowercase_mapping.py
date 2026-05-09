"""
Feature ZID: 20260509090120
Test Creation ZID: 20260509091431
Feature: Lowercase Mapping
Acceptance tests for Russian Keyboard Layout Expansion (20260509090120).
Requirement: expand_ru_keys mapping logic.
"""

import json
import time
import pytest
from tests.ipc.mpv_session import MpvSession

class TestRuKeyExpansion:
    """Verifies that English hotkeys are correctly expanded to Russian equivalents."""

    def _query_expansion(self, ipc, keys):
        ipc.command(['script-message-to', 'lls_core', 'lls-test-expand-ru-keys', keys])
        time.sleep(0.2)
        raw = ipc.get_property('user-data/lls/last_export')
        return json.loads(raw) if raw else []

    def test_lowercase_mapping(self, mpv):
        """'a' must expand to ['a', 'ф']."""
        expanded = self._query_expansion(mpv.ipc, "a")
        assert "a" in expanded
        assert "ф" in expanded

    def test_uppercase_mapping(self, mpv):
        """'A' must expand to ['A', 'Ф']."""
        expanded = self._query_expansion(mpv.ipc, "A")
        assert "A" in expanded
        assert "Ф" in expanded

    def test_shift_modifier_mapping(self, mpv):
        """'Shift+a' must expand to ['Shift+a', 'Ф'].
        
        Note: [v1.58.42] Shift+a -> 'Ф' (uppercase Cyrillic, no Shift+ prefix).
        """
        expanded = self._query_expansion(mpv.ipc, "Shift+a")
        assert "Shift+a" in expanded
        assert "Ф" in expanded
        # Ensure 'Shift+ф' is NOT present (as per v1.58.42 fix)
        assert "Shift+ф" not in expanded

    def test_ctrl_modifier_mapping(self, mpv):
        """'Ctrl+a' must expand to ['Ctrl+a', 'Ctrl+ф']."""
        expanded = self._query_expansion(mpv.ipc, "Ctrl+a")
        assert "Ctrl+a" in expanded
        assert "Ctrl+ф" in expanded

    def test_complex_multikey_input(self, mpv):
        """'a,Ctrl+b' must expand correctly for both keys."""
        expanded = self._query_expansion(mpv.ipc, "a,Ctrl+b")
        assert "a" in expanded
        assert "ф" in expanded
        assert "Ctrl+b" in expanded
        assert "Ctrl+и" in expanded

    def test_punctuation_mapping(self, mpv):
        """'[' must expand to ['[', 'х']."""
        expanded = self._query_expansion(mpv.ipc, "[")
        assert "[" in expanded
        assert "х" in expanded

    def test_no_mapping_for_non_en(self, mpv):
        """'1' should remain ['1']."""
        expanded = self._query_expansion(mpv.ipc, "1")
        assert expanded == ["1"]
