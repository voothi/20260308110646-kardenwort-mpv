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
    assert sub_tts.sort_srt_files(srt_files, config) == ["video.en.srt", "video.de.srt", "video.ru.srt"]

def test_file_sorting_priority_regional_matches():
    sub_tts = _load_sub_tts()
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "en",
        "primary_languages": "en, de",
    }

    # Input has regional postfixes, primary_languages has base languages
    srt_files = ["video.ru-RU.srt", "video.de-DE.srt", "video.en_US.srt"]
    assert sub_tts.sort_srt_files(srt_files, config) == ["video.en_US.srt", "video.de-DE.srt", "video.ru-RU.srt"]

def test_file_sorting_priority_explicit_regional_in_config():
    sub_tts = _load_sub_tts()
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "en",
        "primary_languages": "en-us, de-de",
    }

    # Input has regional postfixes, primary_languages also has regional languages
    srt_files = ["video.de-DE.srt", "video.en-US.srt"]
    assert sub_tts.sort_srt_files(srt_files, config) == ["video.en-US.srt", "video.de-DE.srt"]

def test_file_sorting_priority_fallback_to_default_lang():
    sub_tts = _load_sub_tts()
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "de",  # default_lang is de, primary_languages is empty
    }

    srt_files = ["video.ru.srt", "video.de-DE.srt", "video.en.srt"]
    assert sub_tts.sort_srt_files(srt_files, config) == ["video.de-DE.srt", "video.ru.srt", "video.en.srt"]


def test_reuse_canonical_output_in_process_srt(monkeypatch, tmp_path):
    sub_tts = _load_sub_tts()
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "en",
        "reuse_canonical_output": "true",
        "timeline_source": "primary_subtitle",
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

    # Run process_srt as a canonical track (canonical_shift_plan is None)
    ok, shift_plan = sub_tts.process_srt(
        srt_file,
        config=config,
        piper_config=piper_cfg,
        piper_root=Path(""),
        ffmpeg_path="ffmpeg",
        reuse_canonical_output_override=True,
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
        "reuse_canonical_output": "true",
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
        reuse_canonical_output_override=True,
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
        reuse_canonical_output_override=True,
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
        "auto_discover_canonical": "true",
    }

    # Exercise the real discovery helper rather than a reimplementation.
    srt_files, auto_discovered_srt_files = sub_tts.discover_canonical_files([str(secondary_file)], config)

    # Verify that the canonical file was auto-discovered, but the unrelated file was not
    assert len(srt_files) == 2
    assert str(primary_file.resolve()) in [str(Path(sf).resolve()) for sf in srt_files]
    assert str(unrelated_file.resolve()) not in [str(Path(sf).resolve()) for sf in srt_files]
    assert str(primary_file.resolve()) in auto_discovered_srt_files


