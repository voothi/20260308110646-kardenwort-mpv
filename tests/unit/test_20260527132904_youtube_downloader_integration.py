"""
Feature ZID: 20260527132904
Feature: YouTube Downloader Integration Tests
Acceptance/integration tests for downloader configurations, modes, subtitle languages, duplicate handling, and backend logic.
"""

import os
import shutil
import importlib.util
from pathlib import Path
import pytest

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


@pytest.fixture
def yd():
    return _load_downloader()


def test_directory_creation_and_write_check(yd, tmp_path, monkeypatch):
    """Verifies directory is created if missing and write permission checked."""
    target_dir = tmp_path / "new_download_folder"
    assert not target_dir.exists()
    
    settings = {
        "youtube_download_directory": str(target_dir),
        "youtube_download_duplicate_mode": "skip",
        "youtube_download_chapters_mode": "embedded",
        "youtube_download_mode": "video",
        "youtube_download_resolution": "360p",
        "youtube_download_subtitle_auto_fallback": True,
        "youtube_download_subtitle_languages": "original",
    }
    
    # Mock run_ytdlp_info
    monkeypatch.setattr(yd, "run_ytdlp_info", lambda url: {"title": "Test Title"})
    # Mock subprocess.run for yt-dlp download call
    monkeypatch.setattr(yd.subprocess, "run", lambda *args, **kwargs: None)
    
    used_zids = set()
    zid_cache = {}
    
    success = yd.download_video_and_metadata(
        "https://youtube.com/watch?v=dQw4w9WgXcQ",
        settings,
        used_zids,
        zid_cache
    )
    
    assert success
    assert target_dir.exists()


def test_duplicate_mode_skip(yd, tmp_path, monkeypatch):
    """Verifies duplicate mode 'skip' skips the download when file exists."""
    target_dir = tmp_path
    existing_file = target_dir / "20260527132904-test-title.mp4"
    existing_file.touch()
    
    settings = {
        "youtube_download_directory": str(target_dir),
        "youtube_download_duplicate_mode": "skip",
        "youtube_download_chapters_mode": "embedded",
        "youtube_download_mode": "video",
        "youtube_download_resolution": "360p",
        "youtube_download_subtitle_auto_fallback": True,
        "youtube_download_subtitle_languages": "original",
    }
    
    monkeypatch.setattr(yd, "run_ytdlp_info", lambda url: {"title": "Test Title"})
    # Ensure subprocess.run is never called since it is skipped
    called = False
    def mock_run(cmd, *args, **kwargs):
        nonlocal called
        called = True
        
    monkeypatch.setattr(yd.subprocess, "run", mock_run)
    monkeypatch.setattr(yd, "get_unique_zid", lambda used: "20260527132904")
    
    success = yd.download_video_and_metadata(
        "https://youtube.com/watch?v=dQw4w9WgXcQ",
        settings,
        set(),
        {}
    )
    
    assert success
    assert not called  # Did not trigger download


def test_duplicate_mode_zid_dir(yd, tmp_path, monkeypatch):
    """Verifies duplicate mode 'zid-dir' puts file in a session subfolder."""
    target_dir = tmp_path
    existing_file = target_dir / "20260527132904-test-title.mp4"
    existing_file.touch()
    
    settings = {
        "youtube_download_directory": str(target_dir),
        "youtube_download_duplicate_mode": "zid-dir",
        "youtube_download_chapters_mode": "embedded",
        "youtube_download_mode": "video",
        "youtube_download_resolution": "360p",
        "youtube_download_subtitle_auto_fallback": True,
        "youtube_download_subtitle_languages": "original",
    }
    
    monkeypatch.setattr(yd, "run_ytdlp_info", lambda url: {"title": "Test Title"})
    
    download_dir = None
    def mock_run(cmd, *args, **kwargs):
        nonlocal download_dir
        # Find the output path in cmd
        for idx, arg in enumerate(cmd):
            if arg == "-o":
                download_dir = Path(cmd[idx+1]).parent
                break
                
    monkeypatch.setattr(yd.subprocess, "run", mock_run)
    monkeypatch.setattr(yd, "get_unique_zid", lambda used: "20260527132904")
    
    zid_cache = {}
    success = yd.download_video_and_metadata(
        "https://youtube.com/watch?v=dQw4w9WgXcQ",
        settings,
        set(),
        zid_cache
    )
    
    assert success
    assert download_dir == target_dir / "20260527132904"
    assert zid_cache["value"] == "20260527132904"


