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
        assert body["prompt"] == "Translate English to Russian.\n\nHello"
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
        assert body["messages"] == [{"role": "user", "content": "Translate English to Russian.\n\nWorld"}]
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


def test_format_validation_error_for_log_compacts_model_response():
    st = _load_translator()

    error = RuntimeError(
        "Ollama request failed: Line count mismatch in structured JSON "
        "(expected 3, got 1). Response was: {\n"
        '"translations": ["one", "two", "three"]\n'
        "}"
    )

    summary, response = st.format_validation_error_for_log(error)

    assert summary == "Ollama request failed: Line count mismatch in structured JSON (expected 3, got 1)"
    assert response == '{\\n"translations": ["one", "two", "three"]\\n}'


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
    """When chunk retries AND the single-line rescue both fail, ChunkValidationError is raised."""
    st = _load_translator()

    settings = {
        "subtitle_translator_provider": "google",
        "google_api_url": "dummy",
        "subtitle_translator_chunk_size": "2",
        "subtitle_translator_max_retries": "3",
        "subtitle_translator_word_count_check": "false",
    }

    # Chunk call → returns wrong line count; single-line rescue call → returns empty string
    call_counts = {"n": 0}

    def mock_translate(text, sl, tl, api_url):
        call_counts["n"] += 1
        if "\n" in text:
            # Chunk call: return a single-item mismatch
            return "Mismatch"
        else:
            # Single-line rescue: return empty → triggers "Empty result" guard
            return ""

    monkeypatch.setattr(st, "google_translate_v1", mock_translate)
    monkeypatch.setattr(st.time, "sleep", lambda x: None)

    lines = ["Hello", "World"]
    with pytest.raises(st.ChunkValidationError) as exc_info:
        st.translate_lines(lines, "en", "ru", settings)

    assert "failed" in str(exc_info.value).lower()
    assert hasattr(exc_info.value, "partial_lines")


def test_translate_lines_rescue_pass_on_chunk_failure(monkeypatch):
    """When chunk retries fail but the single-line rescue succeeds, translation completes without error."""
    st = _load_translator()

    settings = {
        "subtitle_translator_provider": "google",
        "google_api_url": "dummy",
        "subtitle_translator_chunk_size": "3",
        "subtitle_translator_max_retries": "2",
        "subtitle_translator_word_count_check": "false",
    }

    def mock_translate(text, sl, tl, api_url):
        if "\n" in text:
            # Chunk call always returns mismatch (1 line instead of 3)
            return "BadChunkResult"
        # Single-line rescue — translate correctly
        return f"[{text}]"

    monkeypatch.setattr(st, "google_translate_v1", mock_translate)
    monkeypatch.setattr(st.time, "sleep", lambda x: None)

    lines = ["Hello", "World", "Goodbye"]
    result = st.translate_lines(lines, "en", "ru", settings)

    # Rescue should have handled all three lines individually
    assert result == ["[Hello]", "[World]", "[Goodbye]"]


def test_translate_lines_validation_output_clean_by_default(monkeypatch, capsys):
    st = _load_translator()

    settings = {
        "subtitle_translator_provider": "google",
        "google_api_url": "dummy",
        "subtitle_translator_chunk_size": "2",
        "subtitle_translator_max_retries": "1",
        "subtitle_translator_word_count_check": "false",
        "subtitle_translator_verbose_validation_errors": "false",
    }

    def mock_translate(text, sl, tl, api_url):
        if "\n" in text:
            raise RuntimeError("Line count mismatch. Response was: {very noisy model response}")
        return f"[{text}]"

    monkeypatch.setattr(st, "google_translate_v1", mock_translate)
    monkeypatch.setattr(st.time, "sleep", lambda x: None)

    assert st.translate_lines(["Hello", "World"], "en", "ru", settings) == ["[Hello]", "[World]"]

    output = capsys.readouterr().out
    assert "Model response:" not in output
    assert "[RESCUE] Chunk validation failed after 1 attempts for lines 1 to 2" in output
    assert "Line 1 rescued" in output
    assert "Rescued line 1:" not in output


