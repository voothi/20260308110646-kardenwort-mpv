"""
Feature ZID: 20260608105850
Feature: Subtitle Translator Unit Tests
"""

import json
import importlib.util
from pathlib import Path
import pytest
import urllib.request
import urllib.response
import io

_SCRIPT_PATH = (
    Path(__file__).resolve().parents[2]
    / "scripts"
    / "_tools"
    / "subtitle-translator"
    / "subtitle_translator.py"
)


def _load_translator():
    spec = importlib.util.spec_from_file_location("subtitle_translator_under_test", _SCRIPT_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_parse_filename():
    st = _load_translator()

    # ZID + Lang + Ext
    zid, clean, lang, ext = st.parse_filename(Path("20260608102024-title.en.srt"))
    assert zid == "20260608102024"
    assert clean == "title"
    assert lang == "en"
    assert ext == "srt"

    # ZID + Ext (No Lang)
    zid, clean, lang, ext = st.parse_filename(Path("20260608102024-title.srt"))
    assert zid == "20260608102024"
    assert clean == "title"
    assert lang is None
    assert ext == "srt"

    # Lang + Ext (No ZID)
    zid, clean, lang, ext = st.parse_filename(Path("title.ru.txt"))
    assert zid is None
    assert clean == "title"
    assert lang == "ru"
    assert ext == "txt"

    # Title + Ext only
    zid, clean, lang, ext = st.parse_filename(Path("title-only.srt"))
    assert zid is None
    assert clean == "title-only"
    assert lang is None
    assert ext == "srt"


def test_load_config_defaults_match_template(tmp_path, monkeypatch):
    st = _load_translator()

    monkeypatch.setattr(st, "CONFIG_FILE", tmp_path / "missing-config.ini")
    st._ZID_SCRIPT = ""

    settings = st.load_config()

    assert settings["subtitle_translator_rename_source_with_zid"] == "false"
    assert settings["subtitle_translator_word_count_check"] == "false"


def test_srt_parsing_and_writing():
    st = _load_translator()

    srt_content = (
        "1\n"
        "00:00:01,000 --> 00:00:04,000\n"
        "Hello world!\n"
        "How are you?\n"
        "\n"
        "2\n"
        "00:00:04,500 --> 00:00:07,000\n"
        "I am doing great.\n"
    )

    blocks = st.parse_srt(srt_content)
    assert len(blocks) == 2
    assert blocks[0]['index'] == "1"
    assert blocks[0]['timeline'] == "00:00:01,000 --> 00:00:04,000"
    assert blocks[0]['text_lines'] == ["Hello world!", "How are you?"]

    assert blocks[1]['index'] == "2"
    assert blocks[1]['timeline'] == "00:00:04,500 --> 00:00:07,000"
    assert blocks[1]['text_lines'] == ["I am doing great."]

    reconstructed = st.write_srt(blocks).replace("\r\n", "\n")
    assert reconstructed.strip() == srt_content.strip()


def test_google_translate_v1_mock(monkeypatch):
    st = _load_translator()

    mock_response_data = [[["Привет", "Hello", None, None, 10]]]
    mock_body = json.dumps(mock_response_data).encode("utf-8")

    class MockResponse:
        def __init__(self):
            pass
        def read(self):
            return mock_body
        def __enter__(self):
            return self
        def __exit__(self, *args):
            pass

    def mock_urlopen(req, timeout=None):
        return MockResponse()

    monkeypatch.setattr(urllib.request, "urlopen", mock_urlopen)

    res = st.google_translate_v1("Hello", "en", "ru", "https://translate.googleapis.com/translate_a/single")
    assert res == "Привет"


def test_translate_lines_with_fallback(monkeypatch):
    st = _load_translator()

    # Stub translation provider config
    settings = {
        "subtitle_translator_provider": "google",
        "google_api_url": "https://translate.googleapis.com/translate_a/single",
    }

    # Simulate different scenarios based on the input text
    def mock_google_translate(text, sl, tl, api_url):
        if text == "Hello\nWorld":
            # Correct chunk translation matching line counts
            return "Привет\nМир"
        elif text == "Fail\nChunk":
            # Returns a mismatch count (1 line instead of 2) to trigger line-by-line fallback
            return "Несоответствие"
        elif text == "Fail":
            return "Провал"
        elif text == "Chunk":
            return "Кусок"
        return "Переведено: " + text

    monkeypatch.setattr(st, "google_translate_v1", mock_google_translate)

    # 1. Successful chunk translation
    lines = ["Hello", "World"]
    translated = st.translate_lines(lines, "en", "ru", settings)
    assert translated == ["Привет", "Мир"]

    # 2. Chunk translation returns mismatched lines, triggers fallback to line-by-line
    lines_fallback = ["Fail", "Chunk"]
    translated_fallback = st.translate_lines(lines_fallback, "en", "ru", settings)
    assert translated_fallback == ["Провал", "Кусок"]


def test_process_file_idempotency_modes(tmp_path, monkeypatch):
    st = _load_translator()

    # Create dummy source subtitle file
    source_file = tmp_path / "20260608102024-title.en.srt"
    source_content = (
        "1\n"
        "00:00:01,000 --> 00:00:04,000\n"
        "Hello\n"
    )
    source_file.write_text(source_content, encoding="utf-8")

    # Mock translation calls
    monkeypatch.setattr(st, "translate_lines", lambda lines, sl, tl, settings: ["Привет"])

    # 1. Test "skip" duplicate mode (default)
    target_file = tmp_path / "20260608102024-title.ru.srt"
    target_file.write_text("existing russian translation", encoding="utf-8")

    settings_skip = {
        "subtitle_translator_source_language": "en",
        "subtitle_translator_target_languages": "ru",
        "subtitle_translator_provider": "google",
        "subtitle_translator_duplicate_mode": "skip",
        "google_api_url": "dummy",
    }

    ok = st.process_file(source_file, settings_skip, "20260608105552")
    assert ok is True
    # The existing target file should not have been overwritten or modified
    assert target_file.read_text(encoding="utf-8") == "existing russian translation"

    # 2. Test "archive" duplicate mode
    settings_archive = {
        "subtitle_translator_source_language": "en",
        "subtitle_translator_target_languages": "ru",
        "subtitle_translator_provider": "google",
        "subtitle_translator_duplicate_mode": "archive",
        "google_api_url": "dummy",
    }

    ok = st.process_file(source_file, settings_archive, "20260608105552")
    assert ok is True
    # Existing translation should have been moved to the ZID subdirectory
    archive_file = tmp_path / "20260608105552" / "20260608102024-title.ru.srt"
    assert archive_file.exists()
    assert archive_file.read_text(encoding="utf-8") == "existing russian translation"
    # A new translation should have been created at the original target_file path
    new_content = target_file.read_text(encoding="utf-8")
    assert "Привет" in new_content


def test_deepl_translate_v2_mock(monkeypatch):
    st = _load_translator()

    settings = {
        "deepl_api_key": "dummy-key",
        "deepl_api_url": "https://api-free.deepl.com/v2/translate",
        "deepl_formality": "default",
    }

    mock_response_data = {
        "translations": [
            {"detected_source_language": "EN", "text": "Привет"},
            {"detected_source_language": "EN", "text": "Мир"}
        ]
    }
    mock_body = json.dumps(mock_response_data).encode("utf-8")

    class MockResponse:
        def __init__(self):
            pass
        def read(self):
            return mock_body
        def __enter__(self):
            return self
        def __exit__(self, *args):
            pass

    def mock_urlopen(req, timeout=None):
        # Verify request parameters
        assert req.get_header("Authorization") == "DeepL-Auth-Key dummy-key"
        assert req.get_header("Content-type") == "application/x-www-form-urlencoded"
        # Decode body and verify keys
        body = req.data.decode("utf-8")
        assert "target_lang=RU" in body
        assert "source_lang=EN" in body
        assert "text=Hello" in body
        assert "text=World" in body
        return MockResponse()

    monkeypatch.setattr(urllib.request, "urlopen", mock_urlopen)

    res = st.deepl_translate_v2(["Hello", "World"], "en", "ru", settings)
    assert res == ["Привет", "Мир"]


def test_translate_lines_deepl(monkeypatch):
    st = _load_translator()

    settings = {
        "subtitle_translator_provider": "deepl",
        "deepl_api_key": "dummy-key",
        "deepl_api_url": "https://api-free.deepl.com/v2/translate",
        "deepl_formality": "default",
    }

    def mock_deepl(lines, sl, tl, s):
        assert sl == "en"
        assert tl == "ru"
        return [f"RU: {line}" for line in lines]

    monkeypatch.setattr(st, "deepl_translate_v2", mock_deepl)

    lines = ["First line", "", "Second line"]
    res = st.translate_lines(lines, "en", "ru", settings)
    assert res == ["RU: First line", "", "RU: Second line"]


def test_ollama_translate_generate_mock(monkeypatch):
    st = _load_translator()

    settings = {
        "ollama_api_url": "http://localhost:11434/api/generate",
        "ollama_model": "llama3",
        "ollama_prompt": "Translate {source_lang} to {target_lang}.",
    }

    mock_response_data = {"response": "Привет"}
    mock_body = json.dumps(mock_response_data).encode("utf-8")

    class MockResponse:
        def read(self):
            return mock_body
        def __enter__(self):
            return self
        def __exit__(self, *args):
            pass

    def mock_urlopen(req, timeout=None):
        body = json.loads(req.data.decode("utf-8"))
        assert body["model"] == "llama3"
        assert body["prompt"] == "Translate en to ru.\n\nHello"
        assert body["stream"] is False
        return MockResponse()

    monkeypatch.setattr(urllib.request, "urlopen", mock_urlopen)

    res = st.ollama_translate("Hello", "en", "ru", settings)
    assert res == "Привет"


def test_ollama_translate_chat_mock(monkeypatch):
    st = _load_translator()

    settings = {
        "ollama_api_url": "http://localhost:11434/v1/chat/completions",
        "ollama_model": "llama3",
        "ollama_prompt": "Translate {source_lang} to {target_lang}.",
    }

    mock_response_data = {
        "choices": [
            {
                "message": {
                    "content": "Мир"
                }
            }
        ]
    }
    mock_body = json.dumps(mock_response_data).encode("utf-8")

    class MockResponse:
        def read(self):
            return mock_body
        def __enter__(self):
            return self
        def __exit__(self, *args):
            pass

    def mock_urlopen(req, timeout=None):
        body = json.loads(req.data.decode("utf-8"))
        assert body["model"] == "llama3"
        assert body["messages"] == [{"role": "user", "content": "Translate en to ru.\n\nWorld"}]
        assert body["stream"] is False
        return MockResponse()

    monkeypatch.setattr(urllib.request, "urlopen", mock_urlopen)

    res = st.ollama_translate("World", "en", "ru", settings)
    assert res == "Мир"


def test_translate_lines_ollama(monkeypatch):
    st = _load_translator()

    settings = {
        "subtitle_translator_provider": "ollama",
        "ollama_api_url": "http://localhost:11434/api/generate",
        "ollama_model": "llama3",
        "ollama_prompt": "Translate {source_lang} to {target_lang}.",
    }

    def mock_ollama(text, sl, tl, s):
        assert sl == "en"
        assert tl == "ru"
        # Mock translation output returning multiple lines corresponding to input lines
        if text == "Line one\nLine two":
            return "RU: Line one\nRU: Line two"
        return "RU: Single"

    monkeypatch.setattr(st, "ollama_translate", mock_ollama)

    lines = ["Line one", "Line two"]
    res = st.translate_lines(lines, "en", "ru", settings)
    assert res == ["RU: Line one", "RU: Line two"]


def test_make_translation_progress_bar():
    st = _load_translator()
    bar = st.make_translation_progress_bar(10, 20)
    assert "10/20 lines (50.0%)" in st.strip_ansi(bar)
    assert "━" in bar


def test_translate_lines_validation_success(monkeypatch):
    st = _load_translator()

    settings = {
        "subtitle_translator_provider": "google",
        "google_api_url": "dummy",
        "subtitle_translator_chunk_size": "2",
        "subtitle_translator_max_retries": "2",
        "subtitle_translator_word_count_check": "true",
        "subtitle_translator_word_count_min_ratio": "0.5",
        "subtitle_translator_word_count_max_ratio": "2.0",
    }

    # Successful translation matching line count and word counts
    def mock_translate(text, sl, tl, api_url):
        if text == "Hello\nWorld":
            return "Привет\nМир"
        return "Перевод"

    monkeypatch.setattr(st, "google_translate_v1", mock_translate)

    lines = ["Hello", "World"]
    res = st.translate_lines(lines, "en", "ru", settings)
    assert res == ["Привет", "Мир"]


def test_translate_lines_validation_retry_and_success(monkeypatch):
    st = _load_translator()

    settings = {
        "subtitle_translator_provider": "google",
        "google_api_url": "dummy",
        "subtitle_translator_chunk_size": "2",
        "subtitle_translator_max_retries": "3",
        "subtitle_translator_word_count_check": "false",
    }

    call_count = 0

    def mock_translate(text, sl, tl, api_url):
        nonlocal call_count
        call_count += 1
        if call_count == 1:
            # Mismatched line count on first attempt
            return "Mismatched Line"
        # Correct line count on second attempt
        return "Привет\nМир"

    monkeypatch.setattr(st, "google_translate_v1", mock_translate)
    # Patch time.sleep to run quickly
    monkeypatch.setattr(st.time, "sleep", lambda x: None)

    lines = ["Hello", "World"]
    res = st.translate_lines(lines, "en", "ru", settings)
    assert res == ["Привет", "Мир"]
    assert call_count == 2


def test_translate_lines_validation_failure_crash(monkeypatch):
    st = _load_translator()

    settings = {
        "subtitle_translator_provider": "google",
        "google_api_url": "dummy",
        "subtitle_translator_chunk_size": "2",
        "subtitle_translator_max_retries": "3",
        "subtitle_translator_word_count_check": "false",
    }

    # Always return invalid translation
    def mock_translate(text, sl, tl, api_url):
        return "Mismatch"

    monkeypatch.setattr(st, "google_translate_v1", mock_translate)
    monkeypatch.setattr(st.time, "sleep", lambda x: None)

    lines = ["Hello", "World"]
    with pytest.raises(st.ChunkValidationError) as exc_info:
        st.translate_lines(lines, "en", "ru", settings)
    
    assert "Chunk validation failed after 3 attempts" in str(exc_info.value)
    # ChunkValidationError must carry partial_lines
    assert hasattr(exc_info.value, "partial_lines")
    # Failed lines must be empty strings, not original source text
    assert exc_info.value.partial_lines[0] == ""
    assert exc_info.value.partial_lines[1] == ""


def test_translate_lines_word_count_check(monkeypatch):
    st = _load_translator()

    settings = {
        "subtitle_translator_provider": "google",
        "google_api_url": "dummy",
        "subtitle_translator_chunk_size": "1",
        "subtitle_translator_max_retries": "2",
        "subtitle_translator_word_count_check": "true",
        "subtitle_translator_word_count_min_ratio": "0.5",
        "subtitle_translator_word_count_max_ratio": "2.0",
    }

    # Case 1: Translation is too long (hallucination)
    def mock_translate_long(text, sl, tl, api_url):
        return "This is a very long translation that should definitely fail validation checks because it has many words"

    monkeypatch.setattr(st, "google_translate_v1", mock_translate_long)
    monkeypatch.setattr(st.time, "sleep", lambda x: None)

    # "Hello" is 1 word, the mock translation is 17 words. This exceeds absolute diff of 5 and max_ratio of 2.0.
    lines = ["Hello"]
    with pytest.raises(RuntimeError) as exc_info:
        st.translate_lines(lines, "en", "ru", settings)
    assert "Chunk validation failed" in str(exc_info.value)

    # Case 2: Translation is within absolute difference tolerance (<= 5 words diff) even if ratio is high
    # "Hello" is 1 word, mock returns "Привет дорогой друг" (3 words). Absolute diff is 2, which is <= 5, so it should pass.
    def mock_translate_short(text, sl, tl, api_url):
        return "Привет дорогой друг"

    monkeypatch.setattr(st, "google_translate_v1", mock_translate_short)
    res = st.translate_lines(lines, "en", "ru", settings)
    assert res == ["Привет дорогой друг"]


def test_process_file_rollback_on_failure(tmp_path, monkeypatch):
    st = _load_translator()

    # Create dummy subtitle file without ZID
    source_file = tmp_path / "telc-eng-b2.srt"
    source_file.write_text("1\n00:00:01,000 --> 00:00:04,000\nHello\n", encoding="utf-8")

    # Mock translation to fail validation
    def mock_translate_fail(lines, sl, tl, settings):
        raise RuntimeError("Validation failed")

    monkeypatch.setattr(st, "translate_lines", mock_translate_fail)

    settings = {
        "subtitle_translator_source_language": "en",
        "subtitle_translator_target_languages": "ru",
        "subtitle_translator_provider": "google",
        "google_api_url": "dummy",
        "subtitle_translator_rename_source_with_zid": "true",
    }

    # Execute and check it returns False
    ok = st.process_file(source_file, settings, "session-zid")
    assert ok is False

    # Check that the source file name has been rolled back to its original name
    assert source_file.exists()
    assert (tmp_path / "telc-eng-b2.srt").exists()

    # Verify that the renamed ZID file does not exist anymore
    # The renamed ZID file should have been cleaned up/rolled back
    zid_files = list(tmp_path.glob("*-telc-eng-b2.en.srt"))
    assert len(zid_files) == 0


def test_process_file_partial_save(tmp_path, monkeypatch):
    st = _load_translator()

    # Three-line SRT with first line already translated, rest fails
    srt_content = (
        "1\n00:00:01,000 --> 00:00:02,000\nHello\n\n"
        "2\n00:00:02,000 --> 00:00:03,000\nWorld\n\n"
        "3\n00:00:03,000 --> 00:00:04,000\nGoodbye\n"
    )
    source_file = tmp_path / "20260608000000-test.en.srt"
    source_file.write_text(srt_content, encoding="utf-8")

    def mock_translate(lines, sl, tl, settings):
        """First line translated; lines 2-3 failed (empty strings = blank subtitles)."""
        raise st.ChunkValidationError(
            "Chunk validation failed after 3 attempts for lines 2 to 3.",
            ["Привет", "", ""]  # first translated, failed chunks are blank
        )

    monkeypatch.setattr(st, "translate_lines", mock_translate)

    settings = {
        "subtitle_translator_source_language": "en",
        "subtitle_translator_target_languages": "ru",
        "subtitle_translator_provider": "google",
        "google_api_url": "dummy",
        "subtitle_translator_duplicate_mode": "overwrite",
        "subtitle_translator_save_partial_on_failure": "true",
    }

    ok = st.process_file(source_file, settings, "session-zid")
    assert ok is False  # Overall failure

    # Target file should have been written with partial content
    target_file = tmp_path / "20260608000000-test.ru.srt"
    assert target_file.exists()
    content = target_file.read_text(encoding="utf-8")
    # First translated subtitle must be in Russian
    assert "Привет" in content
    # Failed chunks must NOT contain original English text
    assert "World" not in content
    assert "Goodbye" not in content
    # Timecodes for all blocks must still be present
    assert "00:00:02,000 --> 00:00:03,000" in content
    assert "00:00:03,000 --> 00:00:04,000" in content


def test_process_file_archive_preserves_existing_on_failure(tmp_path, monkeypatch):
    st = _load_translator()

    source_file = tmp_path / "20260608000000-test.en.srt"
    source_file.write_text("1\n00:00:01,000 --> 00:00:02,000\nHello\n", encoding="utf-8")
    target_file = tmp_path / "20260608000000-test.ru.srt"
    target_file.write_text("existing translation", encoding="utf-8")

    monkeypatch.setattr(st, "translate_lines", lambda lines, sl, tl, settings: (_ for _ in ()).throw(RuntimeError("boom")))

    settings = {
        "subtitle_translator_source_language": "en",
        "subtitle_translator_target_languages": "ru",
        "subtitle_translator_provider": "google",
        "google_api_url": "dummy",
        "subtitle_translator_duplicate_mode": "archive",
    }

    ok = st.process_file(source_file, settings, "session-zid")
    assert ok is False
    assert target_file.exists()
    assert target_file.read_text(encoding="utf-8") == "existing translation"
    assert not (tmp_path / "session-zid" / "20260608000000-test.ru.srt").exists()


def test_process_file_partial_save_skip_preserves_existing_target(tmp_path, monkeypatch):
    st = _load_translator()

    source_file = tmp_path / "20260608000000-test.en.srt"
    source_file.write_text("1\n00:00:01,000 --> 00:00:02,000\nHello\n", encoding="utf-8")
    target_file = tmp_path / "20260608000000-test.ru.srt"

    def mock_translate(lines, sl, tl, settings):
        target_file.write_text("existing translation", encoding="utf-8")
        raise st.ChunkValidationError("Chunk validation failed.", [""])

    monkeypatch.setattr(st, "translate_lines", mock_translate)

    settings = {
        "subtitle_translator_source_language": "en",
        "subtitle_translator_target_languages": "ru",
        "subtitle_translator_provider": "google",
        "google_api_url": "dummy",
        "subtitle_translator_duplicate_mode": "skip",
        "subtitle_translator_save_partial_on_failure": "true",
    }

    ok = st.process_file(source_file, settings, "session-zid")
    assert ok is False
    assert target_file.read_text(encoding="utf-8") == "existing translation"


def test_process_file_rolls_back_related_media_on_failure(tmp_path, monkeypatch):
    st = _load_translator()

    source_file = tmp_path / "movie.srt"
    media_file = tmp_path / "movie.mp3"
    source_file.write_text("1\n00:00:01,000 --> 00:00:02,000\nHello\n", encoding="utf-8")
    media_file.write_text("audio", encoding="utf-8")

    monkeypatch.setattr(st, "get_current_zid", lambda: "20260608160000")
    monkeypatch.setattr(st, "translate_lines", lambda lines, sl, tl, settings: (_ for _ in ()).throw(RuntimeError("boom")))

    settings = {
        "subtitle_translator_source_language": "en",
        "subtitle_translator_target_languages": "ru",
        "subtitle_translator_provider": "google",
        "google_api_url": "dummy",
        "subtitle_translator_rename_source_with_zid": "true",
        "subtitle_translator_rename_related_media_with_zid": "true",
    }

    ok = st.process_file(source_file, settings, "session-zid")
    assert ok is False
    assert source_file.exists()
    assert media_file.exists()
    assert not list(tmp_path.glob("20260608160000-*"))


def test_process_file_rejects_invalid_duplicate_mode(tmp_path, monkeypatch):
    st = _load_translator()

    source_file = tmp_path / "20260608000000-test.en.srt"
    source_file.write_text("1\n00:00:01,000 --> 00:00:02,000\nHello\n", encoding="utf-8")

    def fail_if_called(*args, **kwargs):
        raise AssertionError("translate_lines should not be called for invalid duplicate mode")

    monkeypatch.setattr(st, "translate_lines", fail_if_called)

    settings = {
        "subtitle_translator_source_language": "en",
        "subtitle_translator_target_languages": "ru",
        "subtitle_translator_provider": "google",
        "google_api_url": "dummy",
        "subtitle_translator_duplicate_mode": "surprise",
    }

    ok = st.process_file(source_file, settings, "session-zid")
    assert ok is False
    assert not (tmp_path / "20260608000000-test.ru.srt").exists()


def test_main_loads_config_before_generating_session_zid(monkeypatch):
    st = _load_translator()
    call_order = []

    def fake_load_config():
        call_order.append("load")
        st._ZID_SCRIPT = "configured-script"
        return {
            "subtitle_translator_provider": "google",
            "subtitle_translator_duplicate_mode": "skip",
            "subtitle_translator_target_languages": "ru",
            "youtube_download_auto_close_timeout_secs": "15",
        }

    def fake_get_current_zid():
        call_order.append("zid")
        assert st._ZID_SCRIPT == "configured-script"
        return "20260608170000"

    monkeypatch.setattr(st, "load_config", fake_load_config)
    monkeypatch.setattr(st, "get_current_zid", fake_get_current_zid)
    monkeypatch.setattr(st.sys, "argv", ["subtitle_translator.py"])

    with pytest.raises(SystemExit):
        st.main()

    assert call_order[:2] == ["load", "zid"]
