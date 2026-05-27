"""
Feature ZID: 20260527132904
Feature: YouTube Downloader
Unit tests for YouTube URL detection, ZID generation, title sanitization, and configuration.
"""

import configparser
import importlib.util
from pathlib import Path
import pytest
import time

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


def test_sanitize_title_rules():
    yd = _load_downloader()
    
    # German umlauts and punctuation
    assert yd.sanitize_title("Müller & Söhne: Eine große Geschichte.") == "mueller-soehne-eine-grosse"
    # Word limit (4 words)
    assert yd.sanitize_title("One Two Three Four Five Six") == "one-two-three-four"
    # Special character filtering and lowercase
    assert yd.sanitize_title("Test! @#$ Video Title%^&*()_+") == "test-video-title"


def test_youtube_url_detection():
    yd = _load_downloader()
    
    # Test regex directly
    pattern = yd.YOUTUBE_URL_REGEX
    assert pattern.match("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    assert pattern.match("https://youtu.be/dQw4w9WgXcQ")
    assert pattern.match("https://m.youtube.com/watch?v=dQw4w9WgXcQ")
    assert pattern.match("https://www.youtube.com/shorts/tPEE9AMyJps")
    
    # Test extract from text file contents
    content = (
        "Here is a link: https://www.youtube.com/watch?v=abc12345678\n"
        "And another one: https://youtu.be/xyz98765432 and some text.\n"
        "Non-matching: https://google.com\n"
    )
    
    # Monkeypatch file reading for test
    def mock_open(*args, **kwargs):
        class MockFile:
            def __enter__(self):
                return self
            def __exit__(self, *args):
                pass
            def read(self):
                return content
        return MockFile()
        
    import builtins
    original_open = builtins.open
    builtins.open = mock_open
    try:
        urls = yd.extract_urls_from_file("dummy_path")
        assert len(urls) == 2
        assert urls[0] == "https://www.youtube.com/watch?v=abc12345678"
        assert urls[1] == "https://youtu.be/xyz98765432"
    finally:
        builtins.open = original_open


def test_get_ytdlp_format():
    yd = _load_downloader()
    
    # Resolution parsing and mapping
    assert yd.get_ytdlp_format("360p") == "bestvideo[height<=360]+bestaudio/best[height<=360]/bestvideo+bestaudio/best"
    assert yd.get_ytdlp_format("720p") == "bestvideo[height<=720]+bestaudio/best[height<=720]/bestvideo+bestaudio/best"
    assert yd.get_ytdlp_format("1080p") == "bestvideo[height<=1080]+bestaudio/best[height<=1080]/bestvideo+bestaudio/best"
    assert yd.get_ytdlp_format("best") == "bestvideo+bestaudio/best"


def test_unique_zid_generation_and_collision_guard(monkeypatch):
    yd = _load_downloader()
    
    # Mock time.strftime to simulate collision
    tick_count = 0
    def mock_strftime(fmt):
        nonlocal tick_count
        # Return same time for first two calls, then increment
        if tick_count < 2:
            val = "20260527132904"
        else:
            val = "20260527132905"
        tick_count += 1
        return val
        
    monkeypatch.setattr(time, "strftime", mock_strftime)
    monkeypatch.setattr(time, "sleep", lambda secs: None) # speed up test
    
    used_zids = set()
    zid1 = yd.get_unique_zid(used_zids)
    zid2 = yd.get_unique_zid(used_zids)
    
    assert zid1 == "20260527132904"
    assert zid2 == "20260527132905"
    assert zid1 != zid2


def test_get_current_zid(monkeypatch):
    yd = _load_downloader()
    
    # 1. Success case: subprocess returns mock ZID.
    #    _ZID_SCRIPT must be non-empty for get_current_zid() to call subprocess
    #    (in tests load_config() is not called, so we set it directly).
    yd._ZID_SCRIPT = "/path/to/zid_script"
    class MockCompletedProcess:
        def __init__(self):
            self.stdout = "20260527141526\n"
            
    monkeypatch.setattr(yd.subprocess, "run", lambda *args, **kwargs: MockCompletedProcess())
    assert yd.get_current_zid() == "20260527141526"
    
    # 2. Failure fallback: subprocess raises, returns time.strftime
    def mock_run_error(*args, **kwargs):
        raise RuntimeError("ZID script failed")
        
    monkeypatch.setattr(yd.subprocess, "run", mock_run_error)
    monkeypatch.setattr(yd.time, "strftime", lambda fmt: "99991231235959")
    assert yd.get_current_zid() == "99991231235959"

    # 3. No script configured: falls back immediately without calling subprocess
    monkeypatch.setattr(yd, "_ZID_SCRIPT", "")
    monkeypatch.setattr(yd.time, "strftime", lambda fmt: "00000000000000")
    assert yd.get_current_zid() == "00000000000000"


def test_clean_srt_file(tmp_path):
    yd = _load_downloader()
    
    # Simulating the real-world bug where there is a blank line between timestamp and text
    dirty_content = (
        "1\n"
        "00:00:02,160 --> 00:00:04,470\n"
        "\n"
        "On Tuesday, May 19th, thousands of\n"
        "\n"
        "2\n"
        "00:00:04,470 --> 00:00:04,480\n"
        "On Tuesday, May 19th, thousands of\n"
        "\n"
        "3\n"
        "00:00:04,480 --> 00:00:06,270\n"
        "On Tuesday, May 19th, thousands of\n"
        "\n"
        "developers opened their computers and\n"
        "\n"
        "4\n"
        "00:00:06,270 --> 00:00:06,280\n"
        "\n"
        "developers opened their computers and\n"
        "\n"
        "5\n"
        "00:00:06,280 --> 00:00:07,950\n"
        "developers opened their computers and\n"
        "found their code editors had basically\n"
    )
    
    sub_file = tmp_path / "test.srt"
    sub_file.write_text(dirty_content, encoding="utf-8")
    
    yd.clean_srt_file(sub_file)
    
    cleaned = sub_file.read_text(encoding="utf-8").replace("\r\n", "\n")
    
    expected = (
        "1\n"
        "00:00:02,160 --> 00:00:04,480\n"
        "On Tuesday, May 19th, thousands of\n"
        "\n"
        "2\n"
        "00:00:04,480 --> 00:00:06,280\n"
        "developers opened their computers and\n"
        "\n"
        "3\n"
        "00:00:06,280 --> 00:00:07,950\n"
        "found their code editors had basically\n"
    )
    
    assert cleaned.strip() == expected.strip()


def test_clean_srt_file_clean_hyphens(tmp_path):
    yd = _load_downloader()
    
    content = (
        "1\n"
        "00:00:02,160 --> 00:00:04,470\n"
        "- On Tuesday, May 19th, thousands of\n"
        "\n"
        "2\n"
        "00:00:04,470 --> 00:00:06,270\n"
        "— developers opened their computers and\n"
    )
    
    sub_file = tmp_path / "test_hyphens.srt"
    sub_file.write_text(content, encoding="utf-8")
    
    yd.clean_srt_file(sub_file, clean_hyphens=True)
    
    cleaned = sub_file.read_text(encoding="utf-8").replace("\r\n", "\n")
    
    expected = (
        "1\n"
        "00:00:02,160 --> 00:00:04,470\n"
        "On Tuesday, May 19th, thousands of\n"
        "\n"
        "2\n"
        "00:00:04,470 --> 00:00:06,270\n"
        "developers opened their computers and\n"
    )
    
    assert cleaned.strip() == expected.strip()


def test_clean_srt_file_unbreak_lines(tmp_path):
    yd = _load_downloader()
    
    content = (
        "1\n"
        "00:00:02,160 --> 00:00:04,470\n"
        "On Tuesday, May 19th,\n"
        "thousands of\n"
        "\n"
        "2\n"
        "00:00:04,470 --> 00:00:06,270\n"
        "developers opened\n"
        "their computers and\n"
    )
    
    sub_file = tmp_path / "test_unbreak.srt"
    sub_file.write_text(content, encoding="utf-8")
    
    yd.clean_srt_file(sub_file, unbreak_lines=True)
    
    cleaned = sub_file.read_text(encoding="utf-8").replace("\r\n", "\n")
    
    expected = (
        "1\n"
        "00:00:02,160 --> 00:00:04,470\n"
        "On Tuesday, May 19th, thousands of\n"
        "\n"
        "2\n"
        "00:00:04,470 --> 00:00:06,270\n"
        "developers opened their computers and\n"
    )
    
    assert cleaned.strip() == expected.strip()


def test_clean_srt_file_both(tmp_path):
    yd = _load_downloader()
    
    content = (
        "1\n"
        "00:00:02,160 --> 00:00:04,470\n"
        "- On Tuesday, May 19th,\n"
        "thousands of\n"
        "\n"
        "2\n"
        "00:00:04,470 --> 00:00:06,270\n"
        "This is an inter-\n"
        "national agreement.\n"
        "\n"
        "3\n"
        "00:00:06,270 --> 00:00:08,000\n"
        "Es gibt Erst-\n"
        "und Zweitleser.\n"
    )
    
    sub_file = tmp_path / "test_both.srt"
    sub_file.write_text(content, encoding="utf-8")
    
    yd.clean_srt_file(sub_file, clean_hyphens=True, unbreak_lines=True)
    
    cleaned = sub_file.read_text(encoding="utf-8").replace("\r\n", "\n")
    
    expected = (
        "1\n"
        "00:00:02,160 --> 00:00:04,470\n"
        "On Tuesday, May 19th, thousands of\n"
        "\n"
        "2\n"
        "00:00:04,470 --> 00:00:06,270\n"
        "This is an international agreement.\n"
        "\n"
        "3\n"
        "00:00:06,270 --> 00:00:08,000\n"
        "Es gibt Erst- und Zweitleser.\n"
    )
    
    assert cleaned.strip() == expected.strip()


def test_sync_secondary_srt_timestamps(tmp_path):
    yd = _load_downloader()

    primary_content = (
        "1\n"
        "00:00:01,000 --> 00:00:02,000\n"
        "Hello world\n"
        "\n"
        "2\n"
        "00:00:02,000 --> 00:00:04,000\n"
        "How are you\n"
        "\n"
        "3\n"
        "00:00:04,000 --> 00:00:06,000\n"
        "Goodbye\n"
    )
    # Secondary has same 3 blocks but desynchronised timestamps
    secondary_content = (
        "1\n"
        "00:00:01,500 --> 00:00:03,000\n"
        "Привет мир\n"
        "\n"
        "2\n"
        "00:00:03,000 --> 00:00:05,500\n"
        "Как дела\n"
        "\n"
        "3\n"
        "00:00:05,500 --> 00:00:07,500\n"
        "Пока\n"
    )
    primary_file = tmp_path / "video.en.srt"
    secondary_file = tmp_path / "video.ru.srt"
    primary_file.write_text(primary_content, encoding="utf-8")
    secondary_file.write_text(secondary_content, encoding="utf-8")

    yd.sync_secondary_srt_timestamps(primary_file, secondary_file)

    result = secondary_file.read_text(encoding="utf-8")
    assert "00:00:01,000 --> 00:00:02,000" in result
    assert "00:00:02,000 --> 00:00:04,000" in result
    assert "00:00:04,000 --> 00:00:06,000" in result
    assert "Привет мир" in result
    assert "Как дела" in result
    assert "Пока" in result
    assert "00:00:01,500" not in result
    assert "00:00:05,500 --> 00:00:07,500" not in result


def test_sync_secondary_srt_timestamps_different_counts(tmp_path):
    yd = _load_downloader()

    # Primary: 2 blocks; Secondary: 3 blocks.
    # Time-based matching keeps all 3 secondary blocks:
    #   RU block 1 (01:500) -> closest EN block 1 (01:000)
    #   RU block 2 (03:000) -> closest EN block 2 (02:000)
    #   RU block 3 (05:000) -> maps to EN block 2 (clamped by monotonic progress)
    primary_content = (
        "1\n"
        "00:00:01,000 --> 00:00:02,000\n"
        "Block one\n"
        "\n"
        "2\n"
        "00:00:02,000 --> 00:00:04,000\n"
        "Block two\n"
    )
    secondary_content = (
        "1\n"
        "00:00:01,500 --> 00:00:03,000\n"
        "Блок один\n"
        "\n"
        "2\n"
        "00:00:03,000 --> 00:00:05,000\n"
        "Блок два\n"
        "\n"
        "3\n"
        "00:00:05,000 --> 00:00:07,000\n"
        "Блок три\n"
    )
    primary_file = tmp_path / "video.en.srt"
    secondary_file = tmp_path / "video.ru.srt"
    primary_file.write_text(primary_content, encoding="utf-8")
    secondary_file.write_text(secondary_content, encoding="utf-8")

    yd.sync_secondary_srt_timestamps(primary_file, secondary_file)

    result = secondary_file.read_text(encoding="utf-8")
    # All 3 secondary blocks are preserved (not trimmed)
    assert result.count("-->") == 3
    assert "00:00:01,000 --> 00:00:02,000" in result
    assert "00:00:02,000 --> 00:00:04,000" in result
    assert "Блок один" in result
    assert "Блок два" in result
    assert "Блок три" in result
    # Old secondary timestamps must not appear
    assert "00:00:01,500" not in result
    assert "00:00:05,000 --> 00:00:07,000" not in result


def test_sync_secondary_srt_timestamps_missing_file(tmp_path):
    yd = _load_downloader()
    # Must not raise when the secondary file does not exist
    primary_file = tmp_path / "video.en.srt"
    primary_file.write_text("1\n00:00:01,000 --> 00:00:02,000\nHello\n", encoding="utf-8")
    missing = tmp_path / "video.ru.srt"
    yd.sync_secondary_srt_timestamps(primary_file, missing)  # must not raise