def test_translate_lines_validation_output_verbose(monkeypatch, capsys):
    st = _load_translator()

    settings = {
        "subtitle_translator_provider": "google",
        "google_api_url": "dummy",
        "subtitle_translator_chunk_size": "2",
        "subtitle_translator_max_retries": "1",
        "subtitle_translator_word_count_check": "false",
        "subtitle_translator_verbose_validation_errors": "true",
    }

    def mock_translate(text, sl, tl, api_url):
        if "\n" in text:
            raise RuntimeError("Line count mismatch. Response was: {very noisy model response}")
        return f"[{text}]"

    monkeypatch.setattr(st, "google_translate_v1", mock_translate)
    monkeypatch.setattr(st.time, "sleep", lambda x: None)

    assert st.translate_lines(["Hello", "World"], "en", "ru", settings) == ["[Hello]", "[World]"]

    output = capsys.readouterr().out
    assert "Model response: {very noisy model response}" in output
    assert "Rescued line 1:" in output


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
    with pytest.raises(st.ChunkValidationError) as exc_info:
        st.translate_lines(lines, "en", "ru", settings)
    assert "rescue pass failed" in str(exc_info.value)
    assert exc_info.value.partial_lines == [""]

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


def test_normalize_media_title():
    st = _load_translator()
    assert st.normalize_media_title("Telc-Eng-B2") == "telcengb2"
    assert st.normalize_media_title("Movie (2026)!") == "movie2026"


def test_find_related_media_files(tmp_path):
    st = _load_translator()

    # Create dummy files
    (tmp_path / "movie.en.srt").write_text("dummy srt", encoding="utf-8")
    mp4_file = tmp_path / "movie.mp4"
    mp4_file.write_text("dummy video", encoding="utf-8")

    # 1. Exact match test
    matches = st.find_related_media_files(tmp_path, "movie")
    assert len(matches) == 1
    assert matches[0] == mp4_file

    # 2. Case-insensitive / normalized match test
    mp3_file = tmp_path / "MOVIE-AUDIO.mp3"
    mp3_file.write_text("dummy audio", encoding="utf-8")
    matches_normalized = st.find_related_media_files(tmp_path, "movie-audio")
    assert len(matches_normalized) == 1
    assert matches_normalized[0] == mp3_file

    # 3. Single-file fallback test
    # Delete movie.mp4 and MOVIE-AUDIO.mp3, leave only one media file
    mp4_file.unlink()
    matches_single = st.find_related_media_files(tmp_path, "unrelated-title")
    assert len(matches_single) == 1
    assert matches_single[0] == mp3_file


def test_process_file_txt_format(tmp_path, monkeypatch):
    st = _load_translator()

    source_file = tmp_path / "20260608000000-notes.en.txt"
    source_file.write_text("Hello\nWorld\n", encoding="utf-8")

    monkeypatch.setattr(st, "translate_lines", lambda lines, sl, tl, settings: ["Привет", "Мир"])

    settings = {
        "subtitle_translator_source_language": "en",
        "subtitle_translator_target_languages": "ru",
        "subtitle_translator_provider": "google",
        "google_api_url": "dummy",
        "subtitle_translator_duplicate_mode": "overwrite",
    }

    ok = st.process_file(source_file, settings, "session-zid")
    assert ok is True

    target_file = tmp_path / "20260608000000-notes.ru.txt"
    assert target_file.exists()
    content = target_file.read_text(encoding="utf-8")
    assert content.replace("\r\n", "\n") == "Привет\nМир"


def test_get_prompt_salt():
    st = _load_translator()
    # 1. Test "Make it [much] better"
    phrase = "Make it [much] better"
    assert st.get_prompt_salt(phrase, 1) == ""
    assert st.get_prompt_salt(phrase, 2) == "Make it much better"
    assert st.get_prompt_salt(phrase, 3) == "Make it much, much better"
    assert st.get_prompt_salt(phrase, 4) == "Make it much, much, much better"

    # 2. Test "Сделай [намного] лучше"
    phrase2 = "Сделай [намного] лучше"
    assert st.get_prompt_salt(phrase2, 2) == "Сделай намного лучше"
    assert st.get_prompt_salt(phrase2, 3) == "Сделай намного, намного лучше"

    # 3. Test end bracket "Make it much [better]"
    phrase3 = "Make it much [better]"
    assert st.get_prompt_salt(phrase3, 2) == "Make it much better"
    assert st.get_prompt_salt(phrase3, 3) == "Make it much better, better"

    # 4. Test no brackets fallback (repeating the entire base phrase)
    phrase4 = "Be extra careful"
    assert st.get_prompt_salt(phrase4, 2) == "Be extra careful"
    assert st.get_prompt_salt(phrase4, 3) == "Be extra careful, Be extra careful"

    # 5. Test disabling settings
    assert st.get_prompt_salt("false", 2) == ""
    assert st.get_prompt_salt("None", 2) == ""
    assert st.get_prompt_salt("", 2) == ""


