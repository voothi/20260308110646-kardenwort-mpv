"""
Feature ZID: 20260605112241
Test Creation ZID: 20260605112241
Feature: DM secondary track edge selection scrolling
"""

import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state


def _src():
    with open("scripts/kardenwort/main.lua", encoding="utf-8") as f:
        return f.read()


def _fn_body(src: str, fn_name: str) -> str:
    start = src.find(f"function {fn_name}(")
    if start == -1:
        start = src.find(f"local function {fn_name}(")
    assert start != -1, f"{fn_name} not found"
    end = src.find("\nfunction ", start + 1)
    local_end = src.find("\nlocal function ", start + 1)
    if end == -1 or (local_end != -1 and local_end < end):
        end = local_end
    return src[start:end if end != -1 else start + 8000]


def test_dw_drag_is_pri_fsm_initialization():
    """
    Ensure DW_DRAG_IS_PRI is initialized in FSM.
    """
    src = _src()
    assert "DW_DRAG_IS_PRI = true" in src


def test_dw_get_auto_scroll_block_zones_signature():
    """
    Ensure dw_get_auto_scroll_block_zones signature includes is_pri.
    """
    src = _src()
    assert "function dw_get_auto_scroll_block_zones(hit_zones, dm_mode, is_pri)" in src
    body = _fn_body(src, "dw_get_auto_scroll_block_zones")
    assert "local target_is_pri = (is_pri ~= false)" in body
    assert "zone.is_pri == target_is_pri" in body


def test_dw_mouse_auto_scroll_passes_is_pri():
    """
    Ensure dw_mouse_auto_scroll passes FSM.DW_DRAG_IS_PRI.
    """
    src = _src()
    body = _fn_body(src, "dw_mouse_auto_scroll")
    assert "dw_get_auto_scroll_block_zones(hit_zones, dm_mode, FSM.DW_DRAG_IS_PRI)" in body


def test_kardenwort_hit_test_all_returns_is_pri():
    """
    Ensure kardenwort_hit_test_all returns is_pri as third value.
    """
    src = _src()
    body = _fn_body(src, "kardenwort_hit_test_all")
    assert "return l, w, false" in body
    assert "return l, w, true" in body
    assert "return line, word, hit_pri" in body


def test_make_mouse_handler_sets_dw_drag_is_pri():
    """
    Ensure make_mouse_handler sets FSM.DW_DRAG_IS_PRI.
    """
    src = _src()
    body = _fn_body(src, "make_mouse_handler")
    assert "local line_idx, word_idx, is_pri = kardenwort_hit_test_all(osd_x, osd_y)" in body
    assert "FSM.DW_DRAG_IS_PRI = is_pri" in body
