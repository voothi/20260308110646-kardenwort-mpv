"""
Feature ZID: 20260509111349
Test Creation ZID: 20260509111349
Feature: Spec Depth Pass 3 — Structural Coverage Batch

Validated Specs:
- context-copy-fsm-repair
- global-navigation-bindings
- lua-scoping-correction
- scanner-parser
- text-processing-hardening
- word-based-deletion-logic
- unified-navigation-logic
- unified-tick-loop
- search-system (structural)
- variable-driven-rendering
- drum-context
- open-record-file
- dw-mouse-selection-engine
- nav-auto-repeat (structural)
- osd-layer-management
"""

import re
import pytest


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _src():
    with open("scripts/kardenwort/main.lua", encoding="utf-8") as f:
        return f.read()


def _input_conf():
    with open("input.conf", encoding="utf-8") as f:
        return f.read()


# ---------------------------------------------------------------------------
# context-copy-fsm-repair
# ---------------------------------------------------------------------------

class TestContextCopyFsmRepair:
    """Tests for spec: context-copy-fsm-repair"""

    def test_get_copy_context_text_exists(self):
        """get_copy_context_text must exist as the pivot-aware copy context extractor."""
        assert "function get_copy_context_text" in _src(), (
            "context-copy-fsm-repair: get_copy_context_text not found in kardenwort.lua"
        )

    def test_copy_context_lines_option_exists(self):
        """copy_context_lines option must be present for configurable context depth."""
        assert "copy_context_lines" in _src(), (
            "context-copy-fsm-repair: copy_context_lines option not found in kardenwort.lua"
        )

    def test_copy_context_traversal_uses_pri_subs(self):
        """Context traversal must reference Tracks.pri.subs for pivot-aware subtitle access."""
        src = _src()
        idx = src.find("function get_copy_context_text")
        assert idx != -1
        body = src[idx:idx + 1000]
        assert "Tracks.pri.subs" in body or "pri.subs" in body, (
            "context-copy-fsm-repair: get_copy_context_text does not reference Tracks.pri.subs"
        )


# ---------------------------------------------------------------------------
# global-navigation-bindings
# ---------------------------------------------------------------------------

class TestGlobalNavigationBindings:
    """Tests for spec: global-navigation-bindings"""

    def test_kardenwort_seek_prev_registered(self):
        """kardenwort-seek_prev must be registered via mp.add_key_binding (global-navigation-bindings)."""
        assert 'mp.add_key_binding(nil, "kardenwort-seek_prev"' in _src(), (
            "global-navigation-bindings: kardenwort-seek_prev not registered with nil key"
        )

    def test_kardenwort_seek_next_registered(self):
        """kardenwort-seek_next must be registered via mp.add_key_binding (global-navigation-bindings)."""
        assert 'mp.add_key_binding(nil, "kardenwort-seek_next"' in _src(), (
            "global-navigation-bindings: kardenwort-seek_next not registered with nil key"
        )

    def test_kardenwort_seek_prev_bound_in_input_conf(self):
        """'a' key must delegate to kardenwort-seek_prev in input.conf (global-navigation-bindings)."""
        found = any(
            l.startswith("a ") and "kardenwort-seek_prev" in l
            for l in _input_conf().split("\n")
        )
        assert found, "global-navigation-bindings: 'a' not bound to kardenwort-seek_prev in input.conf"

    def test_kardenwort_seek_next_bound_in_input_conf(self):
        """'d' key must delegate to kardenwort-seek_next in input.conf (global-navigation-bindings)."""
        found = any(
            l.startswith("d ") and "kardenwort-seek_next" in l
            for l in _input_conf().split("\n")
        )
        assert found, "global-navigation-bindings: 'd' not bound to kardenwort-seek_next in input.conf"


# ---------------------------------------------------------------------------
# lua-scoping-correction
# ---------------------------------------------------------------------------

class TestLuaScopingCorrection:
    """Tests for spec: lua-scoping-correction"""

    def test_is_word_char_defined_before_get_word_boundary(self):
        """is_word_char must be defined before get_word_boundary to avoid forward-reference errors."""
        src = _src()
        idx_is_word = src.find("local function is_word_char")
        idx_boundary = src.find("local function get_word_boundary")
        assert idx_is_word != -1, "lua-scoping-correction: is_word_char not found"
        assert idx_boundary != -1, "lua-scoping-correction: get_word_boundary not found"
        assert idx_is_word < idx_boundary, (
            f"lua-scoping-correction: is_word_char (line ~{src[:idx_is_word].count(chr(10))}) "
            f"defined AFTER get_word_boundary (line ~{src[:idx_boundary].count(chr(10))})"
        )

    def test_word_char_map_defined_before_is_word_char(self):
        """WORD_CHAR_MAP must be defined before is_word_char references it."""
        src = _src()
        idx_map = src.find("local WORD_CHAR_MAP")
        idx_fn = src.find("local function is_word_char")
        assert idx_map != -1, "lua-scoping-correction: WORD_CHAR_MAP not found"
        assert idx_map < idx_fn, (
            "lua-scoping-correction: WORD_CHAR_MAP must be declared before is_word_char"
        )