def test_reuse_canonical_output_conditional_on_existence(monkeypatch, tmp_path):
    sub_tts = _load_sub_tts()
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "en",
        "reuse_canonical_output": "true",
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
        reuse_canonical_output_override=True,
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
        reuse_canonical_output_override=True,
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
    
    # 3. Create a config using the timeline_source = primary_audio_or_subtitle_fallback mode
    config = configparser.ConfigParser()
    config["paths"] = {
        "piper_tts_root": str(tmp_path),
        "ffmpeg_executable": "ffmpeg",
    }
    config["tts_settings"] = {
        "default_lang": "en",
        "primary_languages": "en",
        "timeline_source": "primary_audio_or_subtitle_fallback",
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
        reuse_canonical_output = False
        auto_discover_canonical = False
        sendto = False
        pause = False
    
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


# ---------------------------------------------------------------------------
# Synced subtitle writing (ZID 20260606163554)
# ---------------------------------------------------------------------------

def test_format_ms_to_srt_time():
    sub_tts = _load_sub_tts()
    assert sub_tts.format_ms_to_srt_time(0) == "00:00:00,000"
    assert sub_tts.format_ms_to_srt_time(2440) == "00:00:02,440"
    assert sub_tts.format_ms_to_srt_time(791416) == "00:13:11,416"
    assert sub_tts.format_ms_to_srt_time(3_661_001) == "01:01:01,001"
    # Negative clamps to zero
    assert sub_tts.format_ms_to_srt_time(-5) == "00:00:00,000"


def test_write_synced_srt_uses_shifted_timings(tmp_path):
    sub_tts = _load_sub_tts()
    # Two cues whose timings have already been drifted/shifted by the pipeline.
    synthesis_results = [
        {"ok": True, "wav_path": None, "cue": {"index": 1, "start_ms": 0, "end_ms": 2440, "text": "Hallo"}},
        {"ok": True, "wav_path": None, "cue": {"index": 2, "start_ms": 2440, "end_ms": 7870, "text": "Welt"}},
        # Empty-text cue must be skipped and not break numbering.
        {"ok": False, "wav_path": None, "cue": {"index": 3, "start_ms": 8000, "end_ms": 9000, "text": ""}},
    ]
    out = tmp_path / "video.ru.srt"
    written = sub_tts.write_synced_srt(synthesis_results, out)

    assert written == 2
    content = out.read_text(encoding="utf-8")
    assert "00:00:00,000 --> 00:00:02,440" in content
    assert "00:00:02,440 --> 00:00:07,870" in content
    assert "Hallo" in content and "Welt" in content
    # Re-numbered sequentially, empty cue dropped
    assert content.strip().splitlines()[0] == "1"
    assert "\n2\n" in content


def test_find_existing_canonical_media_no_postfix(tmp_path):
    sub_tts = _load_sub_tts()
    # Main-language source exists WITHOUT a language postfix.
    (tmp_path / "video.mp4").write_text("dummy", encoding="utf-8")

    # keep_postfix=True would historically look only for 'video.de.mp4' and miss this.
    found = sub_tts.find_existing_canonical_media(tmp_path, "video.de", "de", keep_postfix=True)
    assert found is not None
    assert found.name == "video.mp4"


def test_find_existing_canonical_media_postfixed_and_mp3(tmp_path):
    sub_tts = _load_sub_tts()
    (tmp_path / "video.de.mp4").write_text("dummy", encoding="utf-8")
    found = sub_tts.find_existing_canonical_media(tmp_path, "video.de", "de", keep_postfix=True)
    assert found.name == "video.de.mp4"

    # mp3 container is also recognized
    (tmp_path / "audio.mp3").write_text("dummy", encoding="utf-8")
    found_mp3 = sub_tts.find_existing_canonical_media(tmp_path, "audio.de", "de", keep_postfix=False)
    assert found_mp3.name == "audio.mp3"


def test_find_existing_canonical_media_missing(tmp_path):
    sub_tts = _load_sub_tts()
    assert sub_tts.find_existing_canonical_media(tmp_path, "video.de", "de", keep_postfix=True) is None


def test_process_srt_writes_synced_subtitle(monkeypatch, tmp_path):
    sub_tts = _load_sub_tts()
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "en",
        "reuse_canonical_output": "false",
        "timeline_source": "primary_subtitle",
        "keep_lang_postfix": "true",
    }

    srt_file = tmp_path / "video.ru.srt"
    srt_file.write_text("1\n00:00:01,000 --> 00:00:02,000\nПривет", encoding="utf-8")

    monkeypatch.setattr(sub_tts, "parse_srt", lambda *a: [{"index": 1, "start_ms": 1000, "end_ms": 2000, "text": "Привет"}])
    # Shifted result: the audio timeline moved this cue later than the source SRT.
    monkeypatch.setattr(
        sub_tts, "synthesize_all_cues",
        lambda *a: [{"ok": True, "wav_path": Path("cue_1.wav"), "cue": {"index": 1, "start_ms": 5000, "end_ms": 9000, "text": "Привет"}}],
    )
    monkeypatch.setattr(sub_tts, "adjust_speed_for_cues", lambda r, *a: r)
    monkeypatch.setattr(sub_tts, "assemble_audio", lambda *a: tmp_path / "assembled.wav")
    monkeypatch.setattr(sub_tts, "mux_to_mp4", lambda *a: True)

    piper_cfg = configparser.ConfigParser()
    piper_cfg["tts_settings"] = {"supported_languages": "ru"}
    piper_cfg["voice_ru"] = {"model": "ru_voice.onnx"}

    # Output to a separate directory so the synced sub takes the MP4's exact stem
    # (no collision with the source SRT).
    out_dir = tmp_path / "out"
    out_dir.mkdir()

    ok, _ = sub_tts.process_srt(
        srt_file,
        config=config,
        piper_config=piper_cfg,
        piper_root=Path(""),
        ffmpeg_path="ffmpeg",
        output_dir_override=str(out_dir),
        reuse_canonical_output_override=False,
    )
    assert ok is True

    # Output MP4 is 'video.ru.mp4' (keep_lang_postfix); synced sub sits beside it.
    synced = out_dir / "video.ru.srt"
    content = synced.read_text(encoding="utf-8")
    # Reflects the shifted timeline (5s..9s), NOT the original source (1s..2s).
    assert "00:00:05,000 --> 00:00:09,000" in content
    assert "Привет" in content


