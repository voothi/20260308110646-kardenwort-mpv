"""
Feature ZID: 20260526195053
Feature: Sub TTS Pipeline
Unit tests for the subtitle-to-TTS timing and naming rules.
"""

import configparser
import importlib.util
from pathlib import Path


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


def _config(default_lang="en", duplicate_mode="zid-dir"):
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "default_lang": default_lang,
        "duplicate_mode": duplicate_mode,
    }
    config["lang_aliases"] = {
        "eng": "en",
        "ger": "de",
        "rus": "ru",
    }
    return config


def test_parse_srt_strips_markup_and_keeps_multiline_text(monkeypatch):
    sub_tts = _load_sub_tts()
    content = (
        "\ufeff1\n"
        "00:00:01,000 --> 00:00:02,500\n"
        "<i>Hello</i>\n"
        "{\\an8}world\n\n"
        "2\n"
        "00:00:03,000 --> 00:00:04,000\n"
        "   \n"
    )
    monkeypatch.setattr(Path, "exists", lambda self: True)
    monkeypatch.setattr(Path, "read_text", lambda self, **kwargs: content.lstrip("\ufeff"))

    cues = sub_tts.parse_srt(Path("sample.en.srt"))

    assert cues == [
        {
            "index": 1,
            "start_ms": 1000,
            "end_ms": 2500,
            "text": "Hello world",
        }
    ]


def test_detect_language_uses_alias_and_default_fallback():
    sub_tts = _load_sub_tts()
    config = _config(default_lang="en")

    assert sub_tts.detect_language("lesson.ger.srt", config) == "de"
    assert sub_tts.detect_language("lesson.rus.srt", config) == "ru"
    assert sub_tts.detect_language("lesson.srt", config) == "en"


def test_resolve_output_path_strips_language_postfix():
    sub_tts = _load_sub_tts()
    config = _config()
    output_dir = Path("C:/kardenwort-test-output")
    srt_path = output_dir / "video.en.srt"

    output_path, policy = sub_tts.resolve_output_path(
        srt_path,
        output_dir,
        config,
        "en",
        zid_cache={"zid": "20260526195053"},
    )

    assert output_path == output_dir / "video.mp4"
    assert policy == "new"


def test_audio_placement_plan_reports_overflow_without_moving_next_cue(monkeypatch):
    sub_tts = _load_sub_tts()
    durations = {
        "cue_001.wav": 3000,
        "cue_002.wav": 1000,
    }

    def fake_duration(path, ffmpeg_path):
        return durations[Path(path).name]

    monkeypatch.setattr(sub_tts, "get_wav_duration_ms", fake_duration)
    synthesis_results = [
        {
            "ok": True,
            "wav_path": Path("cue_001.wav"),
            "cue": {"index": 1, "start_ms": 1000, "end_ms": 2000, "text": "slow"},
        },
        {
            "ok": True,
            "wav_path": Path("cue_002.wav"),
            "cue": {"index": 2, "start_ms": 2500, "end_ms": 3500, "text": "next"},
        },
    ]

    plan, max_end_ms = sub_tts.build_audio_placement_plan(synthesis_results, "ffmpeg")

    assert plan[0]["start_ms"] == 1000
    assert plan[0]["audio_end_ms"] == 4000
    assert plan[0]["next_start_ms"] == 2500
    assert plan[0]["overflow_ms"] == 1500
    assert plan[1]["start_ms"] == 2500
    assert max_end_ms == 4000


def test_speed_factor_is_capped_for_subtitle_fit():
    sub_tts = _load_sub_tts()

    assert sub_tts.calculate_speed_factor(9000, 6000, 2.0) == 1.5
    assert sub_tts.calculate_speed_factor(9000, 3000, 2.0) == 2.0
    assert sub_tts.calculate_speed_factor(3000, 6000, 2.0) == 1.0


def test_atempo_filter_chains_large_speed_factors():
    sub_tts = _load_sub_tts()

    assert sub_tts.build_atempo_filter(1.25) == "atempo=1.250"
    assert sub_tts.build_atempo_filter(3.0) == "atempo=2.000,atempo=1.500"


