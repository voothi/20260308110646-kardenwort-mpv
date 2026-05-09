"""
Feature ZID: 20260509090125
Test Creation ZID: 20260509113830
Feature: Mouse Isotropic Scaling

Structural tests verifying the isotropic mouse-coordinate mapping and drum-window
hit-zone infrastructure in lls_core.lua.
The IPC test handler (lls-test-mouse-logic) is not implemented, so these tests
validate the scaling formulas and hit-zone data structures directly from source.
"""

import re
import pytest
import time

from tests.ipc.mpv_ipc import query_lls_state


LUA = "scripts/lls_core.lua"


def _lua():
    with open(LUA, encoding="utf-8") as f:
        return f.read()


def test_mouse_isotropic_scaling():
    """
    ASS rendering preserves aspect ratio via height-based (isotropic) scaling.
    Verify the formula: scale_isotropic = oh / 1080, osd_x = 960 + (mx - ow/2) / scale_isotropic.
    """
    content = _lua()
    assert "scale_isotropic" in content, (
        "scale_isotropic variable not found; isotropic mouse scaling not implemented"
    )
    assert re.search(r"scale_isotropic\s*=\s*oh\s*/\s*1080", content), (
        "Isotropic scale formula (oh / 1080) not found in lls_core.lua"
    )
    assert re.search(r"osd_x\s*=\s*960\s*\+", content), (
        "osd_x = 960 + ... formula not found; OSD-space X mapping is missing"
    )
    assert re.search(r"osd_y\s*=\s*my\s*/\s*scale_isotropic", content), (
        "osd_y = my / scale_isotropic formula not found"
    )


def test_drum_window_hit_test():
    """
    Drum Window must maintain a per-line Y-position map (DW_LINE_Y_MAP) used for
    hit-zone resolution when the user clicks inside the drum window.
    """
    content = _lua()
    assert "DW_LINE_Y_MAP" in content, (
        "DW_LINE_Y_MAP not found; drum-window hit-zone tracking not implemented"
    )
    # Map is populated during rendering
    assert content.count("DW_LINE_Y_MAP") >= 2, (
        "DW_LINE_Y_MAP appears only once; it must be both initialised and populated"
    )
    # Hit-zone metadata must also be tracked
    assert "DW_TOOLTIP_HIT_ZONES" in content, (
        "DW_TOOLTIP_HIT_ZONES not found; word-level hit zone tracking is missing"
    )