def test_process_srt_synced_subtitle_does_not_clobber_source(monkeypatch, tmp_path):
    sub_tts = _load_sub_tts()
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "en",
        "reuse_canonical_output": "false",
        "timeline_source": "primary_subtitle",
        "keep_lang_postfix": "true",
    }

    # Input stem equals the output stem (keep_lang_postfix=true) -> would collide.
    srt_file = tmp_path / "video.ru.srt"
    original_text = "1\n00:00:01,000 --> 00:00:02,000\nПривет"
    srt_file.write_text(original_text, encoding="utf-8")

    monkeypatch.setattr(sub_tts, "parse_srt", lambda *a: [{"index": 1, "start_ms": 1000, "end_ms": 2000, "text": "Привет"}])
    monkeypatch.setattr(
        sub_tts, "synthesize_all_cues",
        lambda *a: [{"ok": True, "wav_path": Path("cue_1.wav"), "cue": {"index": 1, "start_ms": 5000, "end_ms": 9000, "text": "Привет"}}],
    )
    monkeypatch.setattr(sub_tts, "adjust_speed_for_cues", lambda r, *a: r)
    monkeypatch.setattr(sub_tts, "assemble_audio", lambda *a: tmp_path / "assembled.wav")
    monkeypatch.setattr(sub_tts, "mux_to_mp4", lambda *a: True)

    piper_cfg = configparser.ConfigParser()
    piper_cfg["tts_settings"] = {"supported_languages": "ru"}
    piper_cfg["voice_ru"] = {"model": "ru_voice.onnx"}

    # Pin the ZID so we know which subdirectory to look in.
    zid_cache = {"value": "20260606171348"}
    ok, _ = sub_tts.process_srt(
        srt_file,
        config=config,
        piper_config=piper_cfg,
        piper_root=Path(""),
        ffmpeg_path="ffmpeg",
        zid_cache=zid_cache,
        reuse_canonical_output_override=False,
    )
    assert ok is True

    # Source SRT is archived into the ZID subdirectory verbatim.
    archived = tmp_path / "20260606171348" / "video.ru.srt"
    assert archived.exists()
    assert archived.read_text(encoding="utf-8") == original_text
    # Synced subtitle overwrites the root path so players auto-load the correct one.
    assert "00:00:05,000 --> 00:00:09,000" in srt_file.read_text(encoding="utf-8")


def test_cleanup_sidecar_on_success(monkeypatch, tmp_path):
    sub_tts = _load_sub_tts()
    import sys

    srt_file = tmp_path / "video.de.srt"
    srt_file.write_text("1\n00:00:01,000 --> 00:00:02,000\nHallo", encoding="utf-8")

    # Pre-create a sidecar as if a previous run left it behind.
    sidecar = tmp_path / "video.de.srt.shift_plan.json"
    sidecar.write_text('{"shifts":[0],"wav_durations_ms":{},"explicit_ends_ms":{},"explicit_targets_ms":{}}', encoding="utf-8")

    config = configparser.ConfigParser()
    config["paths"] = {"piper_tts_root": str(tmp_path), "ffmpeg_executable": "ffmpeg"}
    config["tts_settings"] = {
        "default_lang": "de",
        "primary_languages": "de",
        "timeline_source": "primary_subtitle",
        "auto_discover_canonical": "false",
        "cleanup_sidecar_on_success": "true",
    }

    class Args:
        srt_files = [str(srt_file)]
        lang = None
        output_dir = None
        ffmpeg_path = None
        keep_lang_postfix = None
        timeline_source = None
        reuse_canonical_output = False
        auto_discover_canonical = False
        sendto = False
        pause = False

    monkeypatch.setattr(sub_tts, "parse_args", lambda: Args())
    monkeypatch.setattr(sub_tts, "load_config", lambda: config)
    monkeypatch.setattr(sub_tts, "resolve_ffmpeg", lambda *a, **k: "ffmpeg")

    piper_cfg = configparser.ConfigParser()
    piper_cfg["tts_settings"] = {"supported_languages": "de"}
    piper_cfg["voice_de"] = {"model": "de_voice.onnx"}
    monkeypatch.setattr(sub_tts, "get_piper_config", lambda *a: (piper_cfg, tmp_path))
    monkeypatch.setattr(sub_tts, "process_srt", lambda srt_path, **kw: (True, sub_tts.ShiftPlan([0])))
    monkeypatch.setattr(sys, "exit", lambda code: None)

    sub_tts.main()

    # Sidecar must be gone after a fully successful run.
    assert not sidecar.exists()