def test_chapter_separate_file_mode(yd, tmp_path, monkeypatch):
    """Verifies chapters are saved to a separate .chapters.txt file."""
    target_dir = tmp_path
    
    settings = {
        "youtube_download_directory": str(target_dir),
        "youtube_download_duplicate_mode": "overwrite",
        "youtube_download_chapters_mode": "separate",
        "youtube_download_mode": "video",
        "youtube_download_resolution": "360p",
        "youtube_download_subtitle_auto_fallback": True,
        "youtube_download_subtitle_languages": "original",
    }
    
    chapters_metadata = [
        {"start_time": 0.0, "title": "Intro"},
        {"start_time": 125.5, "title": "Main Topic"},
    ]
    
    monkeypatch.setattr(yd, "run_ytdlp_info", lambda url: {"title": "Test Video", "chapters": chapters_metadata})
    monkeypatch.setattr(yd.subprocess, "run", lambda *args, **kwargs: None)
    monkeypatch.setattr(yd, "get_unique_zid", lambda used: "20260527132904")
    
    success = yd.download_video_and_metadata(
        "https://youtube.com/watch?v=dQw4w9WgXcQ",
        settings,
        set(),
        {}
    )
    
    assert success
    chapters_file = target_dir / "20260527132904-test-video.chapters.txt"
    assert chapters_file.exists()
    content = chapters_file.read_text(encoding="utf-8")
    assert "00:00:00 - Intro" in content
    assert "00:02:05 - Main Topic" in content


def test_download_mode_subtitles_only(yd, tmp_path, monkeypatch):
    """Verifies mode 'subtitles' skips video download via --skip-download."""
    target_dir = tmp_path
    
    settings = {
        "youtube_download_directory": str(target_dir),
        "youtube_download_duplicate_mode": "overwrite",
        "youtube_download_chapters_mode": "embedded",
        "youtube_download_mode": "subtitles",
        "youtube_download_resolution": "360p",
        "youtube_download_subtitle_auto_fallback": True,
        "youtube_download_subtitle_languages": "original",
    }
    
    monkeypatch.setattr(yd, "run_ytdlp_info", lambda url: {"title": "Test Video", "language": "en", "subtitles": {"en": {}}})
    
    skip_download_passed = False
    def mock_run(cmd, *args, **kwargs):
        nonlocal skip_download_passed
        if "--skip-download" in cmd:
            skip_download_passed = True
            
    monkeypatch.setattr(yd.subprocess, "run", mock_run)
    monkeypatch.setattr(yd, "get_unique_zid", lambda used: "20260527132904")
    
    success = yd.download_video_and_metadata(
        "https://youtube.com/watch?v=dQw4w9WgXcQ",
        settings,
        set(),
        {}
    )
    
    assert success
    assert skip_download_passed


def test_download_directory_source(yd, tmp_path, monkeypatch):
    """Verifies that 'source' download directory correctly uses source_dir."""
    source_folder = tmp_path / "my_source_folder"
    source_folder.mkdir()
    
    settings = {
        "youtube_download_directory": "source",
        "youtube_download_duplicate_mode": "overwrite",
        "youtube_download_chapters_mode": "embedded",
        "youtube_download_mode": "video",
        "youtube_download_resolution": "360p",
        "youtube_download_subtitle_auto_fallback": True,
        "youtube_download_subtitle_languages": "original",
    }
    
    monkeypatch.setattr(yd, "run_ytdlp_info", lambda url: {"title": "Source Video"})
    
    download_dir = None
    def mock_run(cmd, *args, **kwargs):
        nonlocal download_dir
        for idx, arg in enumerate(cmd):
            if arg == "-o":
                download_dir = Path(cmd[idx+1]).parent
                break
                
    monkeypatch.setattr(yd.subprocess, "run", mock_run)
    monkeypatch.setattr(yd, "get_unique_zid", lambda used: "20260527132904")
    
    success = yd.download_video_and_metadata(
        "https://youtube.com/watch?v=dQw4w9WgXcQ",
        settings,
        set(),
        {},
        source_dir=source_folder
    )
    
    assert success
    assert download_dir == source_folder


def test_subtitle_languages_mixed_original(yd, tmp_path, monkeypatch):
    """Verifies that 'original,ru' maps to detected lang (e.g. en) plus additional languages."""
    target_dir = tmp_path
    
    settings = {
        "youtube_download_directory": str(target_dir),
        "youtube_download_duplicate_mode": "overwrite",
        "youtube_download_chapters_mode": "embedded",
        "youtube_download_mode": "subtitles",
        "youtube_download_resolution": "360p",
        "youtube_download_subtitle_auto_fallback": True,
        "youtube_download_subtitle_languages": "original,ru",
    }
    
    # Detected lang is 'en', manual subtitles exist for 'en' and 'ru'
    monkeypatch.setattr(yd, "run_ytdlp_info", lambda url: {
        "title": "Test Video",
        "language": "en",
        "subtitles": {"en": {}, "ru": {}}
    })
    
    sub_langs_passed = None
    def mock_run(cmd, *args, **kwargs):
        nonlocal sub_langs_passed
        for idx, arg in enumerate(cmd):
            if arg == "--sub-langs":
                sub_langs_passed = cmd[idx+1]
                break
                
    monkeypatch.setattr(yd.subprocess, "run", mock_run)
    monkeypatch.setattr(yd, "get_unique_zid", lambda used: "20260527132904")
    
    success = yd.download_video_and_metadata(
        "https://youtube.com/watch?v=dQw4w9WgXcQ",
        settings,
        set(),
        {}
    )
    
    assert success
    # 'original,ru' -> 'en,ru'
    assert sub_langs_passed == "en,ru"


