"""
Feature ZID: 20260522162418
Test Creation ZID: 20260522162418
Feature: Tooltip Window Degradation Guard

Regression scope:
- Tooltip must render one shared background window (not a per-line background box per visual row).
- Tooltip text lines must stay independently positioned for accurate hit-zones.
"""

import json
import re
import time
from pathlib import Path

from tests.ipc.mpv_ipc import query_kardenwort_render


def _read_main_lua():
    return Path("scripts/kardenwort/main.lua").read_text(encoding="utf-8")


def _tooltip_function_body(src):
    start = src.find("local function draw_dw_tooltip")
    if start == -1:
        return ""
    end = src.find("local function dw_get_mouse_osd", start)
    if end == -1:
        end = start + 12000
    return src[start:end]


def _pin_tooltip_and_get_render(ipc, candidates):
    for x, y in candidates:
        ipc.command(["script-message-to", "kardenwort", "test-dw-tooltip-pin-at", str(x), str(y), '{"event":"down"}'])
        time.sleep(0.35)
        render = query_kardenwort_render(ipc, "tooltip")
        if render:
            return render
    return ""


def _query_tooltip_style_contract(ipc):
    ipc.command(["script-message-to", "kardenwort", "test-query-tooltip-style-contract"])
    time.sleep(0.15)
    raw = ipc.get_property("user-data/test-tooltip-style-contract")
    return json.loads(raw) if raw else {}


def test_tooltip_renderer_source_uses_shared_background_contract():
    src = _read_main_lua()
    body = _tooltip_function_body(src)
    assert body, "draw_dw_tooltip function not found"
    card_body = src[src.find("function format_tooltip_card_event"):src.find("function format_tooltip_text_event")]
    text_body = src[src.find("function format_tooltip_text_event"):src.find("local function draw_dw_tooltip")]

    assert "\\p1" in card_body, "Tooltip renderer must build a shared vector background window (\\p1)"
    assert "format_tooltip_card_event(style_ctx" in body
    assert "format_tooltip_text_event(style_ctx" in body
    assert "{\\\\an6}{\\\\bord%g}{\\\\shad%g}" in text_body
    assert "line_bgbox_neutral" not in body


def test_render_query_probe_exposes_mode_overlays():
    src = _read_main_lua()
    body = src[src.find('mp.register_script_message("render-query"'):src.find('mp.register_script_message("test-dw-tooltip-toggle"')]

    assert "drum    = drum_osd" in body
    assert "dw      = dw_osd" in body
    assert "tooltip = dw_tooltip_osd" in body


def test_tooltip_style_contract_probe_reports_dw_dm_srt_modes(mpv):
    ipc = mpv.ipc
    ipc.command(["set_property", "osd-border-style", "background-box"])
    time.sleep(0.2)

    contract = _query_tooltip_style_contract(ipc)

    assert set(contract) >= {"dw", "dm", "srt"}
    assert contract["dw"]["needs_override"] is True
    assert contract["dw"]["neutralize_inband"] is False
    assert contract["dm"]["needs_override"] is False
    assert contract["dm"]["neutralize_inband"] is True
    assert contract["srt"]["needs_override"] is False
    assert contract["srt"]["neutralize_inband"] is True

    for mode in ("dw", "dm", "srt"):
        assert "\\p1" in contract[mode]["card_ass"], f"{mode} must use measured card ASS"
        assert "{\\an6}" in contract[mode]["text_ass"], f"{mode} must use shared tooltip text ASS"

    assert contract["dw"]["card_alpha"] == contract["dw"]["bg_alpha"]
    assert contract["dm"]["card_alpha"] == "FF"
    assert contract["srt"]["card_alpha"] == "FF"
    assert "{\\3a&HFF&}{\\4a&HFF&}" not in contract["dw"]["text_ass"]
    assert "{\\3a&HFF&}{\\4a&HFF&}" in contract["dm"]["text_ass"]
    assert "{\\3a&HFF&}{\\4a&HFF&}" in contract["srt"]["text_ass"]


def test_dw_tooltip_renders_single_shared_background_window(mpv_fragment2):
    ipc = mpv_fragment2.ipc

    ipc.command(["set_property", "osd-border-style", "background-box"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_sec_highlighting", "no"])
    ipc.command(["script-message-to", "kardenwort", "test-dw-toggle"])
    time.sleep(1.0)
    ipc.command(["seek", "7.0", "absolute"])
    time.sleep(0.8)

    render = _pin_tooltip_and_get_render(ipc, [(960, 540), (960, 500), (960, 620)])
    ipc.command(["script-message-to", "kardenwort", "test-dw-tooltip-pin-at", "960", "540", '{"event":"up"}'])

    assert render != "", "Tooltip should render in DW mode"
    assert len(re.findall(r"\\p1", render)) == 1, "Tooltip must have exactly one shared background window"
    assert "{\\an6}" in render, "Tooltip text lines must use shared an6 alignment"
    assert "\\bord0}{\\shad0}{\\q2}" not in render, "Tooltip text must not regress to legacy zero-style ASS"


def test_srt_tooltip_renders_single_shared_background_window(mpv_dual):
    ipc = mpv_dual.ipc

    ipc.command(["set_property", "osd-border-style", "background-box"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "srt_font_size", "40"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_sec_highlighting", "no"])
    ipc.command(["script-message-to", "kardenwort", "test-dw-tooltip-toggle"])
    time.sleep(0.25)

    render = query_kardenwort_render(ipc, "tooltip")

    assert render != "", "Tooltip should render in SRT mode"
    assert len(re.findall(r"\\p1", render)) == 1, "Tooltip must have exactly one shared background window in SRT mode"
    assert "{\\an6}" in render, "Tooltip text lines must use shared an6 alignment"
    assert "{\\3a&HFF&}{\\4a&HFF&}" in render, "SRT tooltip text must neutralize native background-box frames"
