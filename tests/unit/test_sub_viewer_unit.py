import importlib.util
from pathlib import Path
import tempfile


def _load_viewer_module():
    repo_root = Path(__file__).resolve().parents[2]
    viewer_path = repo_root / "scripts" / "sub-viewer" / "viewer.py"
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
