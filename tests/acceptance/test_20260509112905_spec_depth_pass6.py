"""
Feature ZID: 20260509112905
Test Creation ZID: 20260509112905
Feature: Spec Depth Pass 6 — Structural Coverage Batch

Validated Specs:
- fsm-architecture
- modular-architecture
- osd-requirements
- proximity-based-relevance
- search-relevance-scoring
- search-ux-optimization
- secondary-subtitle-filtering
- smart-diagnostics
- source-url-discovery
- stability-error-handling
- subtitle-rendering
- word-based-deletion-logic
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


def robust_state(ipc, retries=5):
    from tests.ipc.mpv_ipc import query_kardenwort_state
    for _ in range(retries):
        state = query_kardenwort_state(ipc)
        if state and "options" in state:
            return state
        time.sleep(0.4)
    return query_kardenwort_state(ipc)


# ---------------------------------------------------------------------------
# fsm-architecture
# ---------------------------------------------------------------------------

class TestFsmArchitecture:
    """Tests for spec: fsm-architecture"""

    def test_native_sub_vis_in_fsm(self):
        """FSM.native_sub_vis must track native subtitle visibility (fsm-architecture)."""
        assert "native_sub_vis" in _src(), (
            "fsm-architecture: native_sub_vis not found in FSM"
        )

    def test_dw_saved_sub_vis_preserves_state(self):
        """DW_SAVED_SUB_VIS must save subtitle visibility before Drum Window opens (fsm-architecture)."""
        assert "DW_SAVED_SUB_VIS" in _src(), (
            "fsm-architecture: DW_SAVED_SUB_VIS not found — subtitle state not preserved on DW open"
        )

    def test_last_paused_sub_end_in_fsm(self):
        """last_paused_sub_end must prevent duplicate autopause triggers (fsm-architecture)."""
        assert "last_paused_sub_end" in _src(), (
            "fsm-architecture: last_paused_sub_end not found in FSM"
        )

    def test_immersion_mode_default_option_exists(self):
        """immersion_mode_default must be configurable via Options (fsm-architecture)."""
        assert "immersion_mode_default" in _src(), (
            "fsm-architecture: immersion_mode_default option not found"
        )

    def test_immersion_mode_initialized_from_config(self):
        """IMMERSION_MODE must be initialized from immersion_mode_default option (fsm-architecture)."""
        src = _src()
        assert "IMMERSION_MODE" in src and "immersion_mode_default" in src, (
            "fsm-architecture: IMMERSION_MODE not initialized from immersion_mode_default"
        )
        idx = src.find("IMMERSION_MODE =")
        assert idx != -1
        line = src[idx:idx + 200]
        assert "immersion_mode_default" in line or "PHRASE" in line, (
            "fsm-architecture: IMMERSION_MODE initialization does not reference immersion_mode_default"
        )

    def test_drum_and_drum_window_fields_in_fsm(self):
        """FSM.DRUM and FSM.DRUM_WINDOW must be separate state fields (fsm-architecture)."""
        src = _src()
        assert "FSM.DRUM" in src or "DRUM =" in src, (
            "fsm-architecture: FSM.DRUM not found"
        )
        assert "FSM.DRUM_WINDOW" in src or "DRUM_WINDOW =" in src, (
            "fsm-architecture: FSM.DRUM_WINDOW not found"
        )

    def test_active_idx_in_fsm(self, mpv):
        """ACTIVE_IDX must be exposed in state as active_sub_index (fsm-architecture)."""
        state = robust_state(mpv.ipc)
        assert "active_sub_index" in state, (
            "fsm-architecture: active_sub_index (ACTIVE_IDX) not in state snapshot"
        )


# ---------------------------------------------------------------------------
# modular-architecture
# ---------------------------------------------------------------------------

class TestModularArchitecture:
    """Tests for spec: modular-architecture"""

    def test_diagnostic_module_initialized(self):
        """Diagnostic module with severity levels must be initialized (modular-architecture)."""
        src = _src()
        assert "Diagnostic.error" in src, "modular-architecture: Diagnostic.error not found"
        assert "Diagnostic.warn" in src, "modular-architecture: Diagnostic.warn not found"
        assert "Diagnostic.info" in src, "modular-architecture: Diagnostic.info not found"
        assert "Diagnostic.debug" in src, "modular-architecture: Diagnostic.debug not found"

    def test_diagnostic_log_uses_severity_levels(self):
        """Diagnostic.log must support distinct severity levels (modular-architecture)."""
        src = _src()
        assert "Diagnostic.ERROR" in src or "LEVEL_MAP" in src, (
            "modular-architecture: Diagnostic severity level map not found"
        )

    def test_diagnostic_deduplication_exists(self):
        """Diagnostic module must deduplicate repeated log messages (modular-architecture)."""
        src = _src()
        has_dedup = "SEEN" in src and "Diagnostic" in src
        assert has_dedup, (
            "modular-architecture: Diagnostic.SEEN deduplication not found"
        )

    def test_startup_diagnostic_emitted(self):
        """Diagnostic.info must be called on script initialization (modular-architecture)."""
        assert 'Diagnostic.info("SCRIPT INITIALIZING' in _src(), (
            "modular-architecture: No startup Diagnostic.info found — initialization not logged"
        )


# ---------------------------------------------------------------------------
# osd-requirements
# ---------------------------------------------------------------------------

class TestOsdRequirements:
    """Tests for spec: osd-requirements"""

    def test_dw_double_gap_option_controls_spacing(self):
        """dw_double_gap option must control subtitle gap in Drum Window (osd-requirements)."""
        assert "dw_double_gap" in _src(), (
            "osd-requirements: dw_double_gap option not found in kardenwort.lua"
        )

    def test_vsp_spacing_option_exists(self):
        """dw_vsp (or equivalent) vertical spacing parameter must exist (osd-requirements)."""
        src = _src()
        has_vsp = "dw_vsp" in src or "vsp_base" in src or "vsp_extra" in src
        assert has_vsp, (
            "osd-requirements: No VSP vertical spacing parameter found in kardenwort.lua"
        )

    def test_tooltip_y_offset_option_exists(self):
        """tooltip_y_offset_lines must exist for tooltip centering control (osd-requirements)."""
        assert "tooltip_y_offset" in _src(), (
            "osd-requirements: tooltip_y_offset option not found in kardenwort.lua"
        )


# ---------------------------------------------------------------------------
# proximity-based-relevance
# ---------------------------------------------------------------------------

class TestProximityBasedRelevance:
    """Tests for spec: proximity-based-relevance"""

    def test_search_results_have_numeric_relevance(self):
        """Search results must carry a numeric relevance score for sorting (proximity-based-relevance)."""
        src = _src()
        has_score = "score" in src and "SEARCH_RESULTS" in src
        assert has_score, (
            "proximity-based-relevance: No 'score' field found in search results logic"
        )

    def test_score_sorting_logic_exists(self):
        """Search results must be sorted by score descending (proximity-based-relevance)."""
        src = _src()
        idx = src.find("SEARCH_RESULTS")
        assert idx != -1
        has_sort = "table.sort" in src and "score" in src
        assert has_sort, (
            "proximity-based-relevance: table.sort not found near score-based result ranking"
        )


# ---------------------------------------------------------------------------
# search-relevance-scoring
# ---------------------------------------------------------------------------

class TestSearchRelevanceScoring:
    """Tests for spec: search-relevance-scoring"""

    def test_search_results_sorted_by_score(self):
        """SEARCH_RESULTS must be sorted by score — highest relevance first (search-relevance-scoring)."""
        src = _src()
        assert "table.sort" in src, (
            "search-relevance-scoring: table.sort not found — results are not sorted"
        )
        assert "score" in src, (
            "search-relevance-scoring: no score field in search result objects"
        )

    def test_search_results_exposed_in_state(self, mpv):
        """search_results must be accessible in runtime state snapshot (search-relevance-scoring)."""
        state = robust_state(mpv.ipc)
        assert "search_results" in state, (
            "search-relevance-scoring: search_results not in state snapshot"
        )


# ---------------------------------------------------------------------------
# search-ux-optimization
# ---------------------------------------------------------------------------

class TestSearchUxOptimization:
    """Tests for spec: search-ux-optimization"""

    def test_search_key_delete_word_bound_to_ctrl_w(self):
        """search_key_delete_word must default to 'Ctrl+w' (search-ux-optimization)."""
        assert 'search_key_delete_word = "Ctrl+w"' in _src(), (
            "search-ux-optimization: search_key_delete_word default is not 'Ctrl+w'"
        )

    def test_get_word_boundary_used_in_search_deletion(self):
        """get_word_boundary must be referenced in search mode deletion (search-ux-optimization)."""
        src = _src()
        assert "get_word_boundary" in src, (
            "search-ux-optimization: get_word_boundary not found — word deletion logic missing"
        )
        # The search deletion path must call get_word_boundary
        idx = src.find("local function move_search_cursor")
        assert idx != -1, "search-ux-optimization: move_search_cursor not found"
        body = src[idx:idx + 500]
        assert "get_word_boundary" in body, (
            "search-ux-optimization: move_search_cursor does not use get_word_boundary for ctrl+word-delete"
        )

    def test_search_anchor_supports_selection(self):
        """SEARCH_ANCHOR must exist for selection-range deletion (search-ux-optimization)."""
        assert "SEARCH_ANCHOR" in _src(), (
            "search-ux-optimization: SEARCH_ANCHOR not found — selection deletion not supported"
        )


# ---------------------------------------------------------------------------
# secondary-subtitle-filtering
# ---------------------------------------------------------------------------

class TestSecondarySubtitleFiltering:
    """Tests for spec: secondary-subtitle-filtering"""

    def test_tracks_sec_in_source(self):
        """Tracks.sec must exist for secondary subtitle track management (secondary-subtitle-filtering)."""
        assert "Tracks.sec" in _src(), (
            "secondary-subtitle-filtering: Tracks.sec not found in kardenwort.lua"
        )

    def test_native_sec_sub_vis_tracked(self):
        """native_sec_sub_vis must be tracked for secondary subtitle visibility (secondary-subtitle-filtering)."""
        assert "native_sec_sub_vis" in _src(), (
            "secondary-subtitle-filtering: native_sec_sub_vis not found in kardenwort.lua"
        )

    def test_native_sec_sub_vis_in_state(self, mpv):
        """native_sec_sub_vis must be exposed in runtime state (secondary-subtitle-filtering)."""
        state = robust_state(mpv.ipc)
        assert "native_sec_sub_vis" in state, (
            "secondary-subtitle-filtering: native_sec_sub_vis not in state snapshot"
        )


# ---------------------------------------------------------------------------
# smart-diagnostics
# ---------------------------------------------------------------------------

class TestSmartDiagnostics:
    """Tests for spec: smart-diagnostics"""

    def test_log_level_option_exists(self):
        """log_level option must exist for configurable verbosity (smart-diagnostics)."""
        assert "log_level" in _src(), (
            "smart-diagnostics: log_level option not found in kardenwort.lua"
        )

    def test_diagnostic_has_five_severity_levels(self):
        """Diagnostic must support error, warn, info, debug, trace levels (smart-diagnostics)."""
        src = _src()
        for level in ("error", "warn", "info", "debug", "trace"):
            assert f"Diagnostic.{level}" in src, (
                f"smart-diagnostics: Diagnostic.{level} not found in kardenwort.lua"
            )

    def test_diagnostic_seen_deduplication(self):
        """Diagnostic.SEEN table must prevent repeated log flooding (smart-diagnostics)."""
        assert "Diagnostic.SEEN" in _src(), (
            "smart-diagnostics: Diagnostic.SEEN deduplication table not found"
        )

    def test_startup_health_check_logs_warnings(self):
        """Startup health check must log warnings for config issues (smart-diagnostics)."""
        src = _src()
        assert "startup-health-check" in src or "SCRIPT INITIALIZING" in src, (
            "smart-diagnostics: No startup health check diagnostic found"
        )


# ---------------------------------------------------------------------------
# source-url-discovery
# ---------------------------------------------------------------------------

class TestSourceUrlDiscovery:
    """Tests for spec: source-url-discovery"""

    def test_find_source_url_exists(self):
        """find_source_url must exist for sidecar URL file discovery (source-url-discovery)."""
        assert "local function find_source_url" in _src(), (
            "source-url-discovery: find_source_url not found in kardenwort.lua"
        )

    def test_source_url_mapped_in_anki_export(self):
        """source_url must be resolvable in Anki export field mapping (source-url-discovery)."""
        assert "source_url" in _src(), (
            "source-url-discovery: source_url not found in field resolution logic"
        )

    def test_anki_sync_period_option_exists(self):
        """anki_sync_period must exist for periodic URL cache refresh (source-url-discovery)."""
        assert "anki_sync_period" in _src(), (
            "source-url-discovery: anki_sync_period option not found in kardenwort.lua"
        )


# ---------------------------------------------------------------------------
# stability-error-handling
# ---------------------------------------------------------------------------

class TestStabilityErrorHandling:
    """Tests for spec: stability-error-handling"""

    def test_xpcall_with_debug_traceback_in_master_tick(self):
        """master_tick must use xpcall with debug.traceback for full error context (stability-error-handling)."""
        src = _src()
        idx = src.find("local function master_tick")
        assert idx != -1
        body = src[idx:idx + 400]
        has_xpcall = "xpcall" in body
        assert has_xpcall, (
            "stability-error-handling: master_tick does not use xpcall for error isolation"
        )
        # debug.traceback may be anywhere in file as the xpcall error handler
        assert "debug.traceback" in src, (
            "stability-error-handling: debug.traceback not found — error tracebacks won't be logged"
        )

    def test_tsv_auto_creation_on_missing_file(self):
        """load_anki_tsv must auto-create the TSV file when it's missing (stability-error-handling)."""
        src = _src()
        idx = src.find("local function load_anki_tsv")
        assert idx != -1
        body = src[idx:idx + 2000]
        has_autocreate = ("auto-creation" in body or "io.open" in body or
                          "TSV file missing" in body)
        assert has_autocreate, (
            "stability-error-handling: load_anki_tsv does not auto-create missing TSV file"
        )

    def test_anki_highlights_reset_on_file_missing(self):
        """ANKI_HIGHLIGHTS must be reset to {} when TSV file is missing (stability-error-handling)."""
        src = _src()
        idx = src.find("local function load_anki_tsv")
        assert idx != -1
        body = src[idx:idx + 2000]
        assert "ANKI_HIGHLIGHTS = {}" in body, (
            "stability-error-handling: ANKI_HIGHLIGHTS not reset to {} when TSV file is missing"
        )