def test_resolve_output_path_keeps_language_postfix_when_overridden():
    sub_tts = _load_sub_tts()
    config = _config()
    output_dir = Path("C:/kardenwort-test-output")
    srt_path = output_dir / "video.en.srt"

    output_path, policy = sub_tts.resolve_output_path(
        srt_path,
        output_dir,
        config,
        "en",
        zid_cache={"zid": "20260526195053"},
        keep_lang_postfix=True,
    )

    assert output_path == output_dir / "video.en.mp4"
    assert policy == "new"


def test_resolve_output_path_respects_config_option():
    sub_tts = _load_sub_tts()
    config = _config()
    config["tts_settings"]["keep_lang_postfix"] = "true"
    output_dir = Path("C:/kardenwort-test-output")
    srt_path = output_dir / "video.de.srt"

    output_path, policy = sub_tts.resolve_output_path(
        srt_path,
        output_dir,
        config,
        "de",
        zid_cache={"zid": "20260526195053"},
    )

    assert output_path == output_dir / "video.de.mp4"
    assert policy == "new"


def test_make_cue_progress_bar_lstrip():
    sub_tts = _load_sub_tts()
    bar = sub_tts.make_cue_progress_bar(1, 10, "Test Label", detail="Detail Text")
    assert bar.startswith("\r")
    assert not bar.lstrip("\r").startswith("\r")


def test_non_tty_throttle_writes_expected_line_count(monkeypatch, capsys, tmp_path):
    sub_tts = _load_sub_tts()
    monkeypatch.setattr(sub_tts, "_IS_TTY", False)
    monkeypatch.setattr(sub_tts, "synthesize_cue", lambda *a, **kw: True)
    cues = [{"index": i, "text": "x", "start_ms": 0, "end_ms": 1000} for i in range(1, 101)]
    sub_tts.synthesize_all_cues(cues, "en", tmp_path, Path("piper_root_stub"))
    captured = capsys.readouterr()
    lines = [l for l in captured.out.splitlines() if l.strip()]
    assert len(lines) == 11  # first + 9 deltas + last
    assert "\r" not in captured.out


def test_plan_subtitle_shifts_no_overflow(monkeypatch):
    sub_tts = _load_sub_tts()
    durations = {"cue_001.wav": 800, "cue_002.wav": 700}

    def fake_duration(path, ffmpeg_path):
        return durations[Path(path).name]

    monkeypatch.setattr(sub_tts, "get_wav_duration_ms", fake_duration)
    synthesis_results = [
        {"ok": True, "wav_path": Path("cue_001.wav"), "cue": {"index": 1, "start_ms": 1000, "end_ms": 2000, "text": "a"}},
        {"ok": True, "wav_path": Path("cue_002.wav"), "cue": {"index": 2, "start_ms": 2500, "end_ms": 3500, "text": "b"}},
    ]

    plan = sub_tts.plan_subtitle_shifts(synthesis_results, "ffmpeg")
    assert plan == [0, 0]


def test_plan_subtitle_shifts_single_overflow(monkeypatch):
    sub_tts = _load_sub_tts()
    durations = {"cue_001.wav": 3000, "cue_002.wav": 1000}

    def fake_duration(path, ffmpeg_path):
        return durations[Path(path).name]

    monkeypatch.setattr(sub_tts, "get_wav_duration_ms", fake_duration)
    synthesis_results = [
        {"ok": True, "wav_path": Path("cue_001.wav"), "cue": {"index": 1, "start_ms": 1000, "end_ms": 1500, "text": "a"}},
        {"ok": True, "wav_path": Path("cue_002.wav"), "cue": {"index": 2, "start_ms": 2000, "end_ms": 2500, "text": "b"}},
    ]

    plan = sub_tts.plan_subtitle_shifts(synthesis_results, "ffmpeg")
    assert plan == [0, 2000]


def test_plan_subtitle_shifts_accumulated_drift(monkeypatch):
    sub_tts = _load_sub_tts()
    durations = {"cue_001.wav": 1500, "cue_002.wav": 1500, "cue_003.wav": 900}

    def fake_duration(path, ffmpeg_path):
        return durations[Path(path).name]

    monkeypatch.setattr(sub_tts, "get_wav_duration_ms", fake_duration)
    synthesis_results = [
        {"ok": True, "wav_path": Path("cue_001.wav"), "cue": {"index": 1, "start_ms": 0, "end_ms": 500, "text": "a"}},
        {"ok": True, "wav_path": Path("cue_002.wav"), "cue": {"index": 2, "start_ms": 1000, "end_ms": 1500, "text": "b"}},
        {"ok": True, "wav_path": Path("cue_003.wav"), "cue": {"index": 3, "start_ms": 2000, "end_ms": 2500, "text": "c"}},
    ]

    plan = sub_tts.plan_subtitle_shifts(synthesis_results, "ffmpeg")
    assert plan == [0, 500, 1000]


