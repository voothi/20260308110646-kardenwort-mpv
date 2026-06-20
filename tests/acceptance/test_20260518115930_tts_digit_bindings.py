"""
Feature ZID: 20260518115930
Feature: TTS digit bindings
"""

import re
from pathlib import Path


def _read(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


class TestTtsDigitBindings:
    """Regression guards for one-press TTS digit integration."""

    def test_main_lua_has_tts_trigger_options_and_bindings(self):
        src = _read("scripts/kardenwort/main.lua") + "\n" + _read("scripts/kardenwort/config.lua")
        help_src = _read("scripts/kardenwort/help_hud.lua")
        required_in_main = [
            'tts_trigger_enabled = "no"',
            'tts_hotkey_2 = "Ctrl+Alt+Shift+2"',
            'tts_hotkey_3 = "Ctrl+Alt+Shift+3"',
            'tts_hotkey_4 = "Ctrl+Alt+Shift+4"',
            'tts_hotkey_5 = "Ctrl+Alt+Shift+5"',
            'key_tts_2 = ""',
            'key_tts_3 = ""',
            'key_tts_4 = ""',
            'key_tts_5 = ""',
            'cmd_copy_sub("tts_2")',
            'cmd_copy_sub("tts_3")',
            'cmd_copy_sub("tts_4")',
            'cmd_copy_sub("tts_5")',
            'mode:match("^tts_[1-8]$")',
            'Options["tts_hotkey_" .. mode:match("([1-8])$")]',
        ]
        missing = [item for item in required_in_main if item not in src]
        for idx in (2, 3, 4, 5):
            pat = rf'cmd\s*=\s*"kardenwort/copy-subtitle-tts-{idx}"\s*,\s*fallback_keys\s*=\s*function\(\)\s*(?:return\s+)?Options\.key_tts_{idx}\s+end'
            if not re.search(pat, help_src):
                missing.append(f'tts-{idx} fallback_keys entry')
        assert not missing, f"TTS integration markers missing: {missing}"

    def test_mpv_conf_declares_tts_keys_and_hotkeys(self):
        conf = _read("mpv.conf")
        required = [
            "script-opts-append=kardenwort-tts_trigger_enabled=yes",
            "script-opts-append=kardenwort-tts_hotkey_2=Ctrl+Alt+Shift+2",
            "script-opts-append=kardenwort-tts_hotkey_3=Ctrl+Alt+Shift+3",
            "script-opts-append=kardenwort-tts_hotkey_4=Ctrl+Alt+Shift+4",
            "script-opts-append=kardenwort-tts_hotkey_5=Ctrl+Alt+Shift+5",
            "script-opts-append=kardenwort-key_tts_2=2",
            "script-opts-append=kardenwort-key_tts_3=3",
            "script-opts-append=kardenwort-key_tts_4=4",
            "script-opts-append=kardenwort-key_tts_5=5",
        ]
        missing = [item for item in required if item not in conf]
        assert not missing, f"TTS config markers missing in mpv.conf: {missing}"

    def test_input_conf_does_not_hard_ignore_active_tts_digits(self):
        conf = _read("input.conf")
        mpv_conf = _read("mpv.conf")
        active_tts_digits = re.findall(
            r"^\s*script-opts-append=kardenwort-key_tts_([1-8])=([1-8])\s*$",
            mpv_conf,
            re.MULTILINE,
        )
        for _, digit in active_tts_digits:
            pattern = re.compile(rf"^\s*{digit}\s+ignore\b", re.MULTILINE)
            assert not pattern.search(conf), (
                f"input.conf still hard-ignores '{digit}', which blocks kardenwort-key_tts_{digit}"
            )
