"""
Feature ZID: 20260527132904
Feature: YouTube Downloader Integration Tests
Acceptance/integration tests for downloader configurations, modes, subtitle languages, duplicate handling, and backend logic.
"""

import os
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


def test_subtitle_languages_mixed_original(yd, monkeypatch):
    """Verifies that 'original,ru' maps to detected lang (e.g. en) plus additional languages."""
    target_dir = Path(__file__).resolve().parents[2] / "tmp_test_20260528022742_mixed_original"
    target_dir.mkdir(parents=True, exist_ok=True)
    
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

def test_subtitle_languages_original_and_base_do_not_duplicate(yd, monkeypatch):
    """Verifies that 'original,ru' does not duplicate when original resolves to ru-RU."""
    target_dir = Path(__file__).resolve().parents[2] / "tmp_test_20260528022742_original_base"
    target_dir.mkdir(parents=True, exist_ok=True)

    settings = {
        "youtube_download_directory": str(target_dir),
        "youtube_download_duplicate_mode": "overwrite",
        "youtube_download_chapters_mode": "embedded",
        "youtube_download_mode": "subtitles",
        "youtube_download_resolution": "360p",
        "youtube_download_subtitle_auto_fallback": True,
        "youtube_download_subtitle_languages": "original,ru,",
    }

    monkeypatch.setattr(yd, "run_ytdlp_info", lambda url: {
        "title": "Test Video",
        "language": "ru-RU",
        "subtitles": {"ru-RU": {}},
    })

    sub_langs_passed = None
    def mock_run(cmd, *args, **kwargs):
        nonlocal sub_langs_passed
        for idx, arg in enumerate(cmd):
            if arg == "--sub-langs":
                sub_langs_passed = cmd[idx + 1]
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
    assert sub_langs_passed == "ru-RU"


def test_subtitle_download_fails_gracefully(yd, tmp_path, monkeypatch):
    """Verifies that subtitle download failures do not abort video download."""
    target_dir = tmp_path
    
    settings = {
        "youtube_download_directory": str(target_dir),
        "youtube_download_duplicate_mode": "overwrite",
        "youtube_download_chapters_mode": "embedded",
        "youtube_download_mode": "video+subtitles",
        "youtube_download_resolution": "360p",
        "youtube_download_subtitle_auto_fallback": True,
        "youtube_download_subtitle_languages": "en",
    }
    
    monkeypatch.setattr(yd, "run_ytdlp_info", lambda url: {
        "title": "Test Video",
        "language": "en",
        "subtitles": {"en": {}}
    })
    
    import subprocess
    video_download_called = False
    
    def mock_run(cmd, *args, **kwargs):
        nonlocal video_download_called
        if "--skip-download" in cmd:
            # Simulate subtitle download failure
            raise subprocess.CalledProcessError(1, cmd, stderr="HTTP Error 429: Too Many Requests")
        else:
            video_download_called = True
            
    monkeypatch.setattr(yd.subprocess, "run", mock_run)
    monkeypatch.setattr(yd, "get_unique_zid", lambda used: "20260527132904")
    
    success = yd.download_video_and_metadata(
        "https://youtube.com/watch?v=dQw4w9WgXcQ",
        settings,
        set(),
        {}
    )
    
    assert success  # Returns True because video download succeeded!
    assert video_download_called  # Video download was executed!


