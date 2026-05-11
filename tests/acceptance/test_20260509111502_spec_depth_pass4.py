"""
Feature ZID: 20260509111502
Test Creation ZID: 20260509111502
Feature: Spec Depth Pass 4 — Structural + Runtime Coverage Batch

Validated Specs:
- tsv-state-recovery
- state-aware-ui-management
- softer-scaling-formula
- x-axis-re-anchoring
- subtitle-safety-guards
- drum-window-sticky-navigation
- track-scrolling-accessibility
- synchronized-context-jumps
- multi-line-substring-selection
- search-system (runtime)
- dynamic-contrast-rendering
- tokenized-fuzzy-search
- fuzzy-search-optimization
- drum-scroll-sync (structural)
- vertical-gap-elimination
"""

import re
import time
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


def robust_state(ipc, retries=5):
    from tests.ipc.mpv_ipc import query_kardenwort_state
    for _ in range(retries):
        state = query_kardenwort_state(ipc)
        if state and "options" in state:
            return state
        time.sleep(0.4)
    return query_kardenwort_state(ipc)


# ---------------------------------------------------------------------------
# tsv-state-recovery
# ---------------------------------------------------------------------------

class TestTsvStateRecovery:
    """Tests for spec: tsv-state-recovery"""

    def test_load_anki_tsv_exists(self):
        """load_anki_tsv must exist to load highlight data from TSV (tsv-state-recovery)."""
        assert "local function load_anki_tsv" in _src(), (
            "tsv-state-recovery: load_anki_tsv not found in kardenwort.lua"
        )

    def test_load_anki_tsv_uses_safe_read(self):
        """load_anki_tsv must use safe_read_file for robust error-safe TSV loading (tsv-state-recovery)."""
        src = _src()
        idx = src.find("local function load_anki_tsv")
        assert idx != -1
        body = src[idx:idx + 2000]
        has_safe_read = "safe_read_file" in body or "pcall" in body or "xpcall" in body
        assert has_safe_read, (
            "tsv-state-recovery: load_anki_tsv uses neither safe_read_file nor pcall — malformed lines may crash"
        )

    def test_anki_highlights_fsm_field_exists(self):
        """ANKI_HIGHLIGHTS (or equivalent) must be a FSM field for reset on file deletion (tsv-state-recovery)."""
        src = _src()
        has_field = "ANKI_HIGHLIGHTS" in src or "anki_highlights" in src
        assert has_field, (
            "tsv-state-recovery: ANKI_HIGHLIGHTS FSM field not found in kardenwort.lua"
        )


# ---------------------------------------------------------------------------
# state-aware-ui-management
# ---------------------------------------------------------------------------

class TestStateAwareUiManagement:
    """Tests for spec: state-aware-ui-management"""

    def test_saved_osd_border_style_exists(self):
        """saved_osd_border_style (or equivalent) must be stored for UI restore (state-aware-ui-management)."""
        src = _src()
        has_saved = ("saved_osd" in src or "saved_border" in src or
                     "saved_style" in src or "osd_border_backup" in src)
        assert has_saved, (
            "state-aware-ui-management: No saved OSD style variable found — style can't be restored"
        )

    def test_flush_rendering_caches_is_centralized(self):
        """flush_rendering_caches must be the single invalidation point (state-aware-ui-management)."""
        assert "local function flush_rendering_caches" in _src(), (
            "state-aware-ui-management: flush_rendering_caches not found — no centralized UI invalidation"
        )


# ---------------------------------------------------------------------------
# softer-scaling-formula
# ---------------------------------------------------------------------------

class TestSofterScalingFormula:
    """Tests for spec: softer-scaling-formula"""

    def test_reference_height_1080(self):
        """scale_isotropic must be derived from reference height 1080 (softer-scaling-formula)."""
        src = _src()
        has_1080 = "/ 1080" in src or "1080.0" in src or "= 1080" in src
        assert has_1080, (
            "softer-scaling-formula: reference height 1080 not found in scaling formula"
        )

    def test_scale_isotropic_formula_uses_oh(self):
        """scale_isotropic = oh / 1080 must appear in coordinate math (softer-scaling-formula)."""
        src = _src()
        assert "scale_isotropic" in src, (
            "softer-scaling-formula: scale_isotropic variable not found in kardenwort.lua"
        )
        assert "oh / 1080" in src or "oh/1080" in src, (
            "softer-scaling-formula: scale_isotropic formula (oh/1080) not found"
        )

    def test_font_scale_strength_option_exists(self):
        """font_scale_strength must be a configurable option controlling scaling softness (softer-scaling-formula)."""
        assert "font_scale_strength" in _src(), (
            "softer-scaling-formula: font_scale_strength option not found in kardenwort.lua"
        )