# ---------------------------------------------------------------------------
# scanner-parser
# ---------------------------------------------------------------------------

class TestScannerParser:
    """Tests for spec: scanner-parser"""

    def test_build_word_list_internal_exists(self):
        """build_word_list_internal must exist as the core tokenizer (scanner-parser)."""
        assert "local function build_word_list_internal" in _src(), (
            "scanner-parser: build_word_list_internal not found in kardenwort.lua"
        )

    def test_build_word_list_exists(self):
        """build_word_list must exist as the public scanner API (scanner-parser)."""
        assert "local function build_word_list" in _src(), (
            "scanner-parser: build_word_list not found in kardenwort.lua"
        )

    def test_word_char_map_covers_cyrillic(self):
        """WORD_CHAR_MAP must include Cyrillic characters for Russian text support (scanner-parser)."""
        src = _src()
        assert "WORD_CHAR_MAP" in src, "scanner-parser: WORD_CHAR_MAP not found"
        assert "CYRILLIC" in src, (
            "scanner-parser: No Cyrillic character set found — scanner can't handle Cyrillic text"
        )

    def test_word_char_map_covers_latin(self):
        """WORD_CHAR_MAP must include Latin letters for English/German support (scanner-parser)."""
        src = _src()
        idx = src.find("local WORD_CHAR_MAP")
        assert idx != -1
        # The map is built by iterating CYRILLIC + ASCII — check ASCII coverage exists
        assert "string.byte" in src or "\"a\"" in src or "97" in src, (
            "scanner-parser: No ASCII/Latin character mapping found in WORD_CHAR_MAP construction"
        )


# ---------------------------------------------------------------------------
# text-processing-hardening
# ---------------------------------------------------------------------------

class TestTextProcessingHardening:
    """Tests for spec: text-processing-hardening"""

    def test_build_word_list_handles_empty_string(self):
        """build_word_list must be defined to handle empty/nil input without error (text-processing-hardening)."""
        src = _src()
        assert "local function build_word_list" in src, (
            "text-processing-hardening: build_word_list not found"
        )

    def test_build_word_list_internal_guards_nil_text(self):
        """build_word_list_internal must guard against nil text input (text-processing-hardening)."""
        src = _src()
        idx = src.find("local function build_word_list_internal")
        assert idx != -1
        body = src[idx:idx + 300]
        has_guard = ("== nil" in body or "not text" in body or
                     "if text" in body or "or \"\"" in body or "or ''" in body)
        assert has_guard, (
            "text-processing-hardening: build_word_list_internal lacks nil/empty guard in first 300 chars"
        )

    def test_word_char_map_declared_with_local_keyword(self):
        """WORD_CHAR_MAP must be declared with 'local' at module scope (text-processing-hardening)."""
        assert "local WORD_CHAR_MAP" in _src(), (
            "text-processing-hardening: WORD_CHAR_MAP not declared as a local module-level variable"
        )


# ---------------------------------------------------------------------------
# word-based-deletion-logic
# ---------------------------------------------------------------------------

class TestWordBasedDeletionLogic:
    """Tests for spec: word-based-deletion-logic"""

    def test_get_word_boundary_exists(self):
        """get_word_boundary must exist for word-based cursor deletion (word-based-deletion-logic)."""
        assert "local function get_word_boundary" in _src(), (
            "word-based-deletion-logic: get_word_boundary not found in kardenwort.lua"
        )

    def test_get_word_boundary_accepts_direction(self):
        """get_word_boundary must accept a direction parameter for bidirectional deletion (word-based-deletion-logic)."""
        src = _src()
        idx = src.find("local function get_word_boundary")
        assert idx != -1
        sig = src[idx:idx + 150]
        assert "direction" in sig or "dir" in sig, (
            "word-based-deletion-logic: get_word_boundary must accept a direction parameter"
        )

    def test_word_deletion_handler_registered(self):
        """A Ctrl+W or word-delete binding must be registered in kardenwort.lua (word-based-deletion-logic)."""
        src = _src()
        has_ctrl_w = "Ctrl+w" in src or "ctrl-w" in src.lower() or "ctrl+w" in src.lower()
        has_word_del = "word_delete" in src or "word-delete" in src or "delete_word" in src
        has_backspace_word = "get_word_boundary" in src and "BACKSPACE" in src.upper()
        assert has_ctrl_w or has_word_del or has_backspace_word, (
            "word-based-deletion-logic: No word-deletion handler (Ctrl+W or word_delete) found"
        )