def test_duplicate_mode_skip_recovers_missing_subtitles(yd, tmp_path, monkeypatch):
    """Verifies that in skip mode, if the video exists but subtitles are missing, only subtitles are downloaded using the old ZID."""
    target_dir = tmp_path
    
    # Touch existing video file
    existing_video = target_dir / "20260527132904-test-video.mp4"
    existing_video.touch()
    
    settings = {
        "youtube_download_directory": str(target_dir),
        "youtube_download_duplicate_mode": "skip",
        "youtube_download_chapters_mode": "separate",
        "youtube_download_mode": "video+subtitles",
        "youtube_download_resolution": "360p",
        "youtube_download_subtitle_auto_fallback": True,
        "youtube_download_subtitle_languages": "en",
    }
    
    chapters_metadata = [
        {"start_time": 0.0, "title": "Intro"},
    ]
    
    # Detected lang is 'en', subtitles exist in metadata
    monkeypatch.setattr(yd, "run_ytdlp_info", lambda url: {
        "title": "Test Video",
        "language": "en",
        "subtitles": {"en": {}},
        "chapters": chapters_metadata
    })
    
    video_download_called = False
    subtitle_download_called = False
    
    def mock_run(cmd, *args, **kwargs):
        nonlocal video_download_called, subtitle_download_called
        if "--skip-download" in cmd:
            subtitle_download_called = True
            # Simulate writing the subtitle file
            sub_file = target_dir / "20260527132904-test-video.en.srt"
            sub_file.touch()
        else:
            video_download_called = True
            
    monkeypatch.setattr(yd.subprocess, "run", mock_run)
    # The new ZID generated is different, but the script should override it to match existing file's ZID
    monkeypatch.setattr(yd, "get_unique_zid", lambda used: "99999999999999")
    
    success = yd.download_video_and_metadata(
        "https://youtube.com/watch?v=dQw4w9WgXcQ",
        settings,
        set(),
        {}
    )
    
    assert success
    assert not video_download_called  # Video download was skipped!
    assert subtitle_download_called   # Subtitle download was initiated!
    
    # Verify subtitle was created with the correct old ZID
    assert (target_dir / "20260527132904-test-video.en.srt").exists()
    # Verify chapters was created with the correct old ZID
    assert (target_dir / "20260527132904-test-video.chapters.txt").exists()


def test_download_mode_subtitles_failure(yd, tmp_path, monkeypatch):
    """Verifies that if subtitles download fails in subtitles mode, the function returns False."""
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
    
    def mock_run(cmd, *args, **kwargs):
        raise yd.subprocess.CalledProcessError(1, cmd)
        
    monkeypatch.setattr(yd.subprocess, "run", mock_run)
    monkeypatch.setattr(yd, "get_unique_zid", lambda used: "20260527132904")
    
    success = yd.download_video_and_metadata(
        "https://youtube.com/watch?v=dQw4w9WgXcQ",
        settings,
        set(),
        {}
    )
    
    assert not success


def test_no_subtitle_redownload_when_only_companion_missing(yd, tmp_path, monkeypatch):
    """Skip recovery: if only companion audio is missing, subtitles must not be redownloaded."""
    old_zid = "20260527132904"
    (tmp_path / f"{old_zid}-test-video.mp4").touch()
    (tmp_path / f"{old_zid}-test-video.en.srt").touch()

    settings = {
        "youtube_download_directory": str(tmp_path),
        "youtube_download_duplicate_mode": "skip",
        "youtube_download_chapters_mode": "embedded",
        "youtube_download_mode": "video+subtitles",
        "youtube_download_resolution": "360p",
        "youtube_download_subtitle_auto_fallback": True,
        "youtube_download_subtitle_languages": "en",
        "youtube_download_companion_audio_languages": "ru",
        "youtube_download_sync_secondary_timestamps": False,
    }

    monkeypatch.setattr(yd, "run_ytdlp_info", lambda url: {
        "title": "Test Video",
        "language": "en",
        "subtitles": {"en": {}},
        "chapters": [],
        "formats": [{"acodec": "mp4a.40.2", "vcodec": "none", "language": "ru"}],
    })
    monkeypatch.setattr(yd, "get_unique_zid", lambda used: "99999999999999")

    seen_cmds = []
    def mock_stream(cmd, check=True, **kwargs):
        seen_cmds.append(cmd)
        if "--skip-download" in cmd:
            raise AssertionError("Subtitle command must not run when only companion audio is missing.")
        if any(str(arg).startswith("bestaudio[language=") for arg in cmd):
            (tmp_path / f"{old_zid}-test-video.ru.mp4").touch()

    monkeypatch.setattr(yd, "run_subprocess_streaming", mock_stream)

    success = yd.download_video_and_metadata(
        "https://youtube.com/watch?v=dQw4w9WgXcQ",
        settings,
        set(),
        {}
    )

    assert success
    assert all("--skip-download" not in cmd for cmd in seen_cmds)
    assert any(any(str(arg).startswith("bestaudio[language=") for arg in cmd) for cmd in seen_cmds)
    assert (tmp_path / f"{old_zid}-test-video.ru.mp4").exists()