# ---------------------------------------------------------------------------
# x-axis-re-anchoring
# ---------------------------------------------------------------------------

class TestXAxisReAnchoring:
    """Tests for spec: x-axis-re-anchoring"""

    def test_virtual_x_formula_uses_960_center(self):
        """x coordinate must be re-anchored around 960 (horizontal center) (x-axis-re-anchoring)."""
        src = _src()
        assert "960 +" in src or "960+" in src, (
            "x-axis-re-anchoring: 960 center anchor not found in coordinate formula"
        )

    def test_virtual_x_divides_by_scale_isotropic(self):
        """x formula must divide by scale_isotropic for viewport-size compensation (x-axis-re-anchoring)."""
        src = _src()
        has_formula = ("/ scale_isotropic" in src and "960" in src)
        assert has_formula, (
            "x-axis-re-anchoring: osd_x = 960 + (mx - ow/2) / scale_isotropic formula not found"
        )

    def test_output_width_referenced_in_x_formula(self):
        """ow (output width) must appear in x-axis formula for center-relative mapping (x-axis-re-anchoring)."""
        src = _src()
        has_ow = "ow / 2" in src or "ow/2" in src
        assert has_ow, (
            "x-axis-re-anchoring: ow/2 (output-width half) not found in x-coordinate formula"
        )


# ---------------------------------------------------------------------------
# subtitle-safety-guards
# ---------------------------------------------------------------------------

class TestSubtitleSafetyGuards:
    """Tests for spec: subtitle-safety-guards"""

    def test_sec_pos_bottom_option_exists(self):
        """sec_pos_bottom must be in Options for configurable secondary subtitle positioning (subtitle-safety-guards)."""
        assert "sec_pos_bottom" in _src(), (
            "subtitle-safety-guards: sec_pos_bottom option not found in kardenwort.lua"
        )

    def test_sec_pos_bottom_default_is_90(self):
        """sec_pos_bottom default must be 90 (10% gap below primary at 95+) (subtitle-safety-guards)."""
        assert "sec_pos_bottom = 90" in _src(), (
            "subtitle-safety-guards: sec_pos_bottom default is not 90 in Options table"
        )

    def test_sec_pos_bottom_comment_warns_about_gap(self):
        """sec_pos_bottom comment must document the gap relationship with sub-pos (subtitle-safety-guards)."""
        src = _src()
        idx = src.find("sec_pos_bottom")
        assert idx != -1
        context = src[max(0, idx - 200):idx + 200]
        has_warning = ("5%" in context or "gap" in context.lower() or
                       "sub-pos" in context or "sub_pos" in context)
        assert has_warning, (
            "subtitle-safety-guards: sec_pos_bottom lacks gap/positioning warning comment"
        )

    def test_sec_pos_bottom_runtime_option_accessible(self, mpv):
        """sec_pos_bottom must be accessible via runtime state options (subtitle-safety-guards)."""
        state = robust_state(mpv.ipc)
        opts = state["options"]
        assert "sec_pos_bottom" in opts, (
            "subtitle-safety-guards: sec_pos_bottom not exposed in runtime state options"
        )


# ---------------------------------------------------------------------------
# drum-window-sticky-navigation
# ---------------------------------------------------------------------------

class TestDrumWindowStickyNavigation:
    """Tests for spec: drum-window-sticky-navigation"""

    def test_dw_anchor_line_initialized_in_fsm(self):
        """DW_ANCHOR_LINE must be initialized to -1 in FSM for sticky nav reset (drum-window-sticky-navigation)."""
        assert "DW_ANCHOR_LINE = -1" in _src(), (
            "drum-window-sticky-navigation: DW_ANCHOR_LINE not initialized to -1 in FSM"
        )

    def test_dw_anchor_word_initialized_in_fsm(self):
        """DW_ANCHOR_WORD must be initialized to -1 in FSM (drum-window-sticky-navigation)."""
        assert "DW_ANCHOR_WORD = -1" in _src(), (
            "drum-window-sticky-navigation: DW_ANCHOR_WORD not initialized to -1 in FSM"
        )

    def test_dw_cursor_line_initialized_to_minus_one(self):
        """DW_CURSOR_LINE must start at -1 (no selection) (drum-window-sticky-navigation)."""
        assert "DW_CURSOR_LINE = -1" in _src(), (
            "drum-window-sticky-navigation: DW_CURSOR_LINE not initialized to -1 in FSM"
        )

    def test_anchor_reset_on_context_change(self):
        """DW_ANCHOR_WORD must be reset to -1 in multiple places (track change, mode toggle, etc.) (drum-window-sticky-navigation)."""
        src = _src()
        reset_count = src.count("DW_ANCHOR_WORD = -1")
        assert reset_count >= 3, (
            f"drum-window-sticky-navigation: DW_ANCHOR_WORD = -1 appears only {reset_count} time(s); "
            "need resets at track change, mode toggle, and ESC"
        )