def test_ollama_translate_with_salt(monkeypatch):
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
        assert body["prompt"] == "Translate English to Russian. Make it much better.\n\nHello"
        return MockResponse()

    monkeypatch.setattr(urllib.request, "urlopen", mock_urlopen)
    res = st.ollama_translate("Hello", "en", "ru", settings, salt="Make it much better")
    assert res == "Привет"


def test_translate_lines_ollama_retry_with_salt(monkeypatch):
    st = _load_translator()
    settings = {
        "subtitle_translator_provider": "ollama",
        "ollama_api_url": "http://localhost:11434/api/generate",
        "ollama_model": "llama3",
        "ollama_prompt": "Translate {source_lang} to {target_lang}.",
        "ollama_prompt_salt": "Make it [much] better",
        "subtitle_translator_chunk_size": "2",
        "subtitle_translator_max_retries": "3",
    }

    attempts = []
    def mock_ollama_translate(text, sl, tl, s, salt="", feedback=""):
        attempts.append(salt)
        if len(attempts) < 3:
            return ""
        return "Привет\nМир"

    monkeypatch.setattr(st, "ollama_translate", mock_ollama_translate)
    monkeypatch.setattr(st.time, "sleep", lambda x: None)

    lines = ["Hello", "World"]
    res = st.translate_lines(lines, "en", "ru", settings)
    assert res == ["Привет", "Мир"]
    assert attempts == ["", "Make it much better", "Make it much, much better"]


def test_translate_lines_ollama_retry_with_feedback(monkeypatch):
    st = _load_translator()
    settings = {
        "subtitle_translator_provider": "ollama",
        "ollama_api_url": "http://localhost:11434/api/generate",
        "ollama_model": "llama3",
        "ollama_prompt": "Translate {source_lang} to {target_lang}.",
        "ollama_prompt_salt": "Make it [much] better",
        "ollama_prompt_feedback": "true",
        "ollama_prompt_feedback_template": "Error detail: {last_error}",
        "subtitle_translator_chunk_size": "2",
        "subtitle_translator_max_retries": "3",
    }

    calls = []
    def mock_ollama_translate(text, sl, tl, s, salt="", feedback=""):
        calls.append((salt, feedback))
        if len(calls) == 1:
            return "Привет"  # triggers line count mismatch validation error
        return "Привет\nМир"

    monkeypatch.setattr(st, "ollama_translate", mock_ollama_translate)
    monkeypatch.setattr(st.time, "sleep", lambda x: None)

    lines = ["Hello", "World"]
    res = st.translate_lines(lines, "en", "ru", settings)
    assert res == ["Привет", "Мир"]
    
    assert len(calls) == 2
    assert calls[0] == ("", "")
    assert calls[1][0] == "Make it much better"
    assert calls[1][1] == "Error detail: Line count mismatch (expected 2, got 1)"


def test_ollama_translate_structured_success(monkeypatch):
    st = _load_translator()
    settings = {
        "ollama_api_url": "http://localhost:11434/api/generate",
        "ollama_model": "llama3",
        "ollama_prompt": "Translate {source_lang} to {target_lang}.",
        "ollama_json_format": "true",
        "ollama_json_schema": "array_of_objects",
        "ollama_json_prompt": "Translate JSON {source_lang} to {target_lang}.",
    }
    mock_response_data = {"response": '[{"id": 1, "text": "Привет"}, {"id": 2, "text": "Мир"}]'}
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
        assert body["format"] == "json"
        assert body["prompt"] == 'Translate JSON English to Russian.\n\n[{"id": 1, "text": "Hello"}, {"id": 2, "text": "World"}]'
        return MockResponse()

    monkeypatch.setattr(urllib.request, "urlopen", mock_urlopen)
    res = st.ollama_translate("Hello\nWorld", "en", "ru", settings)
    assert res == "Привет\nМир"