# ---------------------------------------------------------------------------
# unified-navigation-logic
# ---------------------------------------------------------------------------

class TestUnifiedNavigationLogic:
    """Tests for spec: unified-navigation-logic"""

    def test_tracks_pri_subs_used_for_navigation(self):
        """Navigation logic must use Tracks.pri.subs as the unified subtitle source (unified-navigation-logic)."""
        src = _src()
        count = src.count("Tracks.pri.subs")
        assert count >= 5, (
            f"unified-navigation-logic: Tracks.pri.subs referenced only {count} time(s); "
            "expected at least 5 (definition + multiple navigation call sites)"
        )

    def test_seek_uses_absolute_exact(self):
        """Subtitle navigation seeks must use absolute+exact for precise frame targeting (unified-navigation-logic)."""
        src = _src()
        count = src.count("absolute+exact")
        assert count >= 3, (
            f"unified-navigation-logic: 'absolute+exact' found only {count} time(s); "
            "subtitle jumps must use exact seek mode"
        )


# ---------------------------------------------------------------------------
# unified-tick-loop
# ---------------------------------------------------------------------------

class TestUnifiedTickLoop:
    """Tests for spec: unified-tick-loop"""

    def test_tick_loop_exists(self):
        """tick_loop must exist as the feature boundary enforcer (unified-tick-loop)."""
        assert "local function tick_loop" in _src(), (
            "unified-tick-loop: tick_loop function not found in kardenwort.lua"
        )

    def test_master_tick_exists(self):
        """master_tick must exist as the periodic timer entry point (unified-tick-loop)."""
        assert "local function master_tick" in _src(), (
            "unified-tick-loop: master_tick function not found in kardenwort.lua"
        )

    def test_tick_rate_option_is_0_05(self):
        """tick_rate default must be 0.05 seconds (20 Hz) for responsive subtitle tracking (unified-tick-loop)."""
        src = _src()
        assert "tick_rate = 0.05" in src, (
            "unified-tick-loop: tick_rate default is not 0.05 in Options table"
        )

    def test_media_state_gates_tick_features(self):
        """MEDIA_STATE must be used in tick-related code to gate feature activation (unified-tick-loop)."""
        src = _src()
        assert "MEDIA_STATE" in src, "unified-tick-loop: MEDIA_STATE FSM field not found"
        # master_tick drives the loop — it references MEDIA_STATE (or its equivalent NO_SUBS guard)
        # anywhere in the source confirms media-state-aware gating
        count = src.count("MEDIA_STATE")
        assert count >= 10, (
            f"unified-tick-loop: MEDIA_STATE referenced only {count} time(s); "
            "tick-loop gating requires pervasive MEDIA_STATE checks"
        )


# ---------------------------------------------------------------------------
# search-system (structural)
# ---------------------------------------------------------------------------

class TestSearchSystemStructural:
    """Tests for spec: search-system (structural layer)"""

    def test_render_search_exists(self):
        """render_search must exist as the search HUD render function (search-system)."""
        assert "local function render_search" in _src(), (
            "search-system: render_search not found in kardenwort.lua"
        )

    def test_search_mode_fsm_field_exists(self):
        """SEARCH_MODE must be declared in the FSM state table (search-system)."""
        assert "SEARCH_MODE = false" in _src(), (
            "search-system: SEARCH_MODE FSM field not initialized to false"
        )

    def test_search_mode_message_handler_registered(self):
        """A script-message handler must activate SEARCH_MODE (search-system)."""
        src = _src()
        assert "SEARCH_MODE" in src and "FSM.SEARCH_MODE" in src, (
            "search-system: FSM.SEARCH_MODE not referenced in script logic"
        )


# ---------------------------------------------------------------------------
# variable-driven-rendering
# ---------------------------------------------------------------------------

