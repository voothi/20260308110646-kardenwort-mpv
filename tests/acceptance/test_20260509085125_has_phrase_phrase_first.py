"""
Feature ZID: 20260509085125
Test Creation ZID: 20260509085637
Feature: Has Phrase Phrase First
Regression tests for the has_phrase order-dependency bug (ZID 20260507230551).

Bug: `has_phrase` in `calculate_highlight_stack` was unconditionally overwritten per
matched term, so the last TSV record in the candidate scan determined whether full
(Phrase Continuity Mode) or surgical backlight was applied.

Triggering case: when a phrase record (e.g. "Geld und die Zeit") appears earlier in
the TSV than single-word records ("Zeit", "Geld") at the same timestamp, the trailing
single-word matches reset has_phrase=False — stripping the full-word highlight style.

Fix: `has_phrase = has_phrase or (#term_clean > 1)` — monotone flag.

Fixture: fragment2.tsv at time 2.162 has the bug-triggering order:
  "So spaßt ja auch"         (phrase, position 0:1:1–0:4:4)
  "die Zeit fürs Fitnessstudio" (phrase, position 0:8:1–0:11:4)
  "Geld und die Zeit"        (phrase, position 0:6:1–0:9:4)  ← phrase BEFORE single
  "Zeit"                     (single, position 0:9:1)         ← single AFTER phrase
  "Geld"                     (single, position 0:6:1)         ← single AFTER phrase

Subtitle 2 text: "So spaßt ja auch das Geld und die Zeit fürs Fitnessstudio."
Timestamps:       2.161 → 6.028 s
"""
import os
import re
import shutil
import time
from typing import Optional

import pytest

from tests.ipc.mpv_ipc import query_lls_render, query_lls_state
from tests.ipc.mpv_session import MpvSession

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

_FIXTURE_DIR = (
    "tests/fixtures/20260507200612-paketzustellerin-in-der-vorweihnachtszeit"
)
_STEM = "20260507164826-fragment2"
_VIDEO = f"{_FIXTURE_DIR}/{_STEM}.mp4"
_DE_SRT = f"{_FIXTURE_DIR}/{_STEM}.de.srt"
_RU_SRT = f"{_FIXTURE_DIR}/{_STEM}.ru.srt"
_TSV = f"{_FIXTURE_DIR}/{_STEM}.tsv"

# Seek into the middle of sub 2 (2.161 → 6.028 s).
_SUB2_SEEK = 3.5

# 0-based line indices of the relevant time-2.162 rows in the TSV.
# (0 = "#deck" comment, 1 = column headers, 2 = "Bewegung", ...)
_IDX_PHRASE_GELD_UND_DIE_ZEIT = 10  # "Geld und die Zeit"  (4 words)
_IDX_SINGLE_ZEIT = 11               # "Zeit"               (1 word)
_IDX_SINGLE_GELD = 12               # "Geld"               (1 word)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _first_hl_tag_after(render: str, word: str) -> Optional[str]:
    """
    Return the identifier of the first ASS override tag that follows `word`
    in the rendered string, or None if the word is not found.

    In phrase mode (full-word highlight):
        ...{\\1c&HCOLOR&...}WORD{\\1c&HBASE&...}{\\b0}...
        → returns '1c'  (color-reset tag follows the word)

    In surgical mode (punctuation isolation):
        ...{\\1c&HCOLOR&...}WORD{\\b0}{\\1c&HBASE&...}...
        → returns 'b0'  (bold-reset tag follows the word)

    Drum rendering uses the \\1c variant (use_1c=true).
    """
    m = re.search(re.escape(word) + r"\{\\([a-zA-Z0-9]+)", render)
    return m.group(1) if m else None


def _snippet(render: str, word: str, radius: int = 60) -> str:
    idx = render.find(word)
    if idx == -1:
        return f"('{word}' not in render; first 200 chars: {render[:200]!r})"
    return render[max(0, idx - radius): idx + len(word) + radius]


def _query_state_reliable(ipc, max_attempts: int = 6) -> dict:
    """
    Retry wrapper around query_lls_state.

    observe_property can fire an initial null property-change notification that
    races with the Event object creation in mpv_ipc.py, causing wait_property_change
    to return before the lls-state-query handler has run.  Retrying with a short
    sleep resolves the race in practice.
    """
    last_exc = None
    for _ in range(max_attempts):
        try:
            return query_lls_state(ipc)
        except (RuntimeError, TimeoutError) as exc:
            last_exc = exc
            time.sleep(0.4)
    raise RuntimeError(f"lls state not available after {max_attempts} attempts: {last_exc}")


