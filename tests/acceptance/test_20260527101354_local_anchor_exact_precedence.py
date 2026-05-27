"""
Feature ZID: 20260527101354
Test Creation ZID: 20260527101354
Feature: Local Anchor Exact-First Precedence

Regression guard for adjacent identical words at subtitle boundaries:
when local highlighting is anchored to an exact pivot slot, neighboring
lines must not also highlight unless exact-slot resolution is unavailable.
"""

import tempfile
import time
import shutil
import json
from pathlib import Path

import pytest

from tests.ipc.mpv_ipc import query_kardenwort_state
from tests.ipc.mpv_session import MpvSession


LUA_SOURCE = Path("scripts/kardenwort/main.lua")
VIDEO_FIXTURE = Path("tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.mp4")


def _lua_source():
    return LUA_SOURCE.read_text(encoding="utf-8")


def _read_anki_fields():
    lines = Path("anki-mapping.ini").read_text(encoding="utf-8").splitlines()
    fields = []
    in_fields = False
    for raw in lines:
        line = raw.strip()
        if line.startswith("["):
            if line.lower() == "[fields]":
                in_fields = True
                continue
            if in_fields:
                break
        if in_fields and line and not line.startswith(";"):
            fields.append(line)
    return fields


def _build_tsv_row(fields, values):
    row = {name: "" for name in fields}
    for key, val in values.items():
        if key in row:
            row[key] = str(val)
    return "\t".join(row[name] for name in fields)


def _write_boundary_tsv(tsv_path, term, context, time_pos, index_str, source_tag):
    fields = _read_anki_fields()
    assert fields, "anki-mapping.ini [fields] must not be empty"
    deck_col = (fields.index("Deck") + 1) if "Deck" in fields else -1

    row = _build_tsv_row(
        fields,
        {
            "Quotation": term,
            "WordSource": term,
            "WordSource2": term,
            "WordSourceInflectedForm": term,
            "WordSourceInflectedForm2": term,
            "SentenceSource": context,
            "SentenceSourceIndex": index_str,
            "Note": time_pos,
            "Source": source_tag,
            "Deck": source_tag,
        },
    )
    header = "\t".join(fields)
    with open(tsv_path, "w", encoding="utf-8", newline="\n") as f:
        if deck_col > 0:
            f.write(f"#deck column:{deck_col}\n")
        f.write(header + "\n")
        f.write(row + "\n")


def _wait_for_tsv_load(ipc, expected_size, timeout_s=8.0):
    deadline = time.time() + timeout_s
    state = {}
    while time.time() < deadline:
        state = _query_state_robust(ipc)
        if state and state.get("anki_db_size", 0) == expected_size:
            return state
        time.sleep(0.2)
    return state


def _query_state_robust(ipc, retries=3):
    for _ in range(retries):
        state = query_kardenwort_state(ipc)
        if state and "options" in state:
            return state
        # Fallback path: explicit query + direct property read (no event dependency).
        try:
            ipc.command(["script-message-to", "kardenwort", "state-query"])
            raw = ipc.get_property("user-data/kardenwort/state") or ""
            if raw and "|" in raw:
                raw = raw.split("|", 1)[1]
            if raw and raw != "{}":
                parsed = json.loads(raw)
                if parsed and "options" in parsed:
                    return parsed
        except Exception:
            pass
        time.sleep(0.2)
    return {}


def test_local_anchor_uses_exact_slot_before_neighbor_fallback():
    src = _lua_source()
    assert "local function has_exact_pivot_slot(" in src
    assert "local function pivot_line_match(" in src
    assert "if has_exact_pivot_slot(expected_sub_idx, pivot_l_idx, expected_clean_word) then" in src
    assert "return false" in src


def test_contiguous_and_split_paths_share_pivot_line_match_guard():
    src = _lua_source()
    assert "local line_match = pivot_line_match(sub_idx, expected_sub_idx, g.p_idx, expected_word)" in src
    assert "local line_match = m and pivot_line_match(m.s_i, expected_sub_idx, g.p_idx, expected_word)" in src


@pytest.mark.acceptance
def test_adjacent_identical_boundary_highlight_respects_exact_anchor_only():
    srt_text = (
        "1\n"
        "00:00:01,000 --> 00:00:02,000\n"
        "(Abbildung eines gruennen Lastkraftwagens)\n\n"
        "2\n"
        "00:00:02,000 --> 00:00:03,000\n"
        "(Abbildung eines silbernen Reisebusses)\n\n"
        "3\n"
        "00:00:03,000 --> 00:00:04,000\n"
        "EU-BERUFSKRAFTFAHRER\n"
    )

    td = tempfile.mkdtemp(prefix="kardenwort-local-anchor-", dir="C:\\tmp")
    try:
        td_path = Path(td)
        srt_path = td_path / "20260527101354-boundary.en.srt"
        tsv_path = td_path / "20260527101354-boundary.tsv"
        srt_path.write_text(srt_text, encoding="utf-8", newline="\n")
        _write_boundary_tsv(
            tsv_path,
            term="Abbildung",
            context="(Abbildung eines gruennen Lastkraftwagens) (Abbildung eines silbernen Reisebusses)",
            time_pos="2.001",
            index_str="0:1:1",
            source_tag="20260527101354-boundary.en",
        )

        session = MpvSession(video=str(VIDEO_FIXTURE), subtitle=str(srt_path), extra_args=["--pause"])
        session.start()
        try:
            ipc = session.ipc
            ipc.command(["script-message-to", "kardenwort", "test-set-option", "anki_sync_period", "0.2"])
            ipc.command(["script-message-to", "kardenwort", "test-set-option", "anki_record_file", str(tsv_path)])
            ipc.command(["script-message-to", "kardenwort", "test-set-option", "anki_global_highlight", "no"])

            ready = _query_state_robust(ipc, retries=8)
            assert ready and "options" in ready, "kardenwort state probe did not become ready in time"

            loaded = _wait_for_tsv_load(ipc, tsv_path.stat().st_size)
            assert loaded.get("anki_db_size", 0) == tsv_path.stat().st_size, "TSV did not load in time"

            ipc.command(["script-message-to", "kardenwort", "test-calc-highlight-stack", "1", "1", "2.001"])
            state_prev = _query_state_robust(ipc)
            prev_stack = (state_prev.get("test_data") or {}).get("highlight_stack") or {}

            ipc.command(["script-message-to", "kardenwort", "test-calc-highlight-stack", "2", "1", "2.001"])
            state_curr = _query_state_robust(ipc)
            curr_stack = (state_curr.get("test_data") or {}).get("highlight_stack") or {}

            assert prev_stack.get("ok") is True, f"previous-line stack probe failed: {prev_stack}"
            assert curr_stack.get("ok") is True, f"anchor-line stack probe failed: {curr_stack}"
            assert prev_stack.get("orange_stack", 0) == 0, (
                "Previous subtitle should not highlight when exact pivot slot is resolvable"
            )
            assert curr_stack.get("orange_stack", 0) >= 1, (
                "Anchor subtitle must keep local highlight on exact pivot slot"
            )
        finally:
            session.stop()
    finally:
        shutil.rmtree(td, ignore_errors=True)