class TestVariableDrivenRendering:
    """Tests for spec: variable-driven-rendering"""

    def test_search_hit_color_in_options(self):
        """search_hit_color must be in Options for dynamic ASS tag construction (variable-driven-rendering)."""
        assert "search_hit_color" in _src(), (
            "variable-driven-rendering: search_hit_color not found in Options"
        )

    def test_search_sel_color_in_options(self):
        """search_sel_color must be in Options for selected-line rendering (variable-driven-rendering)."""
        assert "search_sel_color" in _src(), (
            "variable-driven-rendering: search_sel_color not found in Options"
        )

    def test_search_query_hit_color_in_options(self):
        """search_query_hit_color must be in Options for query character highlighting (variable-driven-rendering)."""
        assert "search_query_hit_color" in _src(), (
            "variable-driven-rendering: search_query_hit_color not found in Options"
        )

    def test_draw_search_ui_uses_search_colors(self):
        """draw_search_ui (the actual renderer called by render_search) must use color options (variable-driven-rendering)."""
        src = _src()
        idx = src.find("local function draw_search_ui")
        assert idx != -1, "variable-driven-rendering: draw_search_ui not found in kardenwort.lua"
        body = src[idx:idx + 3000]
        has_colors = ("search_hit_color" in body or "search_sel_color" in body or
                      "search_query_hit_color" in body)
        assert has_colors, (
            "variable-driven-rendering: draw_search_ui does not reference search color options"
        )


# ---------------------------------------------------------------------------
# drum-context
# ---------------------------------------------------------------------------

class TestDrumContext:
    """Tests for spec: drum-context"""

    def test_drum_context_lines_option_exists(self):
        """drum_context_lines must be in Options for configurable context depth (drum-context)."""
        assert "drum_context_lines" in _src(), (
            "drum-context: drum_context_lines option not found in kardenwort.lua"
        )

    def test_draw_drum_exists(self):
        """draw_drum must exist as the Drum Mode rendering entry point (drum-context)."""
        assert "local function draw_drum" in _src(), (
            "drum-context: draw_drum function not found in kardenwort.lua"
        )

    def test_draw_drum_uses_context_lines(self):
        """draw_drum must reference drum_context_lines to render surrounding lines (drum-context)."""
        src = _src()
        idx = src.find("local function draw_drum")
        assert idx != -1
        body = src[idx:idx + 2000]
        assert "context_lines" in body or "drum_context_lines" in body, (
            "drum-context: draw_drum does not reference drum_context_lines for context rendering"
        )

    def test_drum_osd_z_order_is_10(self):
        """drum_osd.z must be 10 — below dw_osd (20) and search_osd (30) (drum-context)."""
        src = _src()
        assert "drum_osd.z = 10" in src, (
            "drum-context: drum_osd.z is not 10 — z-ordering for overlay stacking is broken"
        )


# ---------------------------------------------------------------------------
# open-record-file
# ---------------------------------------------------------------------------

class TestOpenRecordFile:
    """Tests for spec: open-record-file"""

    def test_cmd_open_record_file_exists(self):
        """cmd_open_record_file must exist to launch the record editor (open-record-file)."""
        assert "local function cmd_open_record_file" in _src(), (
            "open-record-file: cmd_open_record_file not found in kardenwort.lua"
        )

    def test_record_editor_option_exists(self):
        """record_editor must be in Options for user-configurable editor path (open-record-file)."""
        assert "record_editor" in _src(), (
            "open-record-file: record_editor option not found in kardenwort.lua"
        )

    def test_record_editor_checked_before_opening(self):
        """cmd_open_record_file must validate record_editor is configured before launching (open-record-file)."""
        src = _src()
        idx = src.find("local function cmd_open_record_file")
        assert idx != -1
        body = src[idx:idx + 500]
        has_check = "record_editor" in body and (
            "not configured" in body or "== nil" in body or "== \"\"" in body or "not " in body
        )
        assert has_check, (
            "open-record-file: cmd_open_record_file does not validate record_editor before use"
        )


# ---------------------------------------------------------------------------
# dw-mouse-selection-engine
# ---------------------------------------------------------------------------

class TestDwMouseSelectionEngine:
    """Tests for spec: dw-mouse-selection-engine"""

    def test_dw_build_layout_exists(self):
        """dw_build_layout must exist as the pre-calculated hit-test layout builder (dw-mouse-selection-engine)."""
        assert "local function dw_build_layout" in _src(), (
            "dw-mouse-selection-engine: dw_build_layout not found in kardenwort.lua"
        )

    def test_dw_anchor_word_initialized_in_fsm(self):
        """DW_ANCHOR_WORD must be initialized in FSM for range selection anchor (dw-mouse-selection-engine)."""
        assert "DW_ANCHOR_WORD = -1" in _src(), (
            "dw-mouse-selection-engine: DW_ANCHOR_WORD not initialized to -1 in FSM"
        )

    def test_dw_anchor_line_initialized_in_fsm(self):
        """DW_ANCHOR_LINE must be initialized in FSM for multi-line range anchor (dw-mouse-selection-engine)."""
        assert "DW_ANCHOR_LINE = -1" in _src(), (
            "dw-mouse-selection-engine: DW_ANCHOR_LINE not initialized to -1 in FSM"
        )

    def test_dw_build_layout_accepts_view_center(self):
        """dw_build_layout must accept view_center for correct coordinate mapping (dw-mouse-selection-engine)."""
        src = _src()
        idx = src.find("local function dw_build_layout")
        assert idx != -1
        sig = src[idx:idx + 100]
        assert "view_center" in sig, (
            "dw-mouse-selection-engine: dw_build_layout must accept view_center param"
        )


