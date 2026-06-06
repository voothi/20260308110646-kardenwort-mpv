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


def test_skip_primary_output_in_process_srt(monkeypatch, tmp_path):
    sub_tts = _load_sub_tts()
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "en",
        "skip_primary_output": "true",
        "timeline_source": "primary_subtitle",
        "shift_subtitles_on_overflow": "false",
    }
    
    srt_file = tmp_path / "test.en.srt"
    srt_file.write_text("1\n00:00:01,000 --> 00:00:02,000\na", encoding="utf-8")
    
    # Create the dummy output file so skip is NOT overridden/forced
    output_mp4 = tmp_path / "test.mp4"
    output_mp4.write_text("dummy", encoding="utf-8")
    
    # Mocking dependencies of process_srt to prevent running actual PIPER / FFmpeg logic
    monkeypatch.setattr(sub_tts, "parse_srt", lambda *args: [{"index": 1, "start_ms": 1000, "end_ms": 2000, "text": "a"}])
    
    synthesis_called = False
    def mock_synthesize(*args):
        nonlocal synthesis_called
        synthesis_called = True
        return [{"ok": True, "wav_path": Path("cue_1.wav"), "cue": {"index": 1, "start_ms": 1000, "end_ms": 2000, "text": "a"}}]
    monkeypatch.setattr(sub_tts, "synthesize_all_cues", mock_synthesize)
    
    # If the process skips output, it should NOT run assemble_audio
    assemble_called = False
    def mock_assemble(*args):
        nonlocal assemble_called
        assemble_called = True
        return Path("assembled.wav")
    monkeypatch.setattr(sub_tts, "assemble_audio", mock_assemble)
    
    # Mock trim/speed functions to return their inputs to avoid failures
    monkeypatch.setattr(sub_tts, "trim_cues_only", lambda r, *args: r)
    monkeypatch.setattr(sub_tts, "adjust_speed_for_cues", lambda r, *args: r)
    
    piper_cfg = configparser.ConfigParser()
    piper_cfg["tts_settings"] = {"supported_languages": "en"}
    piper_cfg["voice_en"] = {"model": "en_voice.onnx"}

    # Run process_srt as a primary track (canonical_shift_plan is None)
    ok, shift_plan = sub_tts.process_srt(
        srt_file,
        config=config,
        piper_config=piper_cfg,
        piper_root=Path(""),
        ffmpeg_path="ffmpeg",
        skip_primary_output_override=True,
    )
    
    assert ok is True
    # Let's verify we skipped synthesis and audio assembly
    assert not synthesis_called
    assert not assemble_called


def test_sidecar_json_loading_and_writing(monkeypatch, tmp_path):
    sub_tts = _load_sub_tts()
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "en",
        "skip_primary_output": "true",
        "timeline_source": "primary_audio",
    }
    
    # 1. Test Writing:
    # First, run process_srt where sidecar does NOT exist. It should synthesize cues and write the sidecar JSON.
    srt_file = tmp_path / "test.en.srt"
    srt_file.write_text("1\n00:00:01,000 --> 00:00:02,000\nHello", encoding="utf-8")
    
    # Create the dummy output file so skip is NOT overridden/forced
    output_mp4 = tmp_path / "test.mp4"
    output_mp4.write_text("dummy", encoding="utf-8")
    
    synthesis_called = False
    def mock_synthesize(*args):
        nonlocal synthesis_called
        synthesis_called = True
        return [{"ok": True, "wav_path": Path("cue_1.wav"), "cue": {"index": 1, "start_ms": 1000, "end_ms": 2000, "text": "Hello"}}]
    monkeypatch.setattr(sub_tts, "synthesize_all_cues", mock_synthesize)
    
    # Mock trim/synthesis/timeline calculations
    monkeypatch.setattr(sub_tts, "trim_cues_only", lambda r, *args: r)
    monkeypatch.setattr(sub_tts, "plan_recording_timeline", lambda *args: sub_tts.ShiftPlan([0]))
    monkeypatch.setattr(sub_tts, "apply_shift_plan", lambda r, *args: r)
    
    piper_cfg = configparser.ConfigParser()
    piper_cfg["tts_settings"] = {"supported_languages": "en"}
    piper_cfg["voice_en"] = {"model": "en_voice.onnx"}
    
    # Run process_srt. It should write sidecar JSON on exit.
    ok, shift_plan = sub_tts.process_srt(
        srt_file,
        config=config,
        piper_config=piper_cfg,
        piper_root=Path(""),
        ffmpeg_path="ffmpeg",
        skip_primary_output_override=True,
    )
    
    assert ok is True
    assert synthesis_called is True
    
    sidecar_file = tmp_path / "test.en.srt.shift_plan.json"
    assert sidecar_file.exists()
    
    # 2. Test Loading:
    # Reset flag and run again. It should load the sidecar JSON and NOT call synthesis.
    synthesis_called = False
    
    ok2, shift_plan2 = sub_tts.process_srt(
        srt_file,
        config=config,
        piper_config=piper_cfg,
        piper_root=Path(""),
        ffmpeg_path="ffmpeg",
        skip_primary_output_override=True,
    )
    
    assert ok2 is True
    assert synthesis_called is False  # Verification that synthesis was bypassed!
    assert shift_plan2 == [0]