def test_ollama_translate_structured_invalid_json(monkeypatch):
    st = _load_translator()
    settings = {
        "ollama_api_url": "http://localhost:11434/api/generate",
        "ollama_model": "llama3",
        "ollama_json_format": "true",
    }
    mock_response_data = {"response": 'invalid-json'}
    mock_body = json.dumps(mock_response_data).encode("utf-8")

    class MockResponse:
        def read(self):
            return mock_body
        def __enter__(self):
            return self
        def __exit__(self, *args):
            pass

    monkeypatch.setattr(urllib.request, "urlopen", lambda req, timeout=None: MockResponse())
    with pytest.raises(Exception) as exc_info:
        st.ollama_translate("Hello\nWorld", "en", "ru", settings)
    assert "Ollama returned invalid JSON" in str(exc_info.value)


def test_ollama_translate_structured_count_mismatch(monkeypatch):
    st = _load_translator()
    settings = {
        "ollama_api_url": "http://localhost:11434/api/generate",
        "ollama_model": "llama3",
        "ollama_json_format": "true",
    }
    mock_response_data = {"response": '[{"id": 1, "text": "Привет"}]'}
    mock_body = json.dumps(mock_response_data).encode("utf-8")

    class MockResponse:
        def read(self):
            return mock_body
        def __enter__(self):
            return self
        def __exit__(self, *args):
            pass

    monkeypatch.setattr(urllib.request, "urlopen", lambda req, timeout=None: MockResponse())
    with pytest.raises(Exception) as exc_info:
        st.ollama_translate("Hello\nWorld", "en", "ru", settings)
    assert "Line count mismatch in structured JSON" in str(exc_info.value)


def test_ollama_translate_structured_duplicate_keys_regex_fallback(monkeypatch):
    st = _load_translator()
    settings = {
        "ollama_api_url": "http://localhost:11434/api/generate",
        "ollama_model": "llama3",
        "ollama_json_format": "true",
        "ollama_json_schema": "array_of_objects",
    }
    # Duplicate keys: standard json.loads parses this as a single dict with 1 text item,
    # but the regex fallback correctly finds all 2 items!
    response_payload = '{"id": 1, "text": "Привет", "id": 2, "text": "Мир"}'
    mock_response_data = {"response": response_payload}
    mock_body = json.dumps(mock_response_data).encode("utf-8")

    class MockResponse:
        def read(self):
            return mock_body
        def __enter__(self):
            return self
        def __exit__(self, *args):
            pass

    monkeypatch.setattr(urllib.request, "urlopen", lambda req, timeout=None: MockResponse())
    res = st.ollama_translate("Hello\nWorld", "en", "ru", settings)
    assert res == "Привет\nМир"


def test_ollama_translate_structured_markdown_fences(monkeypatch):
    st = _load_translator()
    settings = {
        "ollama_api_url": "http://localhost:11434/api/generate",
        "ollama_model": "llama3",
        "ollama_json_format": "true",
        "ollama_json_schema": "array_of_objects",
    }
    # Response wrapped in markdown fences with extra preamble text
    response_payload = (
        "Here is the translated data:\n"
        "```json\n"
        '[{"id": 1, "text": "Привет"}, {"id": 2, "text": "Мир"}]\n'
        "```\n"
        "Hope this helps!"
    )
    mock_response_data = {"response": response_payload}
    mock_body = json.dumps(mock_response_data).encode("utf-8")

    class MockResponse:
        def read(self):
            return mock_body
        def __enter__(self):
            return self
        def __exit__(self, *args):
            pass

    monkeypatch.setattr(urllib.request, "urlopen", lambda req, timeout=None: MockResponse())
    res = st.ollama_translate("Hello\nWorld", "en", "ru", settings)
    assert res == "Привет\nМир"