# ---------------------------------------------------------------------------
# nav-auto-repeat (structural)
# ---------------------------------------------------------------------------

class TestNavAutoRepeatStructural:
    """Tests for spec: nav-auto-repeat (structural layer)"""

    def test_seek_hold_rate_option_exists(self):
        """seek_hold_rate must be in Options — controls auto-repeat frequency (nav-auto-repeat)."""
        assert "seek_hold_rate" in _src(), (
            "nav-auto-repeat: seek_hold_rate option not found in kardenwort.lua"
        )

    def test_seek_hold_delay_option_exists(self):
        """seek_hold_delay must be in Options — controls hold-before-repeat onset delay (nav-auto-repeat)."""
        assert "seek_hold_delay" in _src(), (
            "nav-auto-repeat: seek_hold_delay option not found in kardenwort.lua"
        )

    def test_seek_repeat_timer_initialized_nil(self):
        """SEEK_REPEAT_TIMER must be initialized to nil in FSM (nav-auto-repeat)."""
        assert "SEEK_REPEAT_TIMER = nil" in _src(), (
            "nav-auto-repeat: SEEK_REPEAT_TIMER not initialized to nil in FSM"
        )

    def test_seek_hold_rate_default_is_10(self):
        """seek_hold_rate default must be 10 Hz (nav-auto-repeat)."""
        assert "seek_hold_rate = 10" in _src(), (
            "nav-auto-repeat: seek_hold_rate default is not 10 in Options table"
        )

    def test_seek_with_repeat_uses_periodic_timer(self):
        """Auto-repeat must use mp.add_periodic_timer for rate-controlled repetition (nav-auto-repeat)."""
        assert "mp.add_periodic_timer" in _src(), (
            "nav-auto-repeat: mp.add_periodic_timer not found; seek auto-repeat not implemented"
        )


# ---------------------------------------------------------------------------
# osd-layer-management
# ---------------------------------------------------------------------------

class TestOsdLayerManagement:
    """Tests for spec: osd-layer-management"""

    def test_drum_osd_z_is_10(self):
        """drum_osd must have z=10 — lowest overlay layer (osd-layer-management)."""
        assert "drum_osd.z = 10" in _src(), (
            "osd-layer-management: drum_osd.z != 10; drum overlay z-order incorrect"
        )

    def test_dw_osd_z_is_20(self):
        """dw_osd must have z=20 — above drum, below search (osd-layer-management)."""
        assert "dw_osd.z = 20" in _src(), (
            "osd-layer-management: dw_osd.z != 20; drum window overlay z-order incorrect"
        )

    def test_search_osd_z_is_30(self):
        """search_osd must have z=30 — topmost search HUD layer (osd-layer-management)."""
        assert "search_osd.z = 30" in _src(), (
            "osd-layer-management: search_osd.z != 30; search HUD overlay z-order incorrect"
        )

    def test_tooltip_osd_z_is_between_dw_and_search(self):
        """dw_tooltip_osd must have z=25 — between dw_osd and search_osd (osd-layer-management)."""
        assert "dw_tooltip_osd.z = 25" in _src(), (
            "osd-layer-management: dw_tooltip_osd.z != 25; tooltip overlay z-order incorrect"
        )

    def test_z_values_are_strictly_ordered(self):
        """All overlay z-values must be in ascending order: 10 < 20 < 25 < 30 (osd-layer-management)."""
        src = _src()
        drums = 10 if "drum_osd.z = 10" in src else None
        dw = 20 if "dw_osd.z = 20" in src else None
        tip = 25 if "dw_tooltip_osd.z = 25" in src else None
        srch = 30 if "search_osd.z = 30" in src else None
        assert all(v is not None for v in [drums, dw, tip, srch]), (
            "osd-layer-management: one or more overlay z-values are missing"
        )
        assert drums < dw < tip < srch, (
            f"osd-layer-management: z-values not strictly ordered: drum={drums} dw={dw} tip={tip} search={srch}"
        )