def test_auto_discovery_of_primary_files(tmp_path):
    sub_tts = _load_sub_tts()
    
    # Create test directory and files
    primary_file = tmp_path / "video.en.srt"
    secondary_file = tmp_path / "video.ru.srt"
    unrelated_file = tmp_path / "other.en.srt"
    
    primary_file.write_text("1\n00:00:01,000 --> 00:00:02,000\nHello", encoding="utf-8")
    secondary_file.write_text("1\n00:00:01,000 --> 00:00:02,000\nПривет", encoding="utf-8")
    unrelated_file.write_text("1\n00:00:01,000 --> 00:00:02,000\nOther", encoding="utf-8")

    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "en",
        "primary_languages": "en, de",
        "auto_discover_primary": "true",
    }
    
    # Simulate the main() auto-discovery logic
    srt_files = [str(secondary_file)]
    
    auto_discovered_srt_files = set()
    auto_discover = True
    primary_langs = ["en", "de"]

    if auto_discover:
        discovered_candidates = []
        for f in list(srt_files):
            lang = sub_tts.detect_language(f, config)
            try:
                f_priority = primary_langs.index(lang)
            except ValueError:
                f_priority = len(primary_langs)

            if f_priority > 0:
                parent_dir = Path(f).resolve().parent
                stem = Path(f).stem
                clean_stem = sub_tts.strip_lang_postfix(stem, lang)
                
                try:
                    for p in parent_dir.glob("*.srt"):
                        if p.resolve() == Path(f).resolve():
                            continue
                        p_lang = sub_tts.detect_language(p, config)
                        p_stem = p.stem
                        p_clean_stem = sub_tts.strip_lang_postfix(p_stem, p_lang)
                        if p_clean_stem.lower() == clean_stem.lower():
                            try:
                                p_priority = primary_langs.index(p_lang)
                            except ValueError:
                                p_priority = len(primary_langs)
                            if p_priority < f_priority:
                                discovered_candidates.append((p, p_priority))
                except Exception:
                    pass

        by_stem = {}
        for p, priority in discovered_candidates:
            p_lang = sub_tts.detect_language(p, config)
            clean_stem = sub_tts.strip_lang_postfix(p.stem, p_lang).lower()
            if clean_stem not in by_stem or priority < by_stem[clean_stem][1]:
                by_stem[clean_stem] = (p, priority)

        for p, priority in by_stem.values():
            resolved_p = str(p.resolve())
            resolved_srt_files = [str(Path(sf).resolve()) for sf in srt_files]
            if resolved_p not in resolved_srt_files:
                srt_files.append(str(p))
                auto_discovered_srt_files.add(str(p.resolve()))

    # Verify that the primary file was auto-discovered, but the unrelated file was not
    assert len(srt_files) == 2
    assert str(primary_file.resolve()) in [str(Path(sf).resolve()) for sf in srt_files]
    assert str(unrelated_file.resolve()) not in [str(Path(sf).resolve()) for sf in srt_files]
    assert str(primary_file.resolve()) in auto_discovered_srt_files