def test_ollama_translate_structured_strings_success(monkeypatch):
    st = _load_translator()
    settings = {
        "ollama_api_url": "http://localhost:11434/api/generate",
        "ollama_model": "llama3",
        "ollama_json_format": "true",
        "ollama_json_schema": "array_of_strings",
    }
    mock_response_data = {"response": '["Привет", "Мир"]'}
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
        assert body["format"] == "json"
        expected_prompt = (
            "Translate the JSON array of strings from English to Russian.\n"
            "Output format must be a JSON array of strings.\n\n"
            "Example input:\n"
            "[\n"
            "  \"Hello\",\n"
            "  \"World\"\n"
            "]\n\n"
            "Example output:\n"
            "[\n"
            "  \"Привет\",\n"
            "  \"Мир\"\n"
            "]\n\n"
            "Input:\n\n"
            '["Hello", "World"]'
        )
        assert body["prompt"] == expected_prompt
        return MockResponse()

    monkeypatch.setattr(urllib.request, "urlopen", mock_urlopen)
    res = st.ollama_translate("Hello\nWorld", "en", "ru", settings)
    assert res == "Привет\nМир"


def test_ollama_translate_structured_dict_success(monkeypatch):
    st = _load_translator()
    settings = {
        "ollama_api_url": "http://localhost:11434/api/generate",
        "ollama_model": "llama3",
        "ollama_json_format": "true",
        "ollama_json_schema": "dict_of_strings",
    }
    mock_response_data = {"response": '{"translations": ["Привет", "Мир"]}'}
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
        assert body["format"] == "json"
        expected_prompt = (
            "Translate the JSON array of strings under the 'source' key from English to Russian.\n"
            "Output format must be a JSON object with a single 'translations' key containing the translated JSON array of strings.\n\n"
            "Example input:\n"
            "{\n"
            "  \"source\": [\n"
            "    \"Hello\",\n"
            "    \"World\"\n"
            "  ]\n"
            "}\n\n"
            "Example output:\n"
            "{\n"
            "  \"translations\": [\n"
            "    \"Привет\",\n"
            "    \"Мир\"\n"
            "  ]\n"
            "}\n\n"
            "Input:\n\n"
            '{"source": ["Hello", "World"]}'
        )
        assert body["prompt"] == expected_prompt
        return MockResponse()

    monkeypatch.setattr(urllib.request, "urlopen", mock_urlopen)
    res = st.ollama_translate("Hello\nWorld", "en", "ru", settings)
    assert res == "Привет\nМир"


def test_clean_subtitle_text():
    st = _load_translator()
    
    # Test HTML tags removal
    assert st.clean_subtitle_text("<i>Hello</i> <b>World</b>") == "Hello World"
    assert st.clean_subtitle_text("<font color=\"#ff0000\">Red</font>") == "Red"
    
    # Test ASS formatting tags removal
    assert st.clean_subtitle_text("{\\an8}Hello {\\pos(100,120)}World") == "Hello World"
    
    # Test custom cleanup patterns
    assert st.clean_subtitle_text(
        "Вы услышите новости всего раз.**",
        clean_rules=st.parse_clean_patterns("**"),
    ) == "Вы услышите новости всего раз."
    assert st.clean_subtitle_text(
        "Hello [noise]",
        clean_rules=st.parse_clean_patterns("re:\\s+\\[noise\\]$"),
    ) == "Hello"
    assert st.clean_subtitle_text(
        "Hello [draft]",
        clean_rules=st.parse_clean_patterns("glob:[[]draft[]]"),
    ) == "Hello"
    assert st.clean_subtitle_text(
        "Hello REMOVE",
        clean_rules=st.parse_clean_patterns("REMOVE"),
    ) == "Hello"
    assert st.clean_subtitle_text(
        "Hello [noise] REMOVE",
        clean_rules=st.parse_clean_patterns("re:\\s+\\[noise\\],REMOVE"),
    ) == "Hello"
    assert st.clean_subtitle_text(
        "Hello, world",
        clean_rules=st.parse_clean_patterns("Hello\\,"),
    ) == "world"
    assert st.clean_subtitle_text("Вы услышите новости всего раз.**") == "Вы услышите новости всего раз.**"
    
    # Test newlines replacement
    assert st.clean_subtitle_text("Line1\nLine2\r\nLine3\rLine4") == "Line1 Line2 Line3 Line4"
    
    # Test whitespace normalization
    assert st.clean_subtitle_text("   Hello     World   ") == "Hello World"
    assert st.clean_subtitle_text("") == ""
    assert st.clean_subtitle_text(None) == ""