def _assert_phrase_mode(render: str, word: str) -> None:
    tag = _first_hl_tag_after(render, word)
    assert tag is not None, (
        f"'{word}' not found highlighted in drum render.\n"
        f"Snippet: {_snippet(render, word)!r}"
    )
    assert tag in ("c", "1c"), (
        f"'{word}' is in surgical mode (tag after word: {tag!r}); "
        f"expected phrase mode ('c' or '1c').\n"
        f"Snippet: {_snippet(render, word)!r}"
    )


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def mpv_fragment2_singles_first(tmp_path):
    """
    Fragment2 session whose TSV has the time-2.162 cluster in the reverse of the
    bug-triggering order: single-word records precede the phrase record.

      "Zeit"               (single)   ← now before phrase
      "Geld"               (single)   ← now before phrase
      "Geld und die Zeit"  (phrase)   ← now after singles

    This verifies order-invariance: even when phrases come last, highlighting is
    still correct (has_phrase stays True once set, OR never gets reset to False
    by a single that precedes the phrase).
    """
    with open(_TSV, encoding="utf-8") as fh:
        lines = fh.readlines()

    # Swap: put singles before the phrase within the same time-cluster block.
    reordered = (
        lines[:_IDX_PHRASE_GELD_UND_DIE_ZEIT]
        + [
            lines[_IDX_SINGLE_ZEIT],
            lines[_IDX_SINGLE_GELD],
            lines[_IDX_PHRASE_GELD_UND_DIE_ZEIT],
        ]
        + lines[_IDX_PHRASE_GELD_UND_DIE_ZEIT + 3:]
    )

    # Copy video into tmp_path so the Lua TSV-path derivation points to our TSV.
    dest_video = tmp_path / f"{_STEM}.mp4"
    shutil.copy2(_VIDEO, dest_video)
    with open(tmp_path / f"{_STEM}.tsv", "w", encoding="utf-8") as fh:
        fh.writelines(reordered)

    session = MpvSession(
        video=str(dest_video),
        subtitle=os.path.abspath(_DE_SRT),
        secondary_subtitle=os.path.abspath(_RU_SRT),
        extra_args=["--pause"],
    )
    session.start()
    yield session
    session.stop()


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

def test_has_phrase_phrase_first_order(mpv_fragment2):
    """
    Regression (bug-triggering TSV order): phrase record before single-word records.

    TSV rows for time 2.162 (current fixture order):
      "Geld und die Zeit"  (phrase)  ← comes FIRST
      "Zeit"               (single)  ← comes after phrase → used to reset has_phrase
      "Geld"               (single)  ← comes after phrase → used to reset has_phrase

    Before the fix, "Zeit" and "Geld" received surgical highlighting because the
    single-word records overwrote has_phrase=False.  After the fix they must receive
    full-word (phrase) highlighting.
    """
    ipc = mpv_fragment2.ipc

    ipc.command(["seek", _SUB2_SEEK, "absolute+exact"])
    time.sleep(0.4)

    state = _query_state_reliable(ipc)
    assert state["active_sub_index"] == 2, (
        f"Expected sub 2 active at {_SUB2_SEEK}s, got index {state['active_sub_index']}"
    )

    render = query_lls_render(ipc, "drum")
    assert render, "drum OSD returned empty render after seek"

    _assert_phrase_mode(render, "Zeit")
    _assert_phrase_mode(render, "Geld")


def test_has_phrase_singles_first_order(mpv_fragment2_singles_first):
    """
    Order-invariance: singles before phrase in TSV → must still produce phrase mode.

    TSV rows for time 2.162 (reversed fixture):
      "Zeit"               (single)  ← comes FIRST
      "Geld"               (single)
      "Geld und die Zeit"  (phrase)  ← comes LAST

    In this order has_phrase is set correctly even without the fix (phrase is last),
    but the test guards against regressions that might break this direction too.
    """
    ipc = mpv_fragment2_singles_first.ipc

    ipc.command(["seek", _SUB2_SEEK, "absolute+exact"])
    time.sleep(0.4)

    state = _query_state_reliable(ipc)
    assert state["active_sub_index"] == 2, (
        f"Expected sub 2 active at {_SUB2_SEEK}s, got index {state['active_sub_index']}"
    )

    render = query_lls_render(ipc, "drum")
    assert render, "drum OSD returned empty render after seek (singles-first fixture)"

    _assert_phrase_mode(render, "Zeit")
    _assert_phrase_mode(render, "Geld")
