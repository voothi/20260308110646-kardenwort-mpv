import importlib.util
from pathlib import Path
import tempfile


def _load_viewer_module():
    repo_root = Path(__file__).resolve().parents[2]
    viewer_path = repo_root / "scripts" / "_tools" / "sub-viewer" / "viewer.py"
    spec = importlib.util.spec_from_file_location("sub_viewer_module", viewer_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Could not load module spec from {viewer_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


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


def test_reader_srt_written_next_to_input_prefers_plain_name_then_zid_on_conflict():
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
            assert first.name == "notes.20260517154232.srt"
            assert second.name == "notes.20260517154232.1.srt"
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

        assert Path(srt1).name == "text1.20260517162358.srt"
        assert Path(srt2).name == "text2.20260517162358.srt"