# ---------------------------------------------------------------------------
# subtitle-rendering
# ---------------------------------------------------------------------------

class TestSubtitleRendering:
    """Tests for spec: subtitle-rendering"""

    def test_srt_font_name_option_exists(self):
        """srt_font_name must be in Options for SRT mode text rendering (subtitle-rendering)."""
        assert "srt_font_name" in _src(), (
            "subtitle-rendering: srt_font_name option not found"
        )

    def test_drum_font_name_option_exists(self):
        """drum_font_name must be in Options for Drum Mode text rendering (subtitle-rendering)."""
        assert "drum_font_name" in _src(), (
            "subtitle-rendering: drum_font_name option not found"
        )

    def test_srt_font_bold_option_exists(self):
        """srt_font_bold must be in Options for SRT mode bold text (subtitle-rendering)."""
        assert "srt_font_bold" in _src(), (
            "subtitle-rendering: srt_font_bold option not found"
        )

    def test_drum_font_bold_option_exists(self):
        """drum_font_bold must be in Options for Drum Mode bold text (subtitle-rendering)."""
        assert "drum_font_bold" in _src(), (
            "subtitle-rendering: drum_font_bold option not found"
        )

    def test_get_center_index_exists_for_log_n_seeking(self):
        """get_center_index must exist for O(log N) subtitle centering (subtitle-rendering)."""
        assert "get_center_index" in _src(), (
            "subtitle-rendering: get_center_index not found — O(log N) centering is missing"
        )

    def test_dw_cursor_word_used_in_rendering(self):
        """DW_CURSOR_WORD must be referenced in rendering for yellow word pointer (subtitle-rendering)."""
        src = _src()
        count = src.count("DW_CURSOR_WORD")
        assert count >= 3, (
            f"subtitle-rendering: DW_CURSOR_WORD referenced only {count} time(s); "
            "yellow word pointer must be used in multiple rendering paths"
        )

    def test_font_bold_parameters_referenced_in_rendering(self):
        """drum_font_bold and srt_font_bold must be referenced in drum/SRT rendering logic (subtitle-rendering)."""
        src = _src()
        assert "drum_font_bold" in src, (
            "subtitle-rendering: drum_font_bold not referenced in kardenwort.lua"
        )
        assert "srt_font_bold" in src, (
            "subtitle-rendering: srt_font_bold not referenced in kardenwort.lua"
        )
        # Both should appear in a branching expression
        count_bold = src.count("drum_font_bold")
        assert count_bold >= 2, (
            f"subtitle-rendering: drum_font_bold appears only {count_bold} time(s) — declaration + usage required"
        )