def test_skip_primary_output_conditional_on_existence(monkeypatch, tmp_path):
    sub_tts = _load_sub_tts()
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "en",
        "skip_primary_output": "true",
        "timeline_source": "primary_subtitle",
    }
    
    srt_file = tmp_path / "video.en.srt"
    srt_file.write_text("1\n00:00:01,000 --> 00:00:02,000\nHello", encoding="utf-8")
    
    # Mocking process_srt logic dependencies
    monkeypatch.setattr(sub_tts, "parse_srt", lambda *args: [{"index": 1, "start_ms": 1000, "end_ms": 2000, "text": "Hello"}])
    monkeypatch.setattr(
        sub_tts,
        "synthesize_all_cues",
        lambda *args: [{"ok": True, "wav_path": Path("cue_1.wav"), "cue": {"index": 1, "start_ms": 1000, "end_ms": 2000, "text": "Hello"}}],
    )
    
    assemble_called = False
    def mock_assemble(*args):
        nonlocal assemble_called
        assemble_called = True
        return Path("assembled.wav")
    monkeypatch.setattr(sub_tts, "assemble_audio", mock_assemble)
    monkeypatch.setattr(sub_tts, "mux_to_mp4", lambda *args: True)
    monkeypatch.setattr(sub_tts, "trim_cues_only", lambda r, *args: r)
    monkeypatch.setattr(sub_tts, "adjust_speed_for_cues", lambda r, *args: r)
    
    piper_cfg = configparser.ConfigParser()
    piper_cfg["tts_settings"] = {"supported_languages": "en"}
    piper_cfg["voice_en"] = {"model": "en_voice.onnx"}

    # Case 1: The primary output file "video.mp4" does NOT exist.
    # It should FORCE generation (so assemble_audio is called).
    ok, shift_plan = sub_tts.process_srt(
        srt_file,
        config=config,
        piper_config=piper_cfg,
        piper_root=Path(""),
        ffmpeg_path="ffmpeg",
        skip_primary_output_override=True,
    )
    
    assert ok is True
    assert assemble_called is True  # Bypassed skip because file is missing!
    
    # Case 2: The primary output file "video.mp4" DOES exist.
    # It should skip output generation (so assemble_audio is NOT called).
    output_mp4 = tmp_path / "video.mp4"
    output_mp4.write_text("dummy mp4 content", encoding="utf-8")
    
    assemble_called = False
    ok2, shift_plan2 = sub_tts.process_srt(
        srt_file,
        config=config,
        piper_config=piper_cfg,
        piper_root=Path(""),
        ffmpeg_path="ffmpeg",
        skip_primary_output_override=True,
    )
    
    assert ok2 is True
    assert assemble_called is False  # Respects skip because file exists!


def test_fallback_to_subtitle_if_output_exists(monkeypatch, tmp_path):
    sub_tts = _load_sub_tts()
    import sys
    
    # 1. Create a dummy primary SRT file
    primary_srt = tmp_path / "video.en.srt"
    primary_srt.write_text("1\n00:00:01,000 --> 00:00:02,000\nHello", encoding="utf-8")
    
    # 2. Create the target MP4 file
    primary_mp4 = tmp_path / "video.mp4"
    primary_mp4.write_text("dummy mp4", encoding="utf-8")
    
    # 3. Create a config with timeline_source = primary_audio and fallback_to_subtitle_if_output_exists = true
    config = configparser.ConfigParser()
    config["paths"] = {
        "piper_tts_root": str(tmp_path),
        "ffmpeg_executable": "ffmpeg",
    }
    config["tts_settings"] = {
        "default_lang": "en",
        "primary_languages": "en",
        "timeline_source": "primary_audio",
        "fallback_to_subtitle_if_output_exists": "true",
        "keep_lang_postfix": "false",
    }
    
    # Mock parse_args to return srt_files=[str(primary_srt)]
    class Args:
        srt_files = [str(primary_srt)]
        lang = None
        output_dir = None
        ffmpeg_path = None
        keep_lang_postfix = None
        timeline_source = None
        shift_subtitles_on_overflow = None
        skip_primary_output = False
        auto_discover_primary = False
        sendto = False
        pause = False
        fallback_to_subtitle_if_output_exists = None
    
    monkeypatch.setattr(sub_tts, "parse_args", lambda: Args())
    monkeypatch.setattr(sub_tts, "load_config", lambda: config)
    monkeypatch.setattr(sub_tts, "resolve_ffmpeg", lambda *args, **kw: "ffmpeg")
    
    # Mock get_piper_config to avoid loading real configs
    piper_cfg = configparser.ConfigParser()
    piper_cfg["tts_settings"] = {"supported_languages": "en"}
    piper_cfg["voice_en"] = {"model": "en_voice.onnx"}
    monkeypatch.setattr(sub_tts, "get_piper_config", lambda *args: (piper_cfg, tmp_path))
    
    # Track the timeline_source passed to process_srt
    called_timeline_sources = []
    def mock_process_srt(srt_path, **kwargs):
        called_timeline_sources.append(kwargs.get("timeline_source_override"))
        return True, sub_tts.ShiftPlan([0])
    monkeypatch.setattr(sub_tts, "process_srt", mock_process_srt)
    
    # Mock sys.exit to avoid exiting the test run
    monkeypatch.setattr(sys, "exit", lambda code: None)
    
    # Run main()
    sub_tts.main()
    
    # Verify that process_srt was called with 'primary_subtitle' (due to fallback!)
    assert len(called_timeline_sources) == 1
    assert called_timeline_sources[0] == "primary_subtitle"
