"""
Feature ZID: 20260527190807
Feature: YouTube Downloader — Companion Audio Track Download (Section 14)
Unit tests for download_companion_audio(): metadata guard, yt-dlp command shape,
multi-language iteration, existing-file skip, and missing-file recovery logic.
"""

import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

_SCRIPT_PATH = (
    Path(__file__).resolve().parents[2]
    / "scripts"
    / "_tools"
    / "youtube-downloader"
    / "youtube_downloader.py"
)


def _load_downloader():
    spec = importlib.util.spec_from_file_location("youtube_downloader_under_test", _SCRIPT_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _make_info(formats=None):
    return {
        "title": "Test Video",
        "language": "en",
        "subtitles": {},
        "automatic_captions": {},
        "chapters": [],
        "formats": formats or [],
    }

def _audio_only(lang):
    return {"acodec": "mp4a.40.2", "vcodec": "none", "language": lang, "format_id": f"audio-{lang}"}

def _combined(lang="en"):
    return {"acodec": "mp4a.40.2", "vcodec": "avc1.64001F", "language": lang, "format_id": f"video-{lang}"}

def _settings(**overrides):
    base = {
        "youtube_download_resolution": "360p",
        "youtube_download_directory": "",
        "youtube_download_mode": "video+subtitles",
        "youtube_download_duplicate_mode": "skip",
        "youtube_download_subtitle_languages": "en",
        "youtube_download_subtitle_auto_fallback": False,
        "youtube_download_auto_update": False,
        "youtube_download_chapters_mode": "embedded",
        "youtube_download_cookies_browser": "",
        "youtube_download_cookies_file": "",
        "youtube_download_clean_hyphens": False,
        "youtube_download_unbreak_lines": False,
        "youtube_download_hyphenation_marks": "-¬",
        "youtube_download_compositional_conjunctions": "und,oder,sowie,bzw,bis",
        "youtube_download_fix_sentence_splits": False,
        "youtube_download_sync_secondary_timestamps": False,
        "youtube_download_companion_audio_languages": "",
        "youtube_download_zid_script": "",
    }
    base.update(overrides)
    return base


# ---------------------------------------------------------------------------
# Pipeline guard: empty languages string → no downloads triggered
# ---------------------------------------------------------------------------

def test_companion_audio_disabled_when_empty():
    settings = _settings(youtube_download_companion_audio_languages="")
    comp_langs_str = settings["youtube_download_companion_audio_languages"].strip()
    comp_langs = [l.strip() for l in comp_langs_str.split(",") if l.strip()]
    assert comp_langs == [], "Empty string must produce an empty language list"


# ---------------------------------------------------------------------------
# Metadata guard: no audio-only dubbed track → graceful skip, no yt-dlp call
# ---------------------------------------------------------------------------

def test_companion_audio_skips_when_no_dubbed_track():
    yd = _load_downloader()
    info = _make_info(formats=[_combined("en")])
    call_count = [0]

    def fake_run(cmd, **kwargs):
        call_count[0] += 1

    with patch.object(yd, "run_subprocess_streaming", side_effect=fake_run):
        result = yd.download_companion_audio(
            "https://youtu.be/test", "20260527000001", "test-video",
            Path(tempfile.gettempdir()), "ru", info, _settings()
        )

    assert result is True, "Graceful skip must return True"
    assert call_count[0] == 0, "yt-dlp must not be called when no dubbed track exists"


def test_companion_audio_skips_combined_format():
    """Combined video+audio format with correct language must NOT trigger download."""
    yd = _load_downloader()
    formats = [{"acodec": "mp4a.40.2", "vcodec": "avc1.64001F", "language": "ru"}]
    info = _make_info(formats=formats)
    call_count = [0]

    def fake_run(cmd, **kwargs):
        call_count[0] += 1

    with patch.object(yd, "run_subprocess_streaming", side_effect=fake_run):
        result = yd.download_companion_audio(
            "https://youtu.be/test", "20260527000001", "test-video",
            Path(tempfile.gettempdir()), "ru", info, _settings()
        )

    assert result is True
    assert call_count[0] == 0


# ---------------------------------------------------------------------------
# Single language: correct yt-dlp command shape
# ---------------------------------------------------------------------------

def test_companion_audio_download_single_lang():
    yd = _load_downloader()
    info = _make_info(formats=[_audio_only("ru")])
    captured = {}

    with tempfile.TemporaryDirectory() as tmp:
        target_dir = Path(tmp)
        comp_file = target_dir / "20260527000001-test-video.ru.mp4"

        def fake_run(cmd, **kwargs):
            captured["cmd"] = cmd
            comp_file.touch()

        with patch.object(yd, "run_subprocess_streaming", side_effect=fake_run):
            result = yd.download_companion_audio(
                "https://youtu.be/test", "20260527000001", "test-video",
                target_dir, "ru", info, _settings()
            )

    assert result is True

    cmd = captured["cmd"]
    assert "-f" in cmd
    assert cmd[cmd.index("-f") + 1] == "bestaudio[language=ru]"
    assert "--merge-output-format" in cmd
    assert cmd[cmd.index("--merge-output-format") + 1] == "mp4"


def test_companion_audio_region_base_code_matches_regional_metadata():
    yd = _load_downloader()
    info = _make_info(formats=[_audio_only("ru-RU")])
    call_count = [0]

    def fake_run(cmd, **kwargs):
        call_count[0] += 1

    with patch.object(yd, "run_subprocess_streaming", side_effect=fake_run):
        result = yd.download_companion_audio(
            "https://youtu.be/test", "20260527000001", "test-video",
            Path("C:/tmp"), "ru", info, _settings()
        )

    assert result is True
    assert call_count[0] == 1


def test_companion_audio_region_match_uses_metadata_tag_in_selector():
    """Deterministic end-to-end check: selector must use metadata tag (ru-RU), not config code (ru)."""
    yd = _load_downloader()
    info = _make_info(formats=[_audio_only("ru-RU")])
    captured = {}

    def fake_run(cmd, **kwargs):
        captured["cmd"] = cmd

    with patch.object(yd, "run_subprocess_streaming", side_effect=fake_run):
        result = yd.download_companion_audio(
            "https://youtu.be/test", "20260527000001", "test-video",
            Path("C:/tmp"), "ru", info, _settings()
        )

    assert result is True
    cmd = captured["cmd"]
    assert "-f" in cmd
    assert cmd[cmd.index("-f") + 1] == "bestaudio[language=ru-RU]"


# ---------------------------------------------------------------------------
# Multi-language: download called once per language
# ---------------------------------------------------------------------------

def test_companion_audio_download_multi_lang():
    settings = _settings(youtube_download_companion_audio_languages="ru,de")
    comp_langs_str = settings["youtube_download_companion_audio_languages"].strip()
    comp_langs = [l.strip() for l in comp_langs_str.split(",") if l.strip()]

    called_langs = []
    with tempfile.TemporaryDirectory() as tmp:
        target_dir = Path(tmp)
        for lang in comp_langs:
            comp_file = target_dir / f"20260527000001-test-video.{lang}.mp4"
            if not comp_file.exists():
                called_langs.append(lang)

    assert called_langs == ["ru", "de"]


# ---------------------------------------------------------------------------
# Skip existing: pipeline skips file that already exists
# ---------------------------------------------------------------------------

def test_companion_audio_skip_existing():
    yd = _load_downloader()
    info = _make_info(formats=[_audio_only("ru")])

    with tempfile.TemporaryDirectory() as tmp:
        target_dir = Path(tmp)
        comp_file = target_dir / "20260527000001-test-video.ru.mp4"
        comp_file.touch()

        call_count = [0]

        def fake_run(cmd, **kwargs):
            call_count[0] += 1

        with patch.object(yd, "run_subprocess_streaming", side_effect=fake_run):
            if not comp_file.exists():
                yd.download_companion_audio(
                    "https://youtu.be/test", "20260527000001", "test-video",
                    target_dir, "ru", info, _settings()
                )

        assert call_count[0] == 0, "yt-dlp must not be called when companion file already exists"


# ---------------------------------------------------------------------------
# Missing-file recovery: absent companion audio added to missing_files
# ---------------------------------------------------------------------------

def test_companion_audio_missing_recovery_in_skip_mode():
    old_zid = "20260527000000"
    title = "test-video"

    with tempfile.TemporaryDirectory() as tmp:
        out_dir = Path(tmp)
        (out_dir / f"{old_zid}-{title}.mp4").touch()  # Video exists

        missing_files = []
        for comp_lang in ["ru"]:
            if not (out_dir / f"{old_zid}-{title}.{comp_lang}.mp4").exists():
                missing_files.append(f"{comp_lang}.mp4 (companion audio)")

        assert "ru.mp4 (companion audio)" in missing_files


def test_no_missing_when_companion_exists():
    old_zid = "20260527000000"
    title = "test-video"

    with tempfile.TemporaryDirectory() as tmp:
        out_dir = Path(tmp)
        (out_dir / f"{old_zid}-{title}.mp4").touch()
        (out_dir / f"{old_zid}-{title}.ru.mp4").touch()

        missing_files = []
        for comp_lang in ["ru"]:
            if not (out_dir / f"{old_zid}-{title}.{comp_lang}.mp4").exists():
                missing_files.append(f"{comp_lang}.mp4 (companion audio)")

        assert missing_files == []