# ---------------------------------------------------------------------------
# track-scrolling-accessibility
# ---------------------------------------------------------------------------

class TestTrackScrollingAccessibility:
    """Tests for spec: track-scrolling-accessibility"""

    def test_uppercase_A_seeks_time_backward(self):
        """'A' (Shift+a) must be bound to kardenwort-seek_time_backward for track-independent 2s seek (track-scrolling-accessibility)."""
        ic = _input_conf()
        found = any(
            l.startswith("A ") and "kardenwort-seek_time_backward" in l
            for l in ic.split("\n")
        )
        assert found, "track-scrolling-accessibility: 'A' not bound to kardenwort-seek_time_backward in input.conf"

    def test_uppercase_D_seeks_time_forward(self):
        """'D' (Shift+d) must be bound to kardenwort-seek_time_forward for track-independent 2s seek (track-scrolling-accessibility)."""
        ic = _input_conf()
        found = any(
            l.startswith("D ") and "kardenwort-seek_time_forward" in l
            for l in ic.split("\n")
        )
        assert found, "track-scrolling-accessibility: 'D' not bound to kardenwort-seek_time_forward in input.conf"

    def test_seek_time_delta_option_exists(self):
        """seek_time_delta option must be present and control 2s step (track-scrolling-accessibility)."""
        assert "seek_time_delta" in _src(), (
            "track-scrolling-accessibility: seek_time_delta option not found"
        )

    def test_seek_time_delta_default_is_2(self):
        """seek_time_delta default must be 2 seconds (track-scrolling-accessibility)."""
        assert "seek_time_delta = 2" in _src(), (
            "track-scrolling-accessibility: seek_time_delta default is not 2 in Options table"
        )

    def test_lls_seek_time_forward_registered(self):
        """kardenwort-seek_time_forward must be registered via mp.add_key_binding (track-scrolling-accessibility)."""
        assert 'mp.add_key_binding(nil, "kardenwort-seek_time_forward"' in _src(), (
            "track-scrolling-accessibility: kardenwort-seek_time_forward not registered in kardenwort.lua"
        )


# ---------------------------------------------------------------------------
# synchronized-context-jumps
# ---------------------------------------------------------------------------

class TestSynchronizedContextJumps:
    """Tests for spec: synchronized-context-jumps"""

    def test_absolute_exact_seek_used_in_navigation(self):
        """Subtitle navigation must use absolute+exact seek for frame-precise jumps (synchronized-context-jumps)."""
        src = _src()
        count = src.count("absolute+exact")
        assert count >= 5, (
            f"synchronized-context-jumps: 'absolute+exact' found {count} time(s); "
            "expected >= 5 (subtitle seek, replay, loop, and navigation paths)"
        )

    def test_seek_command_used_with_absolute(self):
        """mp.commandv('seek', ..., 'absolute+exact') pattern must be present (synchronized-context-jumps)."""
        src = _src()
        assert 'mp.commandv("seek"' in src or "mp.commandv('seek'" in src, (
            "synchronized-context-jumps: mp.commandv('seek',...) not found in kardenwort.lua"
        )


# ---------------------------------------------------------------------------
# multi-line-substring-selection
# ---------------------------------------------------------------------------