def test_process_file_cleans_tags_and_breaks(tmp_path, monkeypatch):
    st = _load_translator()
    
    # Create a source SRT file with tags and multi-line text
    source_content = (
        "1\n"
        "00:00:01,000 --> 00:00:04,000\n"
        "<i>Hello</i>\n"
        "<b>World</b>\n\n"
        "2\n"
        "00:00:05,000 --> 00:00:08,000\n"
        "{\\an8}This is a {\\pos(1,2)}multiline\n"
        "subtitle block.\n"
    )
    source_file = tmp_path / "test_subs.en.srt"
    source_file.write_text(source_content, encoding="utf-8")
    
    settings = {
        "subtitle_translator_zid_script": "",
        "subtitle_translator_target_languages": "ru",
        "subtitle_translator_source_language": "en",
        "subtitle_translator_provider": "google",
        "subtitle_translator_duplicate_mode": "overwrite",
        "subtitle_translator_rename_source_with_zid": "false",
        "subtitle_translator_rename_related_media_with_zid": "false",
        "google_api_url": "dummy",
    }
    
    # Mock google_translate_v1 to return translation (which might keep or introduce tags/formatting)
    # E.g. translating "Hello World" to "Привет Мир" (without tags)
    # and "This is a multiline subtitle block." to "**Привет** {\\an8}мультистрочный\nблок."
    def mock_google_translate(text, sl, tl, api_url):
        if "Hello World" in text:
            return "Привет Мир"
        if "This is a multiline subtitle block." in text:
            return "**Привет** {\\an8}мультистрочный\nблок."
        return text

    monkeypatch.setattr(st, "google_translate_v1", mock_google_translate)
    
    ok = st.process_file(source_file, settings, "session-zid")
    assert ok is True
    
    # Read the translated file
    target_file = tmp_path / "test_subs.ru.srt"
    assert target_file.exists()
    translated_content = target_file.read_text(encoding="utf-8")
    
    # The output should NOT have:
    # 1. <i> or <b> tags
    # 2. ASS formatting tags
    # 3. Markdown markers
    # 4. Line breaks inside the subtitle text blocks
    expected_content = (
        "1\n"
        "00:00:01,000 --> 00:00:04,000\n"
        "Привет Мир\n\n"
        "2\n"
        "00:00:05,000 --> 00:00:08,000\n"
        "Привет мультистрочный блок.\n"
    )

    
    # Normalize line endings
    translated_norm = translated_content.replace("\r\n", "\n")
    expected_norm = expected_content.replace("\r\n", "\n")
    assert translated_norm == expected_norm


# ==============================================================================
# LANGUAGE CODE → NAME LOOKUP
# ==============================================================================

def test_lang_code_to_name_known():
    st = _load_translator()
    assert st.lang_code_to_name("ru") == "Russian"
    assert st.lang_code_to_name("en") == "English"
    assert st.lang_code_to_name("de") == "German"
    assert st.lang_code_to_name("zh-CN") == "Chinese (Simplified)"
    assert st.lang_code_to_name("pt-BR") == "Brazilian Portuguese"


def test_lang_code_to_name_unknown_returns_code():
    st = _load_translator()
    assert st.lang_code_to_name("xx") == "xx"
    assert st.lang_code_to_name("???") == "???"


def test_ollama_translate_uses_english_lang_name(monkeypatch):
    """Verify that ollama_translate builds the prompt with 'Russian', not 'ru'."""
    st = _load_translator()
    captured_prompt = {}

    def fake_urlopen(req, timeout):
        import io, json as _json
        captured_prompt['value'] = req.data.decode('utf-8')
        body = _json.dumps({"response": "Привет"}).encode('utf-8')
        class FakeResp:
            def read(self): return body
            def __enter__(self): return self
            def __exit__(self, *a): pass
        return FakeResp()

    monkeypatch.setattr("urllib.request.urlopen", fake_urlopen)

    settings = {
        "ollama_api_url": "http://localhost:11434/api/generate",
        "ollama_model": "gemma3:1b",
        "ollama_prompt": "Translate from {source_lang} to {target_lang}.",
        "ollama_prompt_salt": "false",
        "ollama_prompt_feedback": "false",
        "ollama_json_format": "false",
    }
    st.ollama_translate("Hello", sl="en", tl="ru", settings=settings)

    payload_str = captured_prompt['value']
    assert "Russian" in payload_str, "Expected 'Russian' in prompt, got: " + payload_str
    assert "English" in payload_str, "Expected 'English' in prompt, got: " + payload_str
    assert '"ru"' not in payload_str or 'target_lang' not in payload_str  # raw code must not appear as lang arg


