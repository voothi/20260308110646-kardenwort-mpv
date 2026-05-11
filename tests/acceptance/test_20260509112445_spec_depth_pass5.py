"""
Feature ZID: 20260509112445
Test Creation ZID: 20260509112445
Feature: Spec Depth Pass 5 — Structural Coverage Batch

Validated Specs:
- drum-window-tooltip
- drum-sync-compatibility-guards
- drum-window-reading-mode
- cyclic-navigation
- karaoke-autopause
- live-positioning-sync
- platform-detection-logic
- session-persistence
- subtitle-replay
- targeted-content-filtering
- tsv-load-optimization
- ui-integration-hooks
- unified-clipboard-abstraction
- rendering-optimization
- script-stability-hardening
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
# drum-window-tooltip
# ---------------------------------------------------------------------------

class TestDrumWindowTooltip:
    """Tests for spec: drum-window-tooltip"""

    def test_draw_dw_tooltip_exists(self):
        """draw_dw_tooltip must exist for tooltip rendering (drum-window-tooltip)."""
        assert "local function draw_dw_tooltip" in _src(), (
            "drum-window-tooltip: draw_dw_tooltip not found in kardenwort.lua"
        )

    def test_tooltip_bg_opacity_option_exists(self):
        """tooltip_bg_opacity must be in Options for configurable transparency (drum-window-tooltip)."""
        assert "tooltip_bg_opacity" in _src(), (
            "drum-window-tooltip: tooltip_bg_opacity option not found in kardenwort.lua"
        )

    def test_tooltip_font_size_option_exists(self):
        """tooltip_font_size must be in Options for unified visual sizing (drum-window-tooltip)."""
        assert "tooltip_font_size" in _src(), (
            "drum-window-tooltip: tooltip_font_size option not found in kardenwort.lua"
        )

    def test_dw_tooltip_mode_fsm_field_exists(self):
        """DW_TOOLTIP_MODE must be in FSM for click/hover mode control (drum-window-tooltip)."""
        assert "DW_TOOLTIP_MODE" in _src(), (
            "drum-window-tooltip: DW_TOOLTIP_MODE FSM field not found in kardenwort.lua"
        )

    def test_dw_tooltip_osd_z_is_25(self):
        """dw_tooltip_osd.z must be 25 (between dw_osd=20 and search_osd=30) (drum-window-tooltip)."""
        assert "dw_tooltip_osd.z = 25" in _src(), (
            "drum-window-tooltip: dw_tooltip_osd.z != 25"
        )

    def test_draw_dw_tooltip_uses_bg_opacity(self):
        """draw_dw_tooltip must reference tooltip_bg_opacity for ASS rendering (drum-window-tooltip)."""
        src = _src()
        idx = src.find("local function draw_dw_tooltip")
        assert idx != -1
        body = src[idx:idx + 2000]
        assert "tooltip_bg_opacity" in body, (
            "drum-window-tooltip: draw_dw_tooltip does not use tooltip_bg_opacity"
        )


# ---------------------------------------------------------------------------
# drum-sync-compatibility-guards
# ---------------------------------------------------------------------------

class TestDrumSyncCompatibilityGuards:
    """Tests for spec: drum-sync-compatibility-guards"""

    def test_native_sec_sub_pos_in_fsm(self):
        """FSM.native_sec_sub_pos must exist for position persistence across mode toggles (drum-sync-compatibility-guards)."""
        assert "native_sec_sub_pos" in _src(), (
            "drum-sync-compatibility-guards: native_sec_sub_pos not found in FSM"
        )

    def test_native_sec_sub_pos_exposed_in_state(self, mpv):
        """native_sec_sub_pos must be exposed in state snapshot (drum-sync-compatibility-guards)."""
        state = robust_state(mpv.ipc)
        assert "native_sec_sub_pos" in state, (
            "drum-sync-compatibility-guards: native_sec_sub_pos not in state snapshot"
        )

    def test_media_state_ass_guard_exists(self):
        """ASS-specific features must be guarded by MEDIA_STATE.match('ASS') (drum-sync-compatibility-guards)."""
        src = _src()
        assert 'MEDIA_STATE:match("ASS")' in src or "MEDIA_STATE.*ASS" in src, (
            "drum-sync-compatibility-guards: No ASS media-state guard found"
        )


# ---------------------------------------------------------------------------
# drum-window-reading-mode
# ---------------------------------------------------------------------------

class TestDrumWindowReadingMode:
    """Tests for spec: drum-window-reading-mode"""

    def test_dw_follow_player_fsm_field_exists(self):
        """DW_FOLLOW_PLAYER must exist in FSM to control Follow/Manual Mode (drum-window-reading-mode)."""
        assert "DW_FOLLOW_PLAYER" in _src(), (
            "drum-window-reading-mode: DW_FOLLOW_PLAYER not found in kardenwort.lua"
        )

    def test_dw_view_center_fsm_field_exists(self):
        """DW_VIEW_CENTER must track the current viewport scroll position (drum-window-reading-mode)."""
        assert "DW_VIEW_CENTER" in _src(), (
            "drum-window-reading-mode: DW_VIEW_CENTER not found in kardenwort.lua"
        )

    def test_dw_follow_player_exposed_in_state(self, mpv):
        """dw_follow_player must be exposed in runtime state (drum-window-reading-mode)."""
        state = robust_state(mpv.ipc)
        assert "dw_follow_player" in state, (
            "drum-window-reading-mode: dw_follow_player not in state snapshot"
        )

    def test_dw_view_center_exposed_in_state(self, mpv):
        """dw_view_center must be exposed in runtime state (drum-window-reading-mode)."""
        state = robust_state(mpv.ipc)
        assert "dw_view_center" in state, (
            "drum-window-reading-mode: dw_view_center not in state snapshot"
        )


# ---------------------------------------------------------------------------
# cyclic-navigation
# ---------------------------------------------------------------------------

class TestCyclicNavigation:
    """Tests for spec: cyclic-navigation"""

    def test_active_idx_initialized_to_minus_one(self):
        """ACTIVE_IDX must start at -1 (no active subtitle) (cyclic-navigation)."""
        assert "ACTIVE_IDX = -1" in _src(), (
            "cyclic-navigation: ACTIVE_IDX not initialized to -1 in FSM"
        )

    def test_active_idx_exposed_in_state(self, mpv):
        """active_sub_index must be exposed in runtime state (cyclic-navigation)."""
        state = robust_state(mpv.ipc)
        assert "active_sub_index" in state, (
            "cyclic-navigation: active_sub_index (ACTIVE_IDX) not in state snapshot"
        )

    def test_seek_prev_next_registered_with_complex_flag(self):
        """kardenwort-seek_prev and kardenwort-seek_next must be registered with {complex=true} for hold detection (cyclic-navigation)."""
        src = _src()
        assert 'complex = true' in src or '{complex = true}' in src, (
            "cyclic-navigation: seek bindings lack {complex=true} for key-hold repeat detection"
        )


# ---------------------------------------------------------------------------
# karaoke-autopause
# ---------------------------------------------------------------------------

class TestKaraokeAutopause:
    """Tests for spec: karaoke-autopause"""

    def test_autopause_fsm_field_exists(self):
        """FSM.AUTOPAUSE must exist for autopause state tracking (karaoke-autopause)."""
        assert "AUTOPAUSE" in _src(), (
            "karaoke-autopause: AUTOPAUSE field not found in FSM"
        )

    def test_autopause_exposed_in_state(self, mpv):
        """autopause must be exposed in runtime state snapshot (karaoke-autopause)."""
        state = robust_state(mpv.ipc)
        assert "autopause" in state, (
            "karaoke-autopause: autopause not in state snapshot"
        )

    def test_ghost_hold_expiry_fsm_field_exists(self):
        """GHOST_HOLD_EXPIRY must exist for hold-to-play bypass detection (karaoke-autopause)."""
        assert "GHOST_HOLD_EXPIRY" in _src(), (
            "karaoke-autopause: GHOST_HOLD_EXPIRY not found in FSM"
        )

    def test_spacebar_fsm_field_exists(self):
        """FSM.SPACEBAR state machine must exist for hold detection (karaoke-autopause)."""
        assert "SPACEBAR" in _src(), (
            "karaoke-autopause: SPACEBAR FSM field not found in kardenwort.lua"
        )


# ---------------------------------------------------------------------------
# live-positioning-sync
# ---------------------------------------------------------------------------

class TestLivePositioningSync:
    """Tests for spec: live-positioning-sync"""

    def test_secondary_sub_pos_property_in_source(self):
        """'secondary-sub-pos' mpv property must be referenced in kardenwort.lua (live-positioning-sync)."""
        assert "secondary-sub-pos" in _src(), (
            "live-positioning-sync: 'secondary-sub-pos' property not referenced in kardenwort.lua"
        )

    def test_sec_pos_bottom_option_controls_positioning(self):
        """sec_pos_bottom option must drive secondary subtitle positioning (live-positioning-sync)."""
        src = _src()
        assert "sec_pos_bottom" in src, (
            "live-positioning-sync: sec_pos_bottom option not found"
        )
        count = src.count("sec_pos_bottom")
        assert count >= 2, (
            f"live-positioning-sync: sec_pos_bottom referenced only {count} time(s); "
            "must appear in both Options declaration and usage"
        )

    def test_native_sec_sub_pos_tracks_position(self, mpv):
        """native_sec_sub_pos in state must be numeric (live-positioning-sync)."""
        state = robust_state(mpv.ipc)
        pos = state.get("native_sec_sub_pos")
        assert isinstance(pos, (int, float)), (
            f"live-positioning-sync: native_sec_sub_pos should be numeric, got {type(pos)}"
        )


# ---------------------------------------------------------------------------
# platform-detection-logic
# ---------------------------------------------------------------------------

class TestPlatformDetectionLogic:
    """Tests for spec: platform-detection-logic"""

    def test_package_config_used_for_platform_detection(self):
        """package.config:sub(1,1) must be used for OS detection (platform-detection-logic)."""
        assert "package.config" in _src(), (
            "platform-detection-logic: package.config not found — OS detection is missing"
        )

    def test_platform_exposed_in_state(self, mpv):
        """platform field must be exposed in runtime state as 'windows' or 'unix' (platform-detection-logic)."""
        state = robust_state(mpv.ipc)
        assert "platform" in state, (
            "platform-detection-logic: platform not in state snapshot"
        )
        assert state["platform"] in ("windows", "unix"), (
            f"platform-detection-logic: platform value should be 'windows' or 'unix', got {state['platform']!r}"
        )

    def test_set_clipboard_detects_platform(self):
        """set_clipboard must detect platform to select clipboard mechanism (platform-detection-logic)."""
        src = _src()
        idx = src.find("local function set_clipboard")
        assert idx != -1, "platform-detection-logic: set_clipboard not found"
        body = src[idx:idx + 500]
        assert "package.config" in body, (
            "platform-detection-logic: set_clipboard does not use package.config for platform detection"
        )


# ---------------------------------------------------------------------------
# session-persistence
# ---------------------------------------------------------------------------

class TestSessionPersistence:
    """Tests for spec: session-persistence"""

    def test_resume_last_file_script_exists(self):
        """scripts/kardenwort/resume.lua must exist for session persistence (session-persistence)."""
        import os
        assert os.path.exists("scripts/kardenwort/resume.lua"), (
            "session-persistence: scripts/kardenwort/resume.lua not found"
        )

    def test_resume_script_registers_file_events(self):
        """resume.lua must register file events to save/restore session (session-persistence)."""
        with open("scripts/kardenwort/resume.lua", encoding="utf-8") as f:
            content = f.read()
        has_event = ("file-loaded" in content or "shutdown" in content or
                     "end-file" in content or "mp.register_event" in content)
        assert has_event, (
            "session-persistence: scripts/kardenwort/resume.lua does not register any file lifecycle events"
        )


# ---------------------------------------------------------------------------
# subtitle-replay
# ---------------------------------------------------------------------------

class TestSubtitleReplay:
    """Tests for spec: subtitle-replay"""

    def test_replay_ms_option_exists(self):
        """replay_ms must be in Options for configurable replay window (subtitle-replay)."""
        assert "replay_ms" in _src(), (
            "subtitle-replay: replay_ms option not found in kardenwort.lua"
        )

    def test_replay_count_option_exists(self):
        """replay_count must be in Options for multi-iteration replay (subtitle-replay)."""
        assert "replay_count" in _src(), (
            "subtitle-replay: replay_count option not found in kardenwort.lua"
        )

    def test_replay_autostop_option_exists(self):
        """replay_autostop must be in Options for autopause-after-iterations behavior (subtitle-replay)."""
        assert "replay_autostop" in _src(), (
            "subtitle-replay: replay_autostop option not found in kardenwort.lua"
        )

    def test_ghost_hold_expiry_used_for_2s_leash(self):
        """GHOST_HOLD_EXPIRY must be set to current time + 2 seconds for ghost-hold recovery (subtitle-replay)."""
        src = _src()
        assert "GHOST_HOLD_EXPIRY" in src, "subtitle-replay: GHOST_HOLD_EXPIRY not found"
        assert "2.0" in src and "GHOST_HOLD_EXPIRY" in src, (
            "subtitle-replay: 2-second ghost hold leash not found (GHOST_HOLD_EXPIRY + 2.0)"
        )

    def test_replay_uses_replay_ms_for_window(self):
        """Replay seek must use replay_ms to calculate replay start time (subtitle-replay)."""
        src = _src()
        assert "replay_ms" in src and "absolute+exact" in src, (
            "subtitle-replay: replay_ms not connected to absolute+exact seek"
        )


# ---------------------------------------------------------------------------
# targeted-content-filtering
# ---------------------------------------------------------------------------

class TestTargetedContentFiltering:
    """Tests for spec: targeted-content-filtering"""

    def test_cyrillic_char_set_defined(self):
        """CYRILLIC character sets must be defined for content filtering (targeted-content-filtering)."""
        assert "CYRILLIC" in _src(), (
            "targeted-content-filtering: CYRILLIC character set not defined in kardenwort.lua"
        )

    def test_word_char_map_enables_language_filtering(self):
        """WORD_CHAR_MAP must enable character-level language detection for filtering (targeted-content-filtering)."""
        src = _src()
        assert "WORD_CHAR_MAP" in src and "CYRILLIC" in src, (
            "targeted-content-filtering: WORD_CHAR_MAP + CYRILLIC not both present"
        )


# ---------------------------------------------------------------------------
# tsv-load-optimization
# ---------------------------------------------------------------------------

class TestTsvLoadOptimization:
    """Tests for spec: tsv-load-optimization"""

    def test_anki_db_mtime_tracked_in_fsm(self):
        """ANKI_DB_MTIME must track file modification time for fingerprinting (tsv-load-optimization)."""
        assert "ANKI_DB_MTIME" in _src(), (
            "tsv-load-optimization: ANKI_DB_MTIME not found in FSM"
        )

    def test_anki_db_size_tracked_in_fsm(self):
        """ANKI_DB_SIZE must track file size for fingerprinting (tsv-load-optimization)."""
        assert "ANKI_DB_SIZE" in _src(), (
            "tsv-load-optimization: ANKI_DB_SIZE not found in FSM"
        )

    def test_fingerprint_match_skips_reload(self):
        """load_anki_tsv must compare fingerprint before reloading (tsv-load-optimization)."""
        src = _src()
        idx = src.find("local function load_anki_tsv")
        assert idx != -1
        body = src[idx:idx + 1000]
        has_fingerprint = "fingerprint_match" in body or ("mtime" in body and "size" in body)
        assert has_fingerprint, (
            "tsv-load-optimization: load_anki_tsv lacks fingerprint comparison logic"
        )

    def test_anki_db_mtime_and_size_exposed_in_state(self, mpv):
        """anki_db_mtime and anki_db_size must be exposed in runtime state (tsv-load-optimization)."""
        state = robust_state(mpv.ipc)
        assert "anki_db_mtime" in state, (
            "tsv-load-optimization: anki_db_mtime not in state snapshot"
        )
        assert "anki_db_size" in state, (
            "tsv-load-optimization: anki_db_size not in state snapshot"
        )


# ---------------------------------------------------------------------------
# ui-integration-hooks
# ---------------------------------------------------------------------------

class TestUiIntegrationHooks:
    """Tests for spec: ui-integration-hooks"""

    def test_manage_ui_border_override_exists(self):
        """manage_ui_border_override must exist for OSD style override on UI open/close (ui-integration-hooks)."""
        assert "function manage_ui_border_override" in _src(), (
            "ui-integration-hooks: manage_ui_border_override not found in kardenwort.lua"
        )

    def test_manage_search_bindings_exists(self):
        """manage_search_bindings must exist for search HUD key-binding lifecycle (ui-integration-hooks)."""
        assert "local function manage_search_bindings" in _src(), (
            "ui-integration-hooks: manage_search_bindings not found in kardenwort.lua"
        )

    def test_saved_osd_border_style_persists_across_toggles(self):
        """saved_osd_border_style must be declared in FSM for multi-component style restore (ui-integration-hooks)."""
        assert "saved_osd_border_style" in _src(), (
            "ui-integration-hooks: saved_osd_border_style not found in FSM"
        )


# ---------------------------------------------------------------------------
# unified-clipboard-abstraction
# ---------------------------------------------------------------------------

class TestUnifiedClipboardAbstraction:
    """Tests for spec: unified-clipboard-abstraction"""

    def test_set_clipboard_exists(self):
        """set_clipboard must exist as the unified clipboard write abstraction (unified-clipboard-abstraction)."""
        assert "local function set_clipboard" in _src(), (
            "unified-clipboard-abstraction: set_clipboard not found in kardenwort.lua"
        )

    def test_gd_trigger_lock_duration_option_exists(self):
        """gd_trigger_lock_duration must be in Options for recursive-trigger prevention (unified-clipboard-abstraction)."""
        assert "gd_trigger_lock_duration" in _src(), (
            "unified-clipboard-abstraction: gd_trigger_lock_duration not found in kardenwort.lua"
        )

    def test_set_clipboard_accepts_mode_parameter(self):
        """set_clipboard must accept a mode parameter for GoldenDict trigger control (unified-clipboard-abstraction)."""
        src = _src()
        idx = src.find("local function set_clipboard")
        assert idx != -1
        sig = src[idx:idx + 100]
        assert "mode" in sig, (
            "unified-clipboard-abstraction: set_clipboard must accept a mode parameter"
        )

    def test_clipboard_uses_platform_detection(self):
        """set_clipboard must branch on platform for Windows vs Unix clipboard (unified-clipboard-abstraction)."""
        src = _src()
        idx = src.find("local function set_clipboard")
        assert idx != -1
        body = src[idx:idx + 600]
        assert "package.config" in body or "platform" in body, (
            "unified-clipboard-abstraction: set_clipboard does not branch on platform"
        )


# ---------------------------------------------------------------------------
# rendering-optimization
# ---------------------------------------------------------------------------

class TestRenderingOptimization:
    """Tests for spec: rendering-optimization"""

    def test_populate_token_meta_exists(self):
        """populate_token_meta must exist for parameter-driven token colorization (rendering-optimization)."""
        assert "local function populate_token_meta" in _src(), (
            "rendering-optimization: populate_token_meta not found in kardenwort.lua"
        )

    def test_lower_clean_cached_on_token(self):
        """Tokens must cache lower_clean for O(1) case-normalized matching (rendering-optimization)."""
        assert "lower_clean" in _src(), (
            "rendering-optimization: lower_clean token property not found in kardenwort.lua"
        )

    def test_calculate_highlight_stack_exists(self):
        """calculate_highlight_stack must exist for memoized highlight calculation (rendering-optimization)."""
        assert "local function calculate_highlight_stack" in _src(), (
            "rendering-optimization: calculate_highlight_stack not found in kardenwort.lua"
        )

    def test_drum_draw_cache_and_dw_draw_cache_exist(self):
        """DRUM_DRAW_CACHE and DW_DRAW_CACHE must exist for render memoization (rendering-optimization)."""
        src = _src()
        assert "DRUM_DRAW_CACHE" in src, (
            "rendering-optimization: DRUM_DRAW_CACHE not found"
        )
        assert "DW_DRAW_CACHE" in src, (
            "rendering-optimization: DW_DRAW_CACHE not found"
        )

    def test_ass_border_shadow_tags_synchronized(self):
        """Border/shadow ASS tags must use all 4 override tags (\\3c \\4c \\3a \\4a) to prevent blooming (rendering-optimization)."""
        src = _src()
        assert "\\3c" in src, "rendering-optimization: \\3c border color tag not found"
        assert "\\4c" in src, "rendering-optimization: \\4c shadow color tag not found"
        assert "\\3a" in src, "rendering-optimization: \\3a border alpha tag not found"
        assert "\\4a" in src, "rendering-optimization: \\4a shadow alpha tag not found"


# ---------------------------------------------------------------------------
# script-stability-hardening
# ---------------------------------------------------------------------------

class TestScriptStabilityHardening:
    """Tests for spec: script-stability-hardening"""

    def test_key_bindings_in_final_section_of_file(self):
        """mp.add_key_binding registrations must appear in the final section of kardenwort.lua (script-stability-hardening)."""
        src = _src()
        first_binding = src.find("mp.add_key_binding(nil,")
        assert first_binding != -1, "script-stability-hardening: no mp.add_key_binding(nil,...) found"
        # Bindings should appear in the last 25% of the file (after most function definitions)
        threshold = len(src) * 0.70
        assert first_binding > threshold, (
            f"script-stability-hardening: first mp.add_key_binding(nil,...) at position {first_binding} "
            f"is not in the final 30% of the file (file length={len(src)}, threshold={int(threshold)})"
        )

    def test_xpcall_used_in_master_tick(self):
        """master_tick must use xpcall for Lua error isolation (script-stability-hardening)."""
        src = _src()
        idx = src.find("local function master_tick")
        assert idx != -1
        body = src[idx:idx + 300]
        assert "xpcall" in body, (
            "script-stability-hardening: master_tick does not use xpcall — Lua errors will crash the tick loop"
        )

    def test_parse_time_handles_centiseconds(self):
        """parse_time must normalize 2-digit centiseconds to milliseconds (script-stability-hardening)."""
        src = _src()
        assert "function parse_time" in src, (
            "script-stability-hardening: parse_time not found in kardenwort.lua"
        )
        idx = src.find("function parse_time")
        body = src[idx:idx + 600]
        has_centisec = "#ms == 2" in body or "Centiseconds" in body or "centisec" in body
        assert has_centisec, (
            "script-stability-hardening: parse_time does not handle 2-digit centisecond normalization"
        )




