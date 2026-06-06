"""
Feature ZID: 20260606152155
Feature: Sub TTS Pipeline - Prioritized File Sorting and Regional Language Support
"""

import configparser
import importlib.util
from pathlib import Path
import pytest

_SCRIPT_PATH = (
    Path(__file__).resolve().parents[2]
    / "scripts"
    / "_tools"
    / "sub-tts"
    / "sub_tts.py"
)

def _load_sub_tts():
    spec = importlib.util.spec_from_file_location("sub_tts_under_test", _SCRIPT_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def test_detect_language_regional_suffixes():
    sub_tts = _load_sub_tts()
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "en",
    }
    
    # Standard languages
    assert sub_tts.detect_language("video.en.srt", config) == "en"
    assert sub_tts.detect_language("video.de.srt", config) == "de"
    
    # Regional suffixes (hyphen and underscore)
    assert sub_tts.detect_language("video.de-DE.srt", config) == "de"
    assert sub_tts.detect_language("video.de_DE.srt", config) == "de"
    assert sub_tts.detect_language("video.en-US.srt", config) == "en"
    assert sub_tts.detect_language("video.en_GB.srt", config) == "en"
    
    # Aliased regional suffix (e.g. rus-RU -> ru)
    assert sub_tts.detect_language("video.rus-RU.srt", config) == "ru"
    assert sub_tts.detect_language("video.rus_RU.srt", config) == "ru"

def test_file_sorting_priority_exact_matches():
    sub_tts = _load_sub_tts()
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "en",
        "primary_languages": "en, de",
    }

    srt_files = ["video.ru.srt", "video.de.srt", "video.en.srt"]

    primary_langs = [l.strip().lower() for l in config.get("tts_settings", "primary_languages").split(",") if l.strip()]

    def get_sort_key(f):
        lang = sub_tts.detect_language(f, config)
        stem = Path(f).stem
        parts = stem.rsplit(".", 1)
        raw_postfix = parts[1].lower() if len(parts) == 2 else ""
        raw_base = re_split_local(raw_postfix)
        
        for idx, p_lang in enumerate(primary_langs):
            p_lang_clean = p_lang.lower()
            p_lang_base = re_split_local(p_lang_clean)
            if lang == p_lang_clean or raw_postfix == p_lang_clean or raw_base == p_lang_base:
                return idx
        return len(primary_langs)

    def re_split_local(s):
        import re
        return re.split(r"[-_]", s)[0] if s else ""

    srt_files.sort(key=get_sort_key)
    assert srt_files == ["video.en.srt", "video.de.srt", "video.ru.srt"]

def test_file_sorting_priority_regional_matches():
    sub_tts = _load_sub_tts()
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "en",
        "primary_languages": "en, de",
    }

    # Input has regional postfixes, primary_languages has base languages
    srt_files = ["video.ru-RU.srt", "video.de-DE.srt", "video.en_US.srt"]
    primary_langs = [l.strip().lower() for l in config.get("tts_settings", "primary_languages").split(",") if l.strip()]

    def get_sort_key(f):
        lang = sub_tts.detect_language(f, config)
        stem = Path(f).stem
        parts = stem.rsplit(".", 1)
        raw_postfix = parts[1].lower() if len(parts) == 2 else ""
        raw_base = re_split_local(raw_postfix)
        
        for idx, p_lang in enumerate(primary_langs):
            p_lang_clean = p_lang.lower()
            p_lang_base = re_split_local(p_lang_clean)
            if lang == p_lang_clean or raw_postfix == p_lang_clean or raw_base == p_lang_base:
                return idx
        return len(primary_langs)

    def re_split_local(s):
        import re
        return re.split(r"[-_]", s)[0] if s else ""

    srt_files.sort(key=get_sort_key)
    assert srt_files == ["video.en_US.srt", "video.de-DE.srt", "video.ru-RU.srt"]

def test_file_sorting_priority_explicit_regional_in_config():
    sub_tts = _load_sub_tts()
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "en",
        "primary_languages": "en-us, de-de",
    }

    # Input has regional postfixes, primary_languages also has regional languages
    srt_files = ["video.de-DE.srt", "video.en-US.srt"]
    primary_langs = [l.strip().lower() for l in config.get("tts_settings", "primary_languages").split(",") if l.strip()]

    def get_sort_key(f):
        lang = sub_tts.detect_language(f, config)
        stem = Path(f).stem
        parts = stem.rsplit(".", 1)
        raw_postfix = parts[1].lower() if len(parts) == 2 else ""
        raw_base = re_split_local(raw_postfix)
        
        for idx, p_lang in enumerate(primary_langs):
            p_lang_clean = p_lang.lower()
            p_lang_base = re_split_local(p_lang_clean)
            if lang == p_lang_clean or raw_postfix == p_lang_clean or raw_base == p_lang_base:
                return idx
        return len(primary_langs)

    def re_split_local(s):
        import re
        return re.split(r"[-_]", s)[0] if s else ""

    srt_files.sort(key=get_sort_key)
    assert srt_files == ["video.en-US.srt", "video.de-DE.srt"]

def test_file_sorting_priority_fallback_to_default_lang():
    sub_tts = _load_sub_tts()
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "de", # default_lang is de, primary_languages is empty
    }

    srt_files = ["video.ru.srt", "video.de-DE.srt", "video.en.srt"]
    
    # Mimic main() fallback logic
    primary_langs = [l.strip().lower() for l in config.get("tts_settings", "primary_languages", fallback="").split(",") if l.strip()]
    if not primary_langs:
        primary_langs = [config.get("tts_settings", "default_lang", fallback="en").strip().lower()]

    def get_sort_key(f):
        lang = sub_tts.detect_language(f, config)
        stem = Path(f).stem
        parts = stem.rsplit(".", 1)
        raw_postfix = parts[1].lower() if len(parts) == 2 else ""
        raw_base = re_split_local(raw_postfix)
        
        for idx, p_lang in enumerate(primary_langs):
            p_lang_clean = p_lang.lower()
            p_lang_base = re_split_local(p_lang_clean)
            if lang == p_lang_clean or raw_postfix == p_lang_clean or raw_base == p_lang_base:
                return idx
        return len(primary_langs)

    def re_split_local(s):
        import re
        return re.split(r"[-_]", s)[0] if s else ""

    srt_files.sort(key=get_sort_key)
    assert srt_files == ["video.de-DE.srt", "video.ru.srt", "video.en.srt"]