def test_cleanup_sidecar_skipped_on_partial_failure(monkeypatch, tmp_path):
    sub_tts = _load_sub_tts()
    import sys

    srt1 = tmp_path / "video.de.srt"
    srt2 = tmp_path / "video.ru.srt"
    srt1.write_text("1\n00:00:01,000 --> 00:00:02,000\nHallo", encoding="utf-8")
    srt2.write_text("1\n00:00:01,000 --> 00:00:02,000\nПривет", encoding="utf-8")

    sidecar = tmp_path / "video.de.srt.shift_plan.json"
    sidecar.write_text('{"shifts":[0],"wav_durations_ms":{},"explicit_ends_ms":{},"explicit_targets_ms":{}}', encoding="utf-8")

    config = configparser.ConfigParser()
    config["paths"] = {"piper_tts_root": str(tmp_path), "ffmpeg_executable": "ffmpeg"}
    config["tts_settings"] = {
        "default_lang": "de",
        "primary_languages": "de",
        "timeline_source": "primary_subtitle",
        "auto_discover_canonical": "false",
        "cleanup_sidecar_on_success": "true",
    }

    class Args:
        srt_files = [str(srt1), str(srt2)]
        lang = None
        output_dir = None
        ffmpeg_path = None
        keep_lang_postfix = None
        timeline_source = None
        reuse_canonical_output = False
        auto_discover_canonical = False
        sendto = False
        pause = False

    monkeypatch.setattr(sub_tts, "parse_args", lambda: Args())
    monkeypatch.setattr(sub_tts, "load_config", lambda: config)
    monkeypatch.setattr(sub_tts, "resolve_ffmpeg", lambda *a, **k: "ffmpeg")

    piper_cfg = configparser.ConfigParser()
    piper_cfg["tts_settings"] = {"supported_languages": "de,ru"}
    piper_cfg["voice_de"] = {"model": "de_voice.onnx"}
    piper_cfg["voice_ru"] = {"model": "ru_voice.onnx"}
    monkeypatch.setattr(sub_tts, "get_piper_config", lambda *a: (piper_cfg, tmp_path))

    # de succeeds, ru fails.
    call_count = [0]
    def mock_process(srt_path, **kw):
        call_count[0] += 1
        return (True, sub_tts.ShiftPlan([0])) if call_count[0] == 1 else (False, None)
    monkeypatch.setattr(sub_tts, "process_srt", mock_process)
    monkeypatch.setattr(sys, "exit", lambda code: None)

    sub_tts.main()

    # Partial failure: sidecar must be preserved.
    assert sidecar.exists()


def test_fallback_triggers_with_no_postfix_primary_media(monkeypatch, tmp_path):
    sub_tts = _load_sub_tts()
    import sys

    # Primary SRT has a postfix; the existing media is the no-postfix main file.
    primary_srt = tmp_path / "video.de.srt"
    primary_srt.write_text("1\n00:00:01,000 --> 00:00:02,000\nHallo", encoding="utf-8")
    (tmp_path / "video.mp4").write_text("dummy mp4", encoding="utf-8")  # no postfix

    config = configparser.ConfigParser()
    config["paths"] = {"piper_tts_root": str(tmp_path), "ffmpeg_executable": "ffmpeg"}
    config["tts_settings"] = {
        "default_lang": "en",
        "primary_languages": "de",
        "timeline_source": "primary_audio_or_subtitle_fallback",
        # keep_lang_postfix=true historically searched only for 'video.de.mp4'.
        "keep_lang_postfix": "true",
        "auto_discover_canonical": "false",
    }

    class Args:
        srt_files = [str(primary_srt)]
        lang = None
        output_dir = None
        ffmpeg_path = None
        keep_lang_postfix = None
        timeline_source = None
        reuse_canonical_output = False
        auto_discover_canonical = False
        sendto = False
        pause = False

    monkeypatch.setattr(sub_tts, "parse_args", lambda: Args())
    monkeypatch.setattr(sub_tts, "load_config", lambda: config)
    monkeypatch.setattr(sub_tts, "resolve_ffmpeg", lambda *a, **k: "ffmpeg")

    piper_cfg = configparser.ConfigParser()
    piper_cfg["tts_settings"] = {"supported_languages": "de"}
    piper_cfg["voice_de"] = {"model": "de_voice.onnx"}
    monkeypatch.setattr(sub_tts, "get_piper_config", lambda *a: (piper_cfg, tmp_path))

    called = []
    monkeypatch.setattr(sub_tts, "process_srt", lambda srt_path, **kw: (called.append(kw.get("timeline_source_override")), (True, sub_tts.ShiftPlan([0])))[1])
    monkeypatch.setattr(sys, "exit", lambda code: None)

    sub_tts.main()

    assert called == ["primary_subtitle"]