# ==============================================================================
# TIMECODE / MERGE-SPLIT HELPERS
# ==============================================================================

def test_parse_timecode():
    st = _load_translator()
    assert st.parse_timecode("00:00:00,000") == 0
    assert st.parse_timecode("00:00:01,000") == 1000
    assert st.parse_timecode("00:01:00,000") == 60_000
    assert st.parse_timecode("01:00:00,000") == 3_600_000
    assert st.parse_timecode("01:02:03,456") == 3_600_000 + 2 * 60_000 + 3_000 + 456


def test_parse_timeline():
    st = _load_translator()
    start, end = st.parse_timeline("00:00:01,000 --> 00:00:04,500")
    assert start == 1000
    assert end == 4500


def test_merge_split_markers_exact_round_trip():
    st = _load_translator()

    joined, markers = st.join_merged_group_texts(["First part", "second part", "third part"])

    assert joined == "First part [[KWSPLIT0001]] second part [[KWSPLIT0002]] third part"
    assert markers == ["[[KWSPLIT0001]]", "[[KWSPLIT0002]]"]
    assert st.split_merged_text_by_markers(
        "Первая часть [[KWSPLIT0001]] вторая часть [[KWSPLIT0002]] третья часть",
        markers,
    ) == ["Первая часть", "вторая часть", "третья часть"]


def test_merge_split_markers_missing_marker_fails():
    st = _load_translator()

    with pytest.raises(ValueError) as exc_info:
        st.split_merged_text_by_markers("Первая часть вторая часть", ["[[KWSPLIT0001]]"])

    assert "Missing merge split marker" in str(exc_info.value)


def test_merge_split_mode_validation():
    st = _load_translator()

    assert st.get_merge_split_mode({}) == "marker"
    assert st.get_merge_split_mode({"subtitle_translator_merge_split_mode": "proportional"}) == "proportional"
    with pytest.raises(ValueError) as exc_info:
        st.get_merge_split_mode({"subtitle_translator_merge_split_mode": "guess"})
    assert "subtitle_translator_merge_split_mode" in str(exc_info.value)


def test_split_by_proportion_compatibility_mode():
    st = _load_translator()

    parts = st.split_by_proportion("Hello World", [5, 5])

    assert len(parts) == 2
    assert " ".join(parts).replace("  ", " ") == "Hello World"


def test_build_merge_groups_no_merge_on_sentence_ending():
    st = _load_translator()
    blocks = [
        {"text_lines": ["Hello world."], "timeline": "00:00:00,000 --> 00:00:02,000"},
        {"text_lines": ["Next sentence starts here."], "timeline": "00:00:02,500 --> 00:00:05,000"},
    ]
    groups = st.build_merge_groups(blocks, max_gap_ms=1000)
    # Prev text ends with '.', so should NOT be merged
    assert groups == [[0], [1]]


def test_build_merge_groups_merge_on_small_gap_no_ending():
    st = _load_translator()
    blocks = [
        {"text_lines": ["This sentence continues"], "timeline": "00:00:00,000 --> 00:00:02,000"},
        {"text_lines": ["right here naturally"], "timeline": "00:00:02,300 --> 00:00:04,000"},
    ]
    groups = st.build_merge_groups(blocks, max_gap_ms=1000)
    # Gap = 300ms < 1000ms, no sentence ending → should merge
    assert groups == [[0, 1]]


def test_build_merge_groups_no_merge_on_large_gap():
    st = _load_translator()
    blocks = [
        {"text_lines": ["Sentence one continues"], "timeline": "00:00:00,000 --> 00:00:02,000"},
        {"text_lines": ["New subtitle here"], "timeline": "00:00:04,000 --> 00:00:06,000"},
    ]
    groups = st.build_merge_groups(blocks, max_gap_ms=1000)
    # Gap = 2000ms > 1000ms → separate groups
    assert groups == [[0], [1]]


def test_build_merge_groups_no_merge_on_empty_block():
    st = _load_translator()
    blocks = [
        {"text_lines": [], "timeline": "00:00:00,000 --> 00:00:02,000"},
        {"text_lines": ["Some text"], "timeline": "00:00:02,200 --> 00:00:04,000"},
    ]
    groups = st.build_merge_groups(blocks, max_gap_ms=1000)
    # Empty block should break the group
    assert groups == [[0], [1]]