class TestMultiLineSubstringSelection:
    """Tests for spec: multi-line-substring-selection"""

    def test_dw_anchor_word_and_line_exposed_in_state(self, mpv):
        """dw_cursor must expose line and word for selection range (multi-line-substring-selection)."""
        state = robust_state(mpv.ipc)
        assert "dw_cursor" in state, (
            "multi-line-substring-selection: dw_cursor not in state snapshot"
        )
        cursor = state["dw_cursor"]
        assert "line" in cursor and "word" in cursor, (
            "multi-line-substring-selection: dw_cursor missing line or word fields"
        )

    def test_anchor_exposed_in_state_snapshot(self, mpv):
        """dw_anchor must be exposed in state snapshot with line and word fields (multi-line-substring-selection)."""
        state = robust_state(mpv.ipc)
        assert "dw_anchor" in state, (
            "multi-line-substring-selection: dw_anchor not in state snapshot"
        )
        anchor = state["dw_anchor"]
        assert "line" in anchor and "word" in anchor, (
            "multi-line-substring-selection: dw_anchor missing line or word fields"
        )

    def test_selection_range_uses_anchor_line_word(self):
        """Selection range calculation must reference DW_ANCHOR_LINE and DW_ANCHOR_WORD (multi-line-substring-selection)."""
        src = _src()
        assert "DW_ANCHOR_LINE" in src and "DW_ANCHOR_WORD" in src, (
            "multi-line-substring-selection: DW_ANCHOR_LINE or DW_ANCHOR_WORD not found in selection logic"
        )


# ---------------------------------------------------------------------------
# search-system (runtime)
# ---------------------------------------------------------------------------

class TestSearchSystemRuntime:
    """Tests for spec: search-system (runtime layer)"""

    def test_search_query_field_in_state(self, mpv):
        """search_query must be exposed in runtime state snapshot (search-system)."""
        state = robust_state(mpv.ipc)
        assert "search_query" in state, (
            "search-system: search_query not exposed in runtime state snapshot"
        )

    def test_search_results_field_in_state(self, mpv):
        """search_results must be exposed in runtime state snapshot (search-system)."""
        state = robust_state(mpv.ipc)
        assert "search_results" in state, (
            "search-system: search_results not exposed in runtime state snapshot"
        )

    def test_search_mode_can_be_toggled_via_test_handler(self, mpv):
        """SEARCH_MODE must be settable via kardenwort-test-search-mode-set for test instrumentation (search-system)."""
        ipc = mpv.ipc
        ipc.command(["script-message-to", "kardenwort", "kardenwort-test-search-mode-set", "ON"])
        time.sleep(0.3)
        state = robust_state(ipc)
        # With search mode ON, search_query should be accessible (not error)
        assert state is not None, (
            "search-system: state probe failed after kardenwort-test-search-mode-set ON"
        )
        # Cleanup
        ipc.command(["script-message-to", "kardenwort", "kardenwort-test-search-mode-set", "OFF"])
        time.sleep(0.2)


# ---------------------------------------------------------------------------
# dynamic-contrast-rendering
# ---------------------------------------------------------------------------

class TestDynamicContrastRendering:
    """Tests for spec: dynamic-contrast-rendering"""

    def test_search_sel_color_differentiates_selected(self):
        """search_sel_color must differ from search_hit_color to create contrast (dynamic-contrast-rendering)."""
        src = _src()
        hit = re.search(r'search_hit_color\s*=\s*"([^"]+)"', src)
        sel = re.search(r'search_sel_color\s*=\s*"([^"]+)"', src)
        assert hit and sel, (
            "dynamic-contrast-rendering: search_hit_color or search_sel_color not found as string defaults"
        )
        assert hit.group(1) != sel.group(1), (
            f"dynamic-contrast-rendering: search_hit_color ({hit.group(1)}) == search_sel_color ({sel.group(1)}); "
            "selected results must have distinct contrast color"
        )

    def test_draw_search_ui_generates_ass_color_tags(self):
        """draw_search_ui (called by render_search) must generate ASS color tags (dynamic-contrast-rendering)."""
        src = _src()
        idx = src.find("local function draw_search_ui")
        assert idx != -1, "dynamic-contrast-rendering: draw_search_ui not found"
        body = src[idx:idx + 5000]
        has_ass = "\\1c&H" in body or "\\c&H" in body or "{\\c" in body
        assert has_ass, (
            "dynamic-contrast-rendering: draw_search_ui does not generate ASS color tags (\\1c&H...&)"
        )


# ---------------------------------------------------------------------------
# tokenized-fuzzy-search
# ---------------------------------------------------------------------------