# ---------------------------------------------------------------------------
# Collapsed timeline enum + unified collision policy (ZID 20260606181116)
# ---------------------------------------------------------------------------

def test_resolve_timeline_mode_all_values():
    sub_tts = _load_sub_tts()
    # (base, shift_on_overflow, fallback_to_subtitle, ok)
    assert sub_tts.resolve_timeline_mode("primary_subtitle") == ("primary_subtitle", False, False, True)
    assert sub_tts.resolve_timeline_mode("primary_subtitle_shift") == ("primary_subtitle", True, False, True)
    assert sub_tts.resolve_timeline_mode("primary_audio") == ("primary_audio", False, False, True)
    assert sub_tts.resolve_timeline_mode("primary_audio_or_subtitle_fallback") == ("primary_audio", False, True, True)
    # Case/space tolerant
    assert sub_tts.resolve_timeline_mode("  Primary_Audio  ") == ("primary_audio", False, False, True)


def test_resolve_timeline_mode_invalid():
    sub_tts = _load_sub_tts()
    base, shift, fallback, ok = sub_tts.resolve_timeline_mode("nonsense")
    assert ok is False
    assert (base, shift, fallback) == ("primary_subtitle", False, False)
    # None is treated as unrecognized, not a crash
    assert sub_tts.resolve_timeline_mode(None)[3] is False


def _synced_collision_setup(sub_tts, monkeypatch, tmp_path, duplicate_mode):
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": "en",
        "timeline_source": "primary_subtitle",
        "keep_lang_postfix": "true",
        "duplicate_mode": duplicate_mode,
    }
    srt_file = tmp_path / "video.ru.srt"
    original_text = "1\n00:00:01,000 --> 00:00:02,000\nПривет"
    srt_file.write_text(original_text, encoding="utf-8")

    monkeypatch.setattr(sub_tts, "parse_srt", lambda *a: [{"index": 1, "start_ms": 1000, "end_ms": 2000, "text": "Привет"}])
    monkeypatch.setattr(
        sub_tts, "synthesize_all_cues",
        lambda *a: [{"ok": True, "wav_path": Path("cue_1.wav"), "cue": {"index": 1, "start_ms": 5000, "end_ms": 9000, "text": "Привет"}}],
    )
    monkeypatch.setattr(sub_tts, "adjust_speed_for_cues", lambda r, *a: r)
    monkeypatch.setattr(sub_tts, "assemble_audio", lambda *a: tmp_path / "assembled.wav")
    monkeypatch.setattr(sub_tts, "mux_to_mp4", lambda *a: True)

    piper_cfg = configparser.ConfigParser()
    piper_cfg["tts_settings"] = {"supported_languages": "ru"}
    piper_cfg["voice_ru"] = {"model": "ru_voice.onnx"}
    return config, srt_file, original_text, piper_cfg


def test_synced_collision_overwrite_mode_replaces_source(monkeypatch, tmp_path):
    sub_tts = _load_sub_tts()
    config, srt_file, original_text, piper_cfg = _synced_collision_setup(sub_tts, monkeypatch, tmp_path, "overwrite")

    ok, _ = sub_tts.process_srt(
        srt_file, config=config, piper_config=piper_cfg, piper_root=Path(""),
        ffmpeg_path="ffmpeg", zid_cache={"value": "20260606181116"},
        reuse_canonical_output_override=False,
    )
    assert ok is True
    # Source overwritten in place with the synced timeline; no ZID archive created.
    assert "00:00:05,000 --> 00:00:09,000" in srt_file.read_text(encoding="utf-8")
    assert not (tmp_path / "20260606181116").exists()


def test_synced_collision_skip_mode_preserves_source(monkeypatch, tmp_path):
    sub_tts = _load_sub_tts()
    config, srt_file, original_text, piper_cfg = _synced_collision_setup(sub_tts, monkeypatch, tmp_path, "skip")

    ok, _ = sub_tts.process_srt(
        srt_file, config=config, piper_config=piper_cfg, piper_root=Path(""),
        ffmpeg_path="ffmpeg", zid_cache={"value": "20260606181116"},
        reuse_canonical_output_override=False,
    )
    assert ok is True
    # Source left untouched; synced copy lands in the ZID subdirectory instead.
    assert srt_file.read_text(encoding="utf-8") == original_text
    synced = tmp_path / "20260606181116" / "video.ru.srt"
    assert "00:00:05,000 --> 00:00:09,000" in synced.read_text(encoding="utf-8")