def test_clean_srt_not_called_on_preexisting_subtitle(yd, tmp_path, monkeypatch):
    """Skip recovery: clean_srt_file must run only for newly downloaded subtitles."""
    old_zid = "20260527132904"
    existing_en = tmp_path / f"{old_zid}-test-video.en.srt"
    new_ru = tmp_path / f"{old_zid}-test-video.ru.srt"
    (tmp_path / f"{old_zid}-test-video.mp4").touch()
    existing_en.touch()

    settings = {
        "youtube_download_directory": str(tmp_path),
        "youtube_download_duplicate_mode": "skip",
        "youtube_download_chapters_mode": "embedded",
        "youtube_download_mode": "video+subtitles",
        "youtube_download_resolution": "360p",
        "youtube_download_subtitle_auto_fallback": True,
        "youtube_download_subtitle_languages": "en,ru",
        "youtube_download_companion_audio_languages": "",
        "youtube_download_sync_secondary_timestamps": False,
    }

    monkeypatch.setattr(yd, "run_ytdlp_info", lambda url: {
        "title": "Test Video",
        "language": "en",
        "subtitles": {"en": {}, "ru": {}},
        "chapters": [],
        "formats": [],
    })
    monkeypatch.setattr(yd, "get_unique_zid", lambda used: "99999999999999")

    def mock_stream(cmd, check=True, **kwargs):
        if "--skip-download" in cmd:
            new_ru.touch()

    monkeypatch.setattr(yd, "run_subprocess_streaming", mock_stream)

    cleaned_paths = []
    monkeypatch.setattr(yd, "clean_srt_file", lambda path, **kwargs: cleaned_paths.append(path))

    success = yd.download_video_and_metadata(
        "https://youtube.com/watch?v=dQw4w9WgXcQ",
        settings,
        set(),
        {}
    )

    assert success
    assert cleaned_paths == [new_ru]


def test_sync_fires_when_secondary_newly_downloaded_primary_preexisting(yd, tmp_path, monkeypatch):
    """Skip recovery: sync must run with ordered [primary pre-existing, secondary new]."""
    old_zid = "20260527132904"
    en_path = tmp_path / f"{old_zid}-test-video.en.srt"
    ru_path = tmp_path / f"{old_zid}-test-video.ru.srt"
    (tmp_path / f"{old_zid}-test-video.mp4").touch()
    en_path.touch()

    settings = {
        "youtube_download_directory": str(tmp_path),
        "youtube_download_duplicate_mode": "skip",
        "youtube_download_chapters_mode": "embedded",
        "youtube_download_mode": "video+subtitles",
        "youtube_download_resolution": "360p",
        "youtube_download_subtitle_auto_fallback": True,
        "youtube_download_subtitle_languages": "en,ru",
        "youtube_download_companion_audio_languages": "",
        "youtube_download_sync_secondary_timestamps": True,
    }

    monkeypatch.setattr(yd, "run_ytdlp_info", lambda url: {
        "title": "Test Video",
        "language": "en",
        "subtitles": {"en": {}, "ru": {}},
        "chapters": [],
        "formats": [],
    })
    monkeypatch.setattr(yd, "get_unique_zid", lambda used: "99999999999999")

    def mock_stream(cmd, check=True, **kwargs):
        if "--skip-download" in cmd:
            ru_path.touch()

    monkeypatch.setattr(yd, "run_subprocess_streaming", mock_stream)
    monkeypatch.setattr(yd, "clean_srt_file", lambda *args, **kwargs: None)

    sync_calls = []
    monkeypatch.setattr(yd, "sync_secondary_srt_timestamps", lambda primary, secondary: sync_calls.append((primary, secondary)))

    success = yd.download_video_and_metadata(
        "https://youtube.com/watch?v=dQw4w9WgXcQ",
        settings,
        set(),
        {}
    )

    assert success
    assert sync_calls == [(en_path, ru_path)]
