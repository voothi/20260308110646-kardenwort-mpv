import importlib.util
from pathlib import Path
import tempfile
from contextlib import contextmanager
import shutil
import uuid


def _load_viewer_module():
    repo_root = Path(__file__).resolve().parents[2]
    viewer_path = repo_root / "scripts" / "_tools" / "sub-viewer" / "viewer.py"
    spec = importlib.util.spec_from_file_location("sub_viewer_module", viewer_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Could not load module spec from {viewer_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _srt_payload_lines(srt_text):
    lines = []
    for line in srt_text.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.isdigit() or "-->" in stripped:
            continue
        lines.append(line)
    return lines


@contextmanager
def _workspace_scratch_dir():
    repo_root = Path(__file__).resolve().parents[2]
    base = repo_root / ".tmp_pytest_subviewer"
    base.mkdir(parents=True, exist_ok=True)
    case_dir = base / f"case-{uuid.uuid4().hex}"
    case_dir.mkdir(parents=True, exist_ok=False)
    try:
        yield case_dir
    finally:
        shutil.rmtree(case_dir, ignore_errors=True)


def test_first_start_parses_over_two_hours():
    viewer = _load_viewer_module()
    with tempfile.TemporaryDirectory() as td:
        srt = Path(td) / "long.en.srt"
        srt.write_text(
            "1\n09:00:00,000 --> 09:00:05,000\nLong session\n",
            encoding="utf-8",
        )
        assert viewer.get_first_sub_start(str(srt), viewer.VIRTUAL_VIDEO_DURATION) == 32400.0


def test_last_end_parses_over_two_hours():
    viewer = _load_viewer_module()
    with tempfile.TemporaryDirectory() as td:
        srt = Path(td) / "long.en.srt"
        srt.write_text(
            "1\n08:59:58,000 --> 09:00:03,500\nLong session\n",
            encoding="utf-8",
        )
        assert viewer.get_last_sub_end(str(srt), viewer.VIRTUAL_VIDEO_DURATION) == 32403.5


def test_secondary_subtitle_selection_is_deterministic():
    viewer = _load_viewer_module()
    with tempfile.TemporaryDirectory() as td:
        tmp_path = Path(td)
        primary = tmp_path / "lesson.de.srt"
        primary.write_text("1\n00:00:00,000 --> 00:00:01,000\nHallo\n", encoding="utf-8")

        # Create in non-priority order to ensure deterministic ranked selection.
        (tmp_path / "lesson.xx.srt").write_text("", encoding="utf-8")
        (tmp_path / "lesson.ru.srt").write_text("", encoding="utf-8")
        (tmp_path / "lesson.en.srt").write_text("", encoding="utf-8")

        selected = viewer.find_secondary_subtitle(str(tmp_path), "lesson", str(primary))
        assert selected is not None
        assert Path(selected).name == "lesson.ru.srt"


def test_reader_builds_srt_from_text():
    viewer = _load_viewer_module()
    with tempfile.TemporaryDirectory() as td:
        txt = Path(td) / "reader.txt"
        txt.write_text("First line\n\nSecond block\nStill second\n", encoding="utf-8")
        srt_path = viewer.build_reader_srt(str(txt))
        srt_text = Path(srt_path).read_text(encoding="utf-8")

        assert "00:00:00,000 -->" in srt_text
        assert "First line" in srt_text
        assert "Second block" in srt_text
        assert "Still second" in srt_text


def test_resolve_subtitle_input_accepts_markdown():
    viewer = _load_viewer_module()
    with tempfile.TemporaryDirectory() as td:
        md = Path(td) / "notes.md"
        md.write_text("# Header\n\nParagraph text\n", encoding="utf-8")
        path, generated = viewer.resolve_subtitle_input(str(md))
        assert generated is True
        assert path.lower().endswith(".srt")


def test_reader_splits_single_long_paragraph_into_multiple_cues():
    viewer = _load_viewer_module()
    with tempfile.TemporaryDirectory() as td:
        txt = Path(td) / "single.txt"
        txt.write_text(
            "This is a long single paragraph without blank lines that should still be split into several reader cues for navigation and seeking in the subtitle reader mode.",
            encoding="utf-8",
        )
        srt_path = viewer.build_reader_srt(str(txt))
        srt_text = Path(srt_path).read_text(encoding="utf-8")
        # At least cue 1 and cue 2 must exist.
        assert "\n1\n" in f"\n{srt_text}"
        assert "\n2\n" in f"\n{srt_text}"


def test_resolve_subtitle_input_rejects_unknown_type():
    viewer = _load_viewer_module()
    with tempfile.TemporaryDirectory() as td:
        dat = Path(td) / "file.xyz"
        dat.write_text("content\n", encoding="utf-8")
        try:
            viewer.resolve_subtitle_input(str(dat))
            assert False, "Expected ValueError for unsupported extension"
        except ValueError as e:
            assert "Unsupported file type" in str(e)


def test_mpv_log_path_is_local_to_sub_viewer():
    viewer = _load_viewer_module()
    log_path = Path(viewer.get_mpv_log_path())
    assert log_path.name == "mpv_sub_viewer.log"
    assert log_path.parent.name == "logs"


def test_reader_srt_written_next_to_input_prefers_plain_name_then_zid_folder_on_conflict():
    viewer = _load_viewer_module()
    with tempfile.TemporaryDirectory() as td:
        txt = Path(td) / "notes.md"
        txt.write_text("Line one\nLine two\n", encoding="utf-8")

        srt_path = Path(viewer.build_reader_srt(str(txt)))
        assert srt_path.parent == txt.parent
        assert srt_path.name == "notes.srt"
        assert srt_path.exists()

        # Ensure collision-safe behavior for same ZID once plain name is taken.
        original_current_zid = viewer.current_zid
        viewer.current_zid = lambda: "20260517154232"
        try:
            first = Path(viewer.build_reader_srt(str(txt)))
            second = Path(viewer.build_reader_srt(str(txt)))
            assert first.parent.name == "20260517154232"
            assert first.name == "notes.srt"
            assert second.parent.name == "20260517154232"
            assert second.name == "notes.1.srt"
        finally:
            viewer.current_zid = original_current_zid


def test_normalize_cli_input_paths_skips_literal_percent_one():
    viewer = _load_viewer_module()
    paths = viewer.normalize_cli_input_paths(["viewer.py", "%1", "a.txt", "b.txt"])
    assert len(paths) == 2
    assert paths[0].lower().endswith("a.txt")
    assert paths[1].lower().endswith("b.txt")


def test_order_input_paths_prefers_numeric_1_then_3():
    viewer = _load_viewer_module()
    ordered = viewer.order_input_paths_for_roles(
        [r"C:\x\text3.txt", r"C:\x\text1.txt"]
    )
    assert ordered[0].lower().endswith("text1.txt")
    assert ordered[1].lower().endswith("text3.txt")


def test_order_input_paths_prefers_en_before_ru():
    viewer = _load_viewer_module()
    ordered = viewer.order_input_paths_for_roles(
        [r"C:\x\movie.ru.txt", r"C:\x\movie.en.txt"]
    )
    assert ordered[0].lower().endswith("movie.en.txt")
    assert ordered[1].lower().endswith("movie.ru.txt")


def test_explicit_secondary_text_is_converted_and_used():
    viewer = _load_viewer_module()
    with tempfile.TemporaryDirectory() as td:
        base = Path(td)
        primary_txt = base / "text1.txt"
        secondary_txt = base / "text2.txt"
        primary_txt.write_text("Primary line\n", encoding="utf-8")
        secondary_txt.write_text("Secondary line\n", encoding="utf-8")

        primary_srt, primary_generated = viewer.resolve_subtitle_input(str(primary_txt))
        assert primary_generated is True

        secondary_sub = viewer.resolve_secondary_subtitle(
            str(primary_txt),
            primary_srt,
            primary_generated,
            str(secondary_txt),
        )
        assert secondary_sub is not None
        assert secondary_sub.lower().endswith(".srt")
        assert Path(secondary_sub).exists()


def test_parallel_reader_srts_align_by_line_index_when_lengths_differ():
    viewer = _load_viewer_module()
    with tempfile.TemporaryDirectory() as td:
        base = Path(td)
        t1 = base / "text1.txt"
        t2 = base / "text2.txt"
        t1.write_text("A1\nA2\nA3\n", encoding="utf-8")
        t2.write_text("B1\nB2\n", encoding="utf-8")

        srt1, srt2 = viewer.build_parallel_reader_srts(str(t1), str(t2))
        p = Path(srt1).read_text(encoding="utf-8")
        s = Path(srt2).read_text(encoding="utf-8")

        assert "A1" in p and "A2" in p and "A3" in p
        assert "B1" in s and "B2" in s
        assert "\n3\n" in s
        p_times = [line for line in p.splitlines() if "-->" in line]
        s_times = [line for line in s.splitlines() if "-->" in line]
        assert p_times == s_times


def test_estimated_cue_duration_grows_with_text_length():
    viewer = _load_viewer_module()
    short_duration = viewer._estimate_cue_duration_seconds("short text")
    long_duration = viewer._estimate_cue_duration_seconds(
        "This is a much longer subtitle line that should take more time to read than the short one."
    )
    assert long_duration > short_duration
    assert short_duration >= viewer.READER_MIN_CUE_SECONDS
    assert long_duration <= viewer.READER_MAX_CUE_SECONDS


def test_parallel_reader_uses_shared_zid_when_one_base_srt_exists():
    viewer = _load_viewer_module()
    with tempfile.TemporaryDirectory() as td:
        base = Path(td)
        t1 = base / "text1.txt"
        t2 = base / "text2.txt"
        t1.write_text("A1\n", encoding="utf-8")
        t2.write_text("B1\n", encoding="utf-8")
        # Existing base SRT only for primary input.
        (base / "text1.srt").write_text("1\n00:00:00,000 --> 00:00:01,000\nold\n", encoding="utf-8")

        original_current_zid = viewer.current_zid
        viewer.current_zid = lambda: "20260517162358"
        try:
            srt1, srt2 = viewer.build_parallel_reader_srts(str(t1), str(t2))
        finally:
            viewer.current_zid = original_current_zid

        assert Path(srt1).parent.name == "20260517162358"
        assert Path(srt2).parent.name == "20260517162358"
        assert Path(srt1).name == "text1.srt"
        assert Path(srt2).name == "text2.srt"


def test_line_to_cue_text_wraps_with_real_newlines_not_ass_markers():
    viewer = _load_viewer_module()
    original_max = viewer.READER_MAX_CHARS_PER_LINE
    viewer.READER_MAX_CHARS_PER_LINE = 16
    try:
        cue = viewer._line_to_cue_text(
            "Microsoft expects capacity constraints through the year."
        )
    finally:
        viewer.READER_MAX_CHARS_PER_LINE = original_max

    assert "\\N" not in cue
    assert "\n" in cue


def test_reader_srt_from_text_does_not_emit_ass_break_markers_or_boundary_spaces():
    viewer = _load_viewer_module()
    with _workspace_scratch_dir() as td:
        txt = td / "briefing.en.txt"
        txt.write_text(
            "Microsoft plans to spend roughly $190 billion this year and still expects to run short on capacity.\n"
            "And Microsoft is not alone: across the four biggest hyperscalers, combined 2026 capital spending is on track.\n",
            encoding="utf-8",
        )

        original_max = viewer.READER_MAX_CHARS_PER_LINE
        viewer.READER_MAX_CHARS_PER_LINE = 24
        try:
            srt_path = viewer.build_reader_srt(str(txt))
        finally:
            viewer.READER_MAX_CHARS_PER_LINE = original_max

        srt_text = Path(srt_path).read_text(encoding="utf-8")
        assert "\\N" not in srt_text
        for payload in _srt_payload_lines(srt_text):
            assert payload == payload.strip()


def test_parallel_reader_preserves_hyphenated_terms_without_extra_spaces_or_ass_markers():
    viewer = _load_viewer_module()
    with _workspace_scratch_dir() as base:
        en_txt = base / "briefing.en.txt"
        ru_txt = base / "briefing.ru.txt"
        en_txt.write_text(
            "Every answer consumes high-bandwidth memory and data-center capacity.\n",
            encoding="utf-8",
        )
        ru_txt.write_text(
            "Каждый ответ потребляет память и мощности дата-центров.\n",
            encoding="utf-8",
        )

        original_max = viewer.READER_MAX_CHARS_PER_LINE
        viewer.READER_MAX_CHARS_PER_LINE = 18
        try:
            en_srt_path, ru_srt_path = viewer.build_parallel_reader_srts(str(en_txt), str(ru_txt))
        finally:
            viewer.READER_MAX_CHARS_PER_LINE = original_max

        en_srt_text = Path(en_srt_path).read_text(encoding="utf-8")
        ru_srt_text = Path(ru_srt_path).read_text(encoding="utf-8")

        assert "\\N" not in en_srt_text
        assert "\\N" not in ru_srt_text
        assert "high-bandwidth" in en_srt_text
        assert "data-center" in en_srt_text
        assert "дата-центров" in ru_srt_text

        for payload in _srt_payload_lines(en_srt_text):
            assert payload == payload.strip()
            assert "  " not in payload
        for payload in _srt_payload_lines(ru_srt_text):
            assert payload == payload.strip()
            assert "  " not in payload


# =============================================================================
# Reader cue timing — mpv.conf integration (ZID 20260526012307)
# =============================================================================

def test_multiline_cue_cap_scales_with_display_lines():
    """A cue with N display lines gets N× the per-line cap."""
    viewer = _load_viewer_module()
    original_max = viewer.READER_MAX_CUE_SECONDS
    viewer.READER_MAX_CUE_SECONDS = 7.0
    try:
        one_line = "Short single line."
        two_lines = "Line one that wraps here\nLine two continues here."
        three_lines = "First line of three\nSecond line of three\nThird line of three."

        d1 = viewer._estimate_cue_duration_seconds(one_line)
        d2 = viewer._estimate_cue_duration_seconds(two_lines)
        d3 = viewer._estimate_cue_duration_seconds(three_lines)

        assert d1 <= 7.0,  f"1-line cap should be ≤7s, got {d1}"
        assert d2 <= 14.0, f"2-line cap should be ≤14s, got {d2}"
        assert d3 <= 21.0, f"3-line cap should be ≤21s, got {d3}"
        assert d2 > d1,    "2-line cue should be longer than 1-line"
        assert d3 > d2,    "3-line cue should be longer than 2-line"
    finally:
        viewer.READER_MAX_CUE_SECONDS = original_max


def test_long_prose_line_exceeds_seven_second_default():
    """A 190-char prose cue wrapped to 2 display lines must exceed the old 7s cap."""
    viewer = _load_viewer_module()
    original_max = viewer.READER_MAX_CHARS_PER_LINE
    viewer.READER_MAX_CHARS_PER_LINE = 90
    try:
        long_text = (
            "And Microsoft is not alone: across the four biggest hyperscalers, combined 2026 capital "
            "spending is on track to approach $700 billion, nearly double what they spent in 2025."
        )
        wrapped = viewer._split_long_line(long_text, viewer.READER_MAX_CHARS_PER_LINE)
        cue_text = "\n".join(wrapped)
        assert len(wrapped) >= 2, "Precondition: text must wrap to at least 2 display lines"
        duration = viewer._estimate_cue_duration_seconds(cue_text)
        assert duration > 7.0, f"Long 2-line prose cue should exceed 7s, got {duration:.2f}s"
    finally:
        viewer.READER_MAX_CHARS_PER_LINE = original_max


def test_parse_kardenwort_reader_opts_reads_script_opts_append():
    """_parse_kardenwort_reader_opts extracts kardenwort-reader_* from script-opts-append lines."""
    viewer = _load_viewer_module()
    with tempfile.NamedTemporaryFile(mode='w', suffix='.conf', delete=False, encoding='utf-8') as f:
        f.write("script-opts-append=kardenwort-reader_max_cue_seconds=12.5\n")
        f.write("script-opts-append=kardenwort-reader_cps=13.0\n")
        f.write("script-opts-append=kardenwort-srt_font_size=34\n")  # must NOT appear
        conf_path = f.name
    try:
        opts = viewer._parse_kardenwort_reader_opts(conf_path)
        assert opts.get('max_cue_seconds') == '12.5'
        assert opts.get('cps') == '13.0'
        assert 'srt_font_size' not in opts
    finally:
        Path(conf_path).unlink(missing_ok=True)


def test_parse_kardenwort_reader_opts_reads_inline_script_opts():
    """_parse_kardenwort_reader_opts also handles comma-delimited script-opts= lines."""
    viewer = _load_viewer_module()
    with tempfile.NamedTemporaryFile(mode='w', suffix='.conf', delete=False, encoding='utf-8') as f:
        f.write("script-opts=kardenwort-reader_wpm=200.0,kardenwort-srt_font_size=34\n")
        conf_path = f.name
    try:
        opts = viewer._parse_kardenwort_reader_opts(conf_path)
        assert opts.get('wpm') == '200.0'
        assert 'srt_font_size' not in opts
    finally:
        Path(conf_path).unlink(missing_ok=True)


def test_parse_kardenwort_reader_opts_returns_empty_for_missing_file():
    viewer = _load_viewer_module()
    opts = viewer._parse_kardenwort_reader_opts("/nonexistent/path/mpv.conf")
    assert opts == {}


def test_parse_kardenwort_reader_opts_returns_empty_for_none():
    viewer = _load_viewer_module()
    opts = viewer._parse_kardenwort_reader_opts(None)
    assert opts == {}


def test_apply_reader_opts_overrides_float_globals():
    """_apply_reader_opts updates READER_* float globals correctly."""
    viewer = _load_viewer_module()
    original_max = viewer.READER_MAX_CUE_SECONDS
    original_cps = viewer.READER_OPTIMAL_CHARACTERS_PER_SECOND
    try:
        viewer._apply_reader_opts({'max_cue_seconds': '10.0', 'cps': '13.5'})
        assert viewer.READER_MAX_CUE_SECONDS == 10.0
        assert viewer.READER_OPTIMAL_CHARACTERS_PER_SECOND == 13.5
    finally:
        viewer.READER_MAX_CUE_SECONDS = original_max
        viewer.READER_OPTIMAL_CHARACTERS_PER_SECOND = original_cps


def test_apply_reader_opts_overrides_int_globals():
    """_apply_reader_opts updates READER_MAX_CHARS_PER_LINE as int."""
    viewer = _load_viewer_module()
    original = viewer.READER_MAX_CHARS_PER_LINE
    try:
        viewer._apply_reader_opts({'max_chars_per_line': '70'})
        assert viewer.READER_MAX_CHARS_PER_LINE == 70
        assert isinstance(viewer.READER_MAX_CHARS_PER_LINE, int)
    finally:
        viewer.READER_MAX_CHARS_PER_LINE = original


def test_apply_reader_opts_ignores_invalid_values():
    """_apply_reader_opts silently skips keys with non-numeric values."""
    viewer = _load_viewer_module()
    original = viewer.READER_MAX_CUE_SECONDS
    try:
        viewer._apply_reader_opts({'max_cue_seconds': 'bad_value'})
        assert viewer.READER_MAX_CUE_SECONDS == original
    finally:
        viewer.READER_MAX_CUE_SECONDS = original


def test_apply_reader_opts_ignores_unknown_keys():
    """_apply_reader_opts does not crash on unknown option keys."""
    viewer = _load_viewer_module()
    viewer._apply_reader_opts({'unknown_key': '99', 'another': 'abc'})


def test_find_mpv_conf_locates_project_root_conf():
    """_find_mpv_conf returns a path ending in mpv.conf that actually exists."""
    viewer = _load_viewer_module()
    result = viewer._find_mpv_conf()
    assert result is not None, "_find_mpv_conf should find the project-root mpv.conf"
    assert Path(result).name == "mpv.conf"
    assert Path(result).exists()


def test_apply_reader_opts_roundtrip_via_temp_conf():
    """Full roundtrip: write a temp mpv.conf, parse it, apply it, check globals."""
    viewer = _load_viewer_module()
    original_max = viewer.READER_MAX_CUE_SECONDS
    original_wpm = viewer.READER_OPTIMAL_WORDS_PER_MINUTE
    try:
        with tempfile.NamedTemporaryFile(mode='w', suffix='.conf', delete=False, encoding='utf-8') as f:
            f.write("script-opts-append=kardenwort-reader_max_cue_seconds=11.0\n")
            f.write("script-opts-append=kardenwort-reader_wpm=160.0\n")
            conf_path = f.name

        opts = viewer._parse_kardenwort_reader_opts(conf_path)
        viewer._apply_reader_opts(opts)

        assert viewer.READER_MAX_CUE_SECONDS == 11.0
        assert viewer.READER_OPTIMAL_WORDS_PER_MINUTE == 160.0
    finally:
        viewer.READER_MAX_CUE_SECONDS = original_max
        viewer.READER_OPTIMAL_WORDS_PER_MINUTE = original_wpm
        Path(conf_path).unlink(missing_ok=True)