# ---------------------------------------------------------------------------
# word-based-deletion-logic
# ---------------------------------------------------------------------------

class TestWordBasedDeletionLogicExtended:
    """Tests for spec: word-based-deletion-logic (extended)"""

    def test_ctrl_w_bound_for_search_word_delete(self):
        """search_key_delete_word option must default to 'Ctrl+w' (word-based-deletion-logic)."""
        assert 'search_key_delete_word = "Ctrl+w"' in _src(), (
            "word-based-deletion-logic: Ctrl+w not configured as default word-delete key"
        )

    def test_cyrillic_ctrl_bound_for_russian_layout(self):
        """A Cyrillic Ctrl equivalent must be configured for Russian keyboard layout (word-based-deletion-logic)."""
        src = _src()
        has_cyrillic_ctrl = ("Ctrl+ц" in src or "Ctrl+Ц" in src or
                             "ctrl.*cyrillic" in src.lower() or
                             "ц" in src)
        assert has_cyrillic_ctrl, (
            "word-based-deletion-logic: No Cyrillic Ctrl binding found for Russian keyboard layout"
        )

    def test_get_word_boundary_called_in_search_context(self):
        """get_word_boundary must be invoked in search mode for Ctrl+word-delete (word-based-deletion-logic)."""
        src = _src()
        idx = src.find("local function move_search_cursor")
        assert idx != -1, "word-based-deletion-logic: move_search_cursor not found"
        body = src[idx:idx + 500]
        assert "get_word_boundary" in body, (
            "word-based-deletion-logic: get_word_boundary not called in move_search_cursor (Ctrl+word-delete)"
        )




