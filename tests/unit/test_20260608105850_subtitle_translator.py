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