def test_build_merge_groups_three_continuous():
    st = _load_translator()
    blocks = [
        {"text_lines": ["First part without ending"], "timeline": "00:00:00,000 --> 00:00:02,000"},
        {"text_lines": ["second part continues"], "timeline": "00:00:02,100 --> 00:00:04,000"},
        {"text_lines": ["and finishes here."], "timeline": "00:00:04,100 --> 00:00:06,000"},
    ]
    groups = st.build_merge_groups(blocks, max_gap_ms=1000)
    # Block 0→1: gap 100ms, no ending → merge; Block 1→2: gap 100ms, no ending → merge
    assert groups == [[0, 1, 2]]


def test_process_file_merge_mode(tmp_path, monkeypatch):
    st = _load_translator()

    source_content = (
        "1\n"
        "00:00:00,000 --> 00:00:02,000\n"
        "This is the first part\n\n"
        "2\n"
        "00:00:02,300 --> 00:00:04,000\n"
        "of a continuous sentence.\n\n"
        "3\n"
        "00:00:10,000 --> 00:00:12,000\n"
        "Standalone sentence.\n"
    )
    source_file = tmp_path / "test_merge.en.srt"
    source_file.write_text(source_content, encoding="utf-8")

    settings = {
        "subtitle_translator_zid_script": "",
        "subtitle_translator_target_languages": "ru",
        "subtitle_translator_source_language": "en",
        "subtitle_translator_provider": "google",
        "subtitle_translator_duplicate_mode": "overwrite",
        "subtitle_translator_rename_source_with_zid": "false",
        "subtitle_translator_rename_related_media_with_zid": "false",
        "subtitle_translator_merge_lines": "true",
        "subtitle_translator_merge_max_gap_ms": "1000",
        "google_api_url": "dummy",
    }

    translated_calls = []

    def mock_google_translate(text, sl, tl, api_url):
        translated_calls.append(text)
        if "This is the first part" in text:
            assert "[[KWSPLIT0001]]" in text
            return "Это первая часть [[KWSPLIT0001]] непрерывного предложения."
        if "Standalone sentence" in text:
            return "Отдельное предложение."
        return text

    monkeypatch.setattr(st, "google_translate_v1", mock_google_translate)

    ok = st.process_file(source_file, settings, "session-zid")
    assert ok is True

    target_file = tmp_path / "test_merge.ru.srt"
    assert target_file.exists()
    content = target_file.read_text(encoding="utf-8")

    # Block 3 (standalone) must be translated as-is
    assert "Отдельное предложение." in content

    lines = content.replace("\r\n", "\n").split("\n")
    text_lines = [l for l in lines if l and not l.isdigit() and "-->" not in l]
    assert text_lines == [
        "Это первая часть",
        "непрерывного предложения.",
        "Отдельное предложение.",
    ]


def test_process_file_merge_mode_missing_marker_fails(tmp_path, monkeypatch):
    st = _load_translator()

    source_content = (
        "1\n"
        "00:00:00,000 --> 00:00:02,000\n"
        "This is the first part\n\n"
        "2\n"
        "00:00:02,300 --> 00:00:04,000\n"
        "of a continuous sentence.\n"
    )
    source_file = tmp_path / "test_merge.en.srt"
    source_file.write_text(source_content, encoding="utf-8")

    settings = {
        "subtitle_translator_zid_script": "",
        "subtitle_translator_target_languages": "ru",
        "subtitle_translator_source_language": "en",
        "subtitle_translator_provider": "google",
        "subtitle_translator_duplicate_mode": "overwrite",
        "subtitle_translator_rename_source_with_zid": "false",
        "subtitle_translator_rename_related_media_with_zid": "false",
        "subtitle_translator_merge_lines": "true",
        "subtitle_translator_merge_max_gap_ms": "1000",
        "google_api_url": "dummy",
    }

    def mock_google_translate(text, sl, tl, api_url):
        assert "[[KWSPLIT0001]]" in text
        return "Это первая часть непрерывного предложения."

    monkeypatch.setattr(st, "google_translate_v1", mock_google_translate)

    ok = st.process_file(source_file, settings, "session-zid")

    assert ok is False
    assert not (tmp_path / "test_merge.ru.srt").exists()
