"""
Feature ZID: 20260522162418
Test Creation ZID: 20260522162418
Feature: Tooltip Window Degradation Guard

Regression scope:
- Tooltip must render one shared background window (not a per-line background box per visual row).
- Tooltip text lines must stay independently positioned for accurate hit-zones.
"""

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


def test_tooltip_renderer_source_uses_shared_background_contract():
    src = _read_main_lua()
    body = _tooltip_function_body(src)
    assert body, "draw_dw_tooltip function not found"

    assert "\\p1" in body, "Tooltip renderer must build a shared vector background window (\\p1)"
    assert r"{\\an6}{\\bord0}{\\shad0}{\\q2}" in body, (
        "Tooltip text lines must be rendered without per-line background boxes"
    )
    assert r"{\\an6}{\\bord%g}{\\shad%g}{\\3c&H%s&}{\\4c&H%s&}{\\3a&H%s&}{\\4a&H%s&}{\\q2}" not in body, (
        "Legacy per-line tooltip background style must not be present"
    )


def test_dw_tooltip_renders_single_shared_background_window(mpv_fragment2):
    ipc = mpv_fragment2.ipc

    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_sec_highlighting", "no"])
    ipc.command(["script-message-to", "kardenwort", "test-dw-toggle"])
    time.sleep(1.0)
    ipc.command(["seek", "7.0", "absolute"])
    time.sleep(0.8)

    render = _pin_tooltip_and_get_render(ipc, [(960, 540), (960, 500), (960, 620)])
    ipc.command(["script-message-to", "kardenwort", "test-dw-tooltip-pin-at", "960", "540", '{"event":"up"}'])

    assert render != "", "Tooltip should render in DW mode"
    assert len(re.findall(r"\\p1", render)) == 1, "Tooltip must have exactly one shared background window"
    assert "{\\an6}{\\bord0}{\\shad0}{\\q2}" in render, "Tooltip text lines must use zero border/shadow style"


def test_srt_tooltip_renders_single_shared_background_window(mpv_dual):
    ipc = mpv_dual.ipc

    ipc.command(["script-message-to", "kardenwort", "test-set-option", "srt_font_size", "40"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_sec_highlighting", "no"])
    ipc.command(["script-message-to", "kardenwort", "test-dw-tooltip-toggle"])
    time.sleep(0.25)

    render = query_kardenwort_render(ipc, "tooltip")

    assert render != "", "Tooltip should render in SRT mode"
    assert len(re.findall(r"\\p1", render)) == 1, "Tooltip must have exactly one shared background window in SRT mode"
    assert "{\\an6}{\\bord0}{\\shad0}{\\q2}" in render, "Tooltip text lines must use zero border/shadow style"