def test_plan_subtitle_shifts_never_pulls_earlier(monkeypatch):
    sub_tts = _load_sub_tts()
    durations = {"cue_001.wav": 1500, "cue_002.wav": 200, "cue_003.wav": 1100}

    def fake_duration(path, ffmpeg_path):
        return durations[Path(path).name]

    monkeypatch.setattr(sub_tts, "get_wav_duration_ms", fake_duration)
    synthesis_results = [
        {"ok": True, "wav_path": Path("cue_001.wav"), "cue": {"index": 1, "start_ms": 0, "end_ms": 500, "text": "a"}},
        {"ok": True, "wav_path": Path("cue_002.wav"), "cue": {"index": 2, "start_ms": 1000, "end_ms": 1500, "text": "b"}},
        {"ok": True, "wav_path": Path("cue_003.wav"), "cue": {"index": 3, "start_ms": 1600, "end_ms": 2000, "text": "c"}},
    ]

    plan = sub_tts.plan_subtitle_shifts(synthesis_results, "ffmpeg")
    assert plan == [0, 500, 500]


def test_apply_shift_plan_mismatch_prefix():
    sub_tts = _load_sub_tts()
    synthesis_results = [
        {"ok": True, "wav_path": Path("cue_001.wav"), "cue": {"index": 1, "start_ms": 1000, "end_ms": 2000, "text": "a"}},
        {"ok": True, "wav_path": Path("cue_002.wav"), "cue": {"index": 2, "start_ms": 2000, "end_ms": 3000, "text": "b"}},
        {"ok": True, "wav_path": Path("cue_003.wav"), "cue": {"index": 3, "start_ms": 3000, "end_ms": 4000, "text": "c"}},
    ]

    shifted = sub_tts.apply_shift_plan(synthesis_results, [0, 500])
    assert shifted[0]["cue"]["start_ms"] == 1000
    assert shifted[1]["cue"]["start_ms"] == 2500
    assert shifted[2]["cue"]["start_ms"] == 3000


def test_plan_subtitle_shifts_does_not_mutate_input(monkeypatch):
    sub_tts = _load_sub_tts()
    monkeypatch.setattr(sub_tts, "get_wav_duration_ms", lambda path, ffmpeg_path: 3000)
    synthesis_results = [
        {"ok": True, "wav_path": Path("cue_001.wav"), "cue": {"index": 1, "start_ms": 1000, "end_ms": 1500, "text": "a"}},
        {"ok": True, "wav_path": Path("cue_002.wav"), "cue": {"index": 2, "start_ms": 2000, "end_ms": 2500, "text": "b"}},
    ]

    sub_tts.plan_subtitle_shifts(synthesis_results, "ffmpeg")

    assert "wav_duration_ms_cached" not in synthesis_results[0]
    assert synthesis_results[0]["cue"]["start_ms"] == 1000
    assert synthesis_results[1]["cue"]["start_ms"] == 2000


def test_apply_shift_plan_uses_cue_position_when_synthesis_failed():
    sub_tts = _load_sub_tts()
    synthesis_results = [
        {"ok": True, "wav_path": Path("cue_001.wav"), "cue": {"index": 1, "start_ms": 1000, "end_ms": 2000, "text": "a"}},
        {"ok": False, "wav_path": None, "cue": {"index": 2, "start_ms": 2000, "end_ms": 3000, "text": "b"}},
        {"ok": True, "wav_path": Path("cue_003.wav"), "cue": {"index": 3, "start_ms": 3000, "end_ms": 4000, "text": "c"}},
    ]

    shifted = sub_tts.apply_shift_plan(synthesis_results, [0, 500, 1000])

    assert shifted[0]["cue"]["start_ms"] == 1000
    assert shifted[1]["cue"]["start_ms"] == 2500
    assert shifted[2]["cue"]["start_ms"] == 4000