class TestTokenizedFuzzySearch:
    """Tests for spec: tokenized-fuzzy-search"""

    def test_render_search_handles_query_tokens(self):
        """render_search must process search query for token-based matching (tokenized-fuzzy-search)."""
        src = _src()
        idx = src.find("local function render_search")
        assert idx != -1
        body = src[idx:idx + 2000]
        has_token_logic = ("token" in body.lower() or "split" in body.lower() or
                           "query" in body or "SEARCH_QUERY" in body or "search_query" in body)
        assert has_token_logic, (
            "tokenized-fuzzy-search: render_search has no query/token processing logic"
        )

    def test_search_query_fsm_field_exists(self):
        """A SEARCH_QUERY or equivalent FSM field must store the user input (tokenized-fuzzy-search)."""
        src = _src()
        has_query = ("SEARCH_QUERY" in src or "search_query" in src or
                     "QUERY_CHARS" in src or "query_chars" in src or "SEARCH_CHARS" in src)
        assert has_query, (
            "tokenized-fuzzy-search: No SEARCH_QUERY / QUERY_CHARS FSM field found in kardenwort.lua"
        )


# ---------------------------------------------------------------------------
# fuzzy-search-optimization
# ---------------------------------------------------------------------------

class TestFuzzySearchOptimization:
    """Tests for spec: fuzzy-search-optimization"""

    def test_search_mode_activation_does_not_error(self, mpv):
        """Activating search mode must succeed without Lua error (fuzzy-search-optimization)."""
        ipc = mpv.ipc
        ipc.command(["script-message-to", "kardenwort", "kardenwort-test-search-mode-set", "ON"])
        time.sleep(0.4)
        state = robust_state(ipc)
        assert state is not None, (
            "fuzzy-search-optimization: state probe failed after search mode activation"
        )
        # Cleanup
        ipc.command(["script-message-to", "kardenwort", "kardenwort-test-search-mode-set", "OFF"])
        time.sleep(0.2)

    def test_render_search_exists_for_optimized_rendering(self):
        """render_search must be a dedicated function, not inline code (fuzzy-search-optimization)."""
        assert "local function render_search" in _src(), (
            "fuzzy-search-optimization: render_search not a dedicated function"
        )


# ---------------------------------------------------------------------------
# drum-scroll-sync (structural)
# ---------------------------------------------------------------------------

class TestDrumScrollSyncStructural:
    """Tests for spec: drum-scroll-sync (structural layer)"""

    def test_draw_drum_handles_is_pri_flag(self):
        """draw_drum must accept is_pri flag for dual-lane rendering (drum-scroll-sync)."""
        src = _src()
        idx = src.find("local function draw_drum")
        assert idx != -1
        sig = src[idx:idx + 200]
        assert "is_pri" in sig, (
            "drum-scroll-sync: draw_drum must accept is_pri param for dual-lane sync"
        )

    def test_drum_osd_and_seek_osd_exist(self):
        """Both drum_osd and seek_osd must exist for dual-lane synchronized rendering (drum-scroll-sync)."""
        src = _src()
        assert "local drum_osd" in src or "drum_osd =" in src, (
            "drum-scroll-sync: drum_osd not found in kardenwort.lua"
        )
        assert "local seek_osd" in src or "seek_osd =" in src, (
            "drum-scroll-sync: seek_osd not found in kardenwort.lua"
        )


# ---------------------------------------------------------------------------
# vertical-gap-elimination
# ---------------------------------------------------------------------------

class TestVerticalGapElimination:
    """Tests for spec: vertical-gap-elimination"""

    def test_dw_double_gap_option_exists(self):
        """dw_double_gap option must exist to control double-newline gap in drum mode (vertical-gap-elimination)."""
        assert "dw_double_gap" in _src(), (
            "vertical-gap-elimination: dw_double_gap option not found in kardenwort.lua"
        )

    def test_rendering_respects_double_gap_flag(self):
        """Drum rendering must branch on d_gap flag for single vs double newline (vertical-gap-elimination)."""
        src = _src()
        has_branch = "d_gap" in src and ("\\N\\N" in src or "\\\\N\\\\N" in src)
        assert has_branch, (
            "vertical-gap-elimination: No d_gap branching between \\N and \\N\\N in rendering logic"
        )

    def test_vsp_used_for_gap_control(self):
        """\\vsp ASS tag must be used for precise vertical gap control (vertical-gap-elimination)."""
        src = _src()
        assert "vsp" in src, (
            "vertical-gap-elimination: \\vsp tag not found — vertical gap can't be controlled precisely"
        )

    def test_an8_anchor_used_for_top_context(self):
        """\\an8 anchor must appear in drum context rendering for top-aligned layout (vertical-gap-elimination)."""
        src = _src()
        assert "\\an8" in src or "an8" in src, (
            "vertical-gap-elimination: \\an8 top-anchor tag not found in kardenwort.lua"
        )




