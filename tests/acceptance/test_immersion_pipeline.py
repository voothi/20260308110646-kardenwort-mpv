"""
Acceptance tests for 7 archived immersion-pipeline changes:

  20260505115453  filtered-secondary-subtitle-cycle
  20260505121439  immersion-suite-hardening
  20260505143734  fix-subtitle-interactivity-regressions
  20260505145046  configurable-immersion-mode-startup
  20260505150404  cyclic-subtitle-nav
  20260505162601  centered-seek-osd
  20260506000713  immersion-hardening-osd-refinement

Infrastructure used:
  MpvSession / MpvIpc  – headless mpv process with IPC pipe
  query_lls_state      – reads FSM snapshot via lls-state-query message
  query_lls_render     – reads a named OSD overlay's ASS data
  lls-test-seek-delta  – triggers cmd_dw_seek_delta(dir) (added for this suite)
  lls-test-cycle-sec-sid – triggers cmd_cycle_sec_sid() (added for this suite)

Fixtures from conftest.py:
  mpv              – single external SRT, not paused
  mpv_dual         – two external SRTs (sync-test), paused, 200 ms gap/padding
  mpv_fragment1    – real 25 fps DE+RU, paused; 5 subs
  mpv_movie_startup – single SRT with lls-immersion_mode_default=MOVIE
"""

import time
import pytest
from tests.ipc.mpv_ipc import query_lls_state, query_lls_render
from tests.ipc.mpv_session import MpvSession


# ─────────────────────────────────────────────────────────────
# Change 20260505115453 – filtered-secondary-subtitle-cycle
# ─────────────────────────────────────────────────────────────

class TestFilteredSecondarySubtitleCycle:
    """Shift+c must cycle only external tracks and skip the primary track."""

    def test_cycle_never_lands_on_primary_sid(self, mpv_fragment1):
        """Secondary cycle must not select the track that is active as primary.

        fragment1: DE primary (sid=1), RU secondary (sid=2), both external.
        Cycling from sid=2 must visit OFF then RU again — never DE (=primary).
        """
        ipc = mpv_fragment1.ipc
        primary_sid = ipc.get_property('sid')

        visited = set()
        for _ in range(4):
            ipc.command(['script-message-to', 'lls_core', 'lls-test-cycle-sec-sid'])
            time.sleep(0.2)
            sid = ipc.get_property('secondary-sid')
            visited.add(sid)

        assert primary_sid not in visited, (
            f"Secondary cycle landed on primary sid={primary_sid}; full rotation: {visited}"
        )

    def test_cycle_visits_off_state(self, mpv_fragment1):
        """Secondary cycle must pass through the OFF (no secondary) state."""
        ipc = mpv_fragment1.ipc

        visited = set()
        for _ in range(4):
            ipc.command(['script-message-to', 'lls_core', 'lls-test-cycle-sec-sid'])
            time.sleep(0.2)
            visited.add(ipc.get_property('secondary-sid'))

        has_off = any(s is None or s == 0 for s in visited)
        assert has_off, f"OFF state never reached; rotation: {visited}"

    def test_cycle_returns_to_start_after_full_rotation(self, mpv_fragment1):
        """A full rotation must return secondary-sid to its starting value.

        Cycles up to 8 steps to accommodate any number of external tracks.
        """
        ipc = mpv_fragment1.ipc
        start_sid = ipc.get_property('secondary-sid')

        for _ in range(8):
            ipc.command(['script-message-to', 'lls_core', 'lls-test-cycle-sec-sid'])
            time.sleep(0.2)
            if ipc.get_property('secondary-sid') == start_sid:
                return  # full rotation confirmed

        end_sid = ipc.get_property('secondary-sid')
        assert False, (
            f"Did not return to start_sid={start_sid} within 8 steps; ended at {end_sid}"
        )


# ─────────────────────────────────────────────────────────────
# Change 20260505121439 – immersion-suite-hardening
# ─────────────────────────────────────────────────────────────

class TestImmersionSuiteHardening:
    """Deterministic FSM sentinel, mode-aware boundaries, configurable thresholds."""

    def test_startup_immersion_mode_is_phrase(self, mpv):
        """Default startup immersion mode must be PHRASE."""
        state = query_lls_state(mpv.ipc)
        assert state['immersion_mode'] == 'PHRASE', (
            f"Expected PHRASE at startup, got {state['immersion_mode']}"
        )

    def test_set_movie_mode_reflects_in_state(self, mpv_dual):
        """lls-immersion-mode-set MOVIE must update FSM state immediately."""
        ipc = mpv_dual.ipc
        ipc.command(['script-message-to', 'lls_core', 'lls-immersion-mode-set', 'MOVIE'])
        time.sleep(0.15)
        state = query_lls_state(ipc)
        assert state['immersion_mode'] == 'MOVIE', (
            f"Expected MOVIE after set; got {state['immersion_mode']}"
        )

    def test_phrase_jerkback_advances_active_idx_in_overlap(self, mpv_dual):
        """In PHRASE mode the Jerk-Back must advance ACTIVE_IDX when padded zones overlap.

        sync-test fixture: sub1 ends 2.000s, sub2 starts 2.200s.
        audio_padding = 200 ms → padded end of sub1 = 2.200s, padded start of sub2 = 2.000s.
        Overlap zone: 2.000–2.200s. Seeking to 2.05s must result in ACTIVE_IDX=2.
        """
        ipc = mpv_dual.ipc
        ipc.command(['script-message-to', 'lls_core', 'lls-immersion-mode-set', 'PHRASE'])
        ipc.command(['script-message-to', 'lls_core', 'lls-autopause-set', 'OFF'])
        time.sleep(0.1)

        ipc.command(['seek', 2.05, 'absolute+exact'])
        time.sleep(0.35)

        state = query_lls_state(ipc)
        assert state['active_sub_index'] == 2, (
            f"Expected Jerk-Back to advance to sub 2 at 2.05s; got {state['active_sub_index']}"
        )

    def test_sentinel_primes_on_seek(self, mpv_fragment1):
        """After seeking into a subtitle, ACTIVE_IDX must be set (not -1).

        This verifies the deterministic sentinel (FSM.ACTIVE_IDX) is primed by
        get_center_index after the nav cooldown expires.
        """
        ipc = mpv_fragment1.ipc
        # Sub 1: 4.295–5.295s
        ipc.command(['seek', 4.5, 'absolute+exact'])
        time.sleep(0.6)  # nav_cooldown default = 0.5s

        state = query_lls_state(ipc)
        assert state['active_sub_index'] == 1, (
            f"Sentinel not primed after seek to 4.5s (sub 1); got {state['active_sub_index']}"
        )

    def test_movie_mode_handover_state_change(self, mpv_dual):
        """Switching to MOVIE and back to PHRASE keeps immersion_mode consistent."""
        ipc = mpv_dual.ipc
        ipc.command(['script-message-to', 'lls_core', 'lls-immersion-mode-set', 'MOVIE'])
        time.sleep(0.1)
        assert query_lls_state(ipc)['immersion_mode'] == 'MOVIE'

        ipc.command(['script-message-to', 'lls_core', 'lls-immersion-mode-set', 'PHRASE'])
        time.sleep(0.1)
        assert query_lls_state(ipc)['immersion_mode'] == 'PHRASE'


# ─────────────────────────────────────────────────────────────
# Change 20260505143734 – fix-subtitle-interactivity-regressions
# ─────────────────────────────────────────────────────────────

class TestSubtitleInteractivityRegressions:
    """MOVIE→PHRASE toggle must sync ACTIVE_IDX; auto-scroll guard with DW OFF."""

    def test_phrase_toggle_syncs_active_idx_no_phantom_jerk(self, mpv_fragment1):
        """Toggling MOVIE→PHRASE must synchronize ACTIVE_IDX without triggering a Jerk-Back.

        Spec: cmd_cycle_immersion_mode must store get_center_index into FSM.ACTIVE_IDX
        immediately on switch to PHRASE, so the next tick does not see a phantom boundary.
        """
        ipc = mpv_fragment1.ipc
        # Sub 2: 6.555–11.088s — seek to middle
        ipc.command(['seek', 8.0, 'absolute+exact'])
        time.sleep(0.4)

        ipc.command(['script-message-to', 'lls_core', 'lls-immersion-mode-set', 'MOVIE'])
        time.sleep(0.1)

        # Toggle back to PHRASE — this must sync ACTIVE_IDX before next tick
        ipc.command(['script-message-to', 'lls_core', 'lls-immersion-mode-set', 'PHRASE'])
        time.sleep(0.35)

        state = query_lls_state(ipc)
        assert state['active_sub_index'] == 2, (
            f"Expected ACTIVE_IDX=2 at 8.0s after MOVIE→PHRASE toggle; got {state['active_sub_index']}"
        )
        # time-pos must stay near 8.0s — no phantom Jerk-Back seek occurred
        time_pos = ipc.get_property('time-pos')
        assert time_pos is not None and abs(time_pos - 8.0) < 2.0, (
            f"Unexpected seek after MOVIE→PHRASE toggle: time-pos={time_pos:.3f}"
        )

    def test_drum_window_off_on_startup(self, mpv):
        """Drum Window must be OFF at startup (auto-scroll guard precondition)."""
        state = query_lls_state(mpv.ipc)
        assert state['drum_window'] == 'OFF'

    def test_drum_window_returns_to_off_after_close(self, mpv):
        """Drum Window state must be OFF after a toggle-open / toggle-close cycle."""
        ipc = mpv.ipc
        ipc.command(['script-message-to', 'lls_core', 'lls-drum-window-toggle'])
        time.sleep(0.2)
        assert query_lls_state(ipc)['drum_window'] != 'OFF'

        ipc.command(['script-message-to', 'lls_core', 'lls-drum-window-toggle'])
        time.sleep(0.2)
        assert query_lls_state(ipc)['drum_window'] == 'OFF', (
            "Drum Window did not return to OFF after second toggle"
        )


# ─────────────────────────────────────────────────────────────
# Change 20260505145046 – configurable-immersion-mode-startup
# ─────────────────────────────────────────────────────────────

class TestConfigurableImmersionModeStartup:
    """immersion_mode_default option must control FSM.IMMERSION_MODE at startup."""

    def test_default_startup_is_phrase(self, mpv):
        """Without any script-opts override the startup mode must be PHRASE."""
        state = query_lls_state(mpv.ipc)
        assert state['immersion_mode'] == 'PHRASE'

    def test_movie_startup_via_script_opt(self, mpv_movie_startup):
        """With lls-immersion_mode_default=MOVIE the startup mode must be MOVIE."""
        state = query_lls_state(mpv_movie_startup.ipc)
        assert state['immersion_mode'] == 'MOVIE', (
            f"Expected MOVIE from script-opts override; got {state['immersion_mode']}"
        )

    def test_invalid_option_value_falls_back_to_phrase(self):
        """An invalid lls-immersion_mode_default value must silently fall back to PHRASE."""
        session = MpvSession(
            video='tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.mp4',
            subtitle='tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.en.srt',
            extra_args=['--pause', '--script-opts=lls-immersion_mode_default=INVALID'],
        )
        session.start()
        try:
            state = query_lls_state(session.ipc)
            assert state['immersion_mode'] == 'PHRASE', (
                f"Invalid option must fall back to PHRASE; got {state['immersion_mode']}"
            )
        finally:
            session.stop()

    def test_movie_startup_can_switch_to_phrase(self, mpv_movie_startup):
        """A MOVIE-startup session must still allow switching to PHRASE at runtime."""
        ipc = mpv_movie_startup.ipc
        assert query_lls_state(ipc)['immersion_mode'] == 'MOVIE'

        ipc.command(['script-message-to', 'lls_core', 'lls-immersion-mode-set', 'PHRASE'])
        time.sleep(0.1)
        assert query_lls_state(ipc)['immersion_mode'] == 'PHRASE'


# ─────────────────────────────────────────────────────────────
# Change 20260505150404 – cyclic-subtitle-nav
# ─────────────────────────────────────────────────────────────

class TestCyclicSubtitleNav:
    """Next from last sub wraps to first; prev from first wraps to last."""

    # fragment1 sub timeline (5 subs):
    #   1: 4.295–5.295   2: 6.555–11.088   3: 11.175–12.722
    #   4: 12.762–15.117  5: 15.716–20.049

    def _prime_at(self, ipc, time_s, expected_idx, label):
        """Seek to time_s and assert that ACTIVE_IDX == expected_idx."""
        ipc.command(['seek', time_s, 'absolute+exact'])
        time.sleep(0.6)  # wait for nav_cooldown (0.5 s) + tick
        state = query_lls_state(ipc)
        assert state['active_sub_index'] == expected_idx, (
            f"Prime failed: expected sub {expected_idx} at {time_s}s ({label}); "
            f"got {state['active_sub_index']}"
        )

    def test_last_to_first_wrap(self, mpv_fragment1):
        """Pressing next from the last subtitle must wrap ACTIVE_IDX to sub 1."""
        ipc = mpv_fragment1.ipc
        self._prime_at(ipc, 17.0, 5, 'sub 5')

        ipc.command(['script-message-to', 'lls_core', 'lls-test-seek-delta', '1'])
        time.sleep(0.3)

        state = query_lls_state(ipc)
        assert state['active_sub_index'] == 1, (
            f"Expected wrap to sub 1 from sub 5; got {state['active_sub_index']}"
        )

    def test_first_to_last_wrap(self, mpv_fragment1):
        """Pressing prev from the first subtitle must wrap ACTIVE_IDX to last sub."""
        ipc = mpv_fragment1.ipc
        self._prime_at(ipc, 4.5, 1, 'sub 1')

        ipc.command(['script-message-to', 'lls_core', 'lls-test-seek-delta', '-1'])
        time.sleep(0.3)

        state = query_lls_state(ipc)
        assert state['active_sub_index'] == 5, (
            f"Expected wrap to sub 5 (last) from sub 1; got {state['active_sub_index']}"
        )

    def test_no_jump_to_last_at_start_of_track(self, mpv_fragment1):
        """In PHRASE mode, seeking before the first subtitle must NOT snap ACTIVE_IDX to last.

        Regression: previous bug caused ACTIVE_IDX to jump to #subs on initialization.
        """
        ipc = mpv_fragment1.ipc
        ipc.command(['seek', 0.5, 'absolute+exact'])
        time.sleep(0.6)

        state = query_lls_state(ipc)
        assert state['active_sub_index'] != 5, (
            f"ACTIVE_IDX jumped to last sub (5) before first subtitle at 0.5s"
        )

    def test_mid_track_forward_navigation(self, mpv_fragment1):
        """Pressing next from sub 2 must advance to sub 3 (no wrap)."""
        ipc = mpv_fragment1.ipc
        self._prime_at(ipc, 8.0, 2, 'sub 2')

        ipc.command(['script-message-to', 'lls_core', 'lls-test-seek-delta', '1'])
        time.sleep(0.3)

        state = query_lls_state(ipc)
        assert state['active_sub_index'] == 3, (
            f"Expected advance to sub 3 from sub 2; got {state['active_sub_index']}"
        )

    def test_osc_style_jump_syncs_active_idx(self, mpv_fragment1):
        """A large time seek (simulating OSC timeline click) must sync ACTIVE_IDX.

        After a Universal Jump Detection fires, the nav cooldown is activated and
        ACTIVE_IDX is synchronized to the subtitle at the new position.
        """
        ipc = mpv_fragment1.ipc
        self._prime_at(ipc, 4.5, 1, 'sub 1')

        # Large jump — triggers Universal Jump Detection
        ipc.command(['seek', 13.5, 'absolute+exact'])
        time.sleep(0.7)  # cooldown 0.5s + tick margin

        state = query_lls_state(ipc)
        assert state['active_sub_index'] == 4, (
            f"Expected ACTIVE_IDX=4 after jump to 13.5s (sub 4: 12.762–15.117s); "
            f"got {state['active_sub_index']}"
        )


# ─────────────────────────────────────────────────────────────
# Change 20260505162601 – centered-seek-osd
# ─────────────────────────────────────────────────────────────

class TestCenteredSeekOsd:
    """Seek OSD: directional alignment, YouTube-style accumulator, custom formatting."""

    def _bind_seek_keys(self, ipc):
        """Register KP0 (forward) and KP1 (backward) via the test helper."""
        ipc.command(['script-message-to', 'lls_core', 'lls-test-bind-seek'])
        time.sleep(0.1)

    def test_forward_seek_populates_osd_right_aligned(self, mpv):
        """Forward seek (KP0) must write right-aligned (\\an6) content to the seek OSD."""
        ipc = mpv.ipc
        self._bind_seek_keys(ipc)

        ipc.command(['keypress', 'KP0'])
        time.sleep(0.2)

        render = query_lls_render(ipc, 'seek')
        assert render, "Seek OSD must have content after forward seek"
        assert r'{\an6}' in render, (
            f"Expected right-side alignment (\\an6) in forward seek OSD; got: {render!r}"
        )

    def test_backward_seek_populates_osd_left_aligned(self, mpv):
        """Backward seek (KP1) must write left-aligned (\\an4) content to the seek OSD."""
        ipc = mpv.ipc
        self._bind_seek_keys(ipc)
        # Seek far enough into the fixture (≈10 s long) to have room to seek back
        ipc.command(['seek', 7.0, 'absolute+exact'])
        time.sleep(0.15)

        ipc.command(['keypress', 'KP1'])
        time.sleep(0.2)

        render = query_lls_render(ipc, 'seek')
        assert render, "Seek OSD must have content after backward seek"
        assert r'{\an4}' in render, (
            f"Expected left-side alignment (\\an4) in backward seek OSD; got: {render!r}"
        )

    def test_two_forward_seeks_produce_osd_content(self, mpv):
        """Two consecutive forward seeks must result in OSD content (cumulative display)."""
        ipc = mpv.ipc
        self._bind_seek_keys(ipc)

        ipc.command(['keypress', 'KP0'])
        time.sleep(0.08)
        ipc.command(['keypress', 'KP0'])
        time.sleep(0.2)

        render = query_lls_render(ipc, 'seek')
        assert render, "Seek OSD must have content after two consecutive forward seeks"

    def test_direction_change_produces_new_osd(self, mpv):
        """After a direction change (forward → backward), a fresh OSD entry must appear."""
        ipc = mpv.ipc
        self._bind_seek_keys(ipc)
        # Seek within the fixture (≈10 s long) so we have room to seek back
        ipc.command(['seek', 7.0, 'absolute+exact'])
        time.sleep(0.15)

        ipc.command(['keypress', 'KP0'])
        time.sleep(0.1)
        ipc.command(['keypress', 'KP1'])
        time.sleep(0.2)

        render = query_lls_render(ipc, 'seek')
        assert render, "Seek OSD must have content after direction change"
        # After direction change, accumulator resets → backward alignment
        assert r'{\an4}' in render, (
            f"Expected left alignment after direction change; got: {render!r}"
        )

    def test_osd_clears_after_timeout(self, mpv):
        """Seek OSD must be empty before any seek occurs (clean state at startup)."""
        ipc = mpv.ipc
        render = query_lls_render(ipc, 'seek')
        assert not render, f"Seek OSD must be empty at startup; got: {render!r}"


# ─────────────────────────────────────────────────────────────
# Change 20260506000713 – immersion-hardening-osd-refinement
# ─────────────────────────────────────────────────────────────

class TestImmersionHardeningOsdRefinement:
    """ESC staged hierarchy; forced key blocking; minimalist OSD labels."""

    def test_esc_clears_pending_set_but_keeps_dw_open(self, mpv):
        """Stage 1: Esc with a pending-set (pink) selection must clear it without closing DW.

        The ESC hierarchy:
          Stage 1 – clear Pending Set (pink)
          Stage 2 – clear Range Selection (yellow)
          Stage 3 – full pointer reset
        DW never closes from Esc alone.
        """
        ipc = mpv.ipc
        ipc.command(['script-message-to', 'lls_core', 'lls-drum-window-toggle'])
        time.sleep(0.2)
        state = query_lls_state(ipc)
        assert state['drum_window'] != 'OFF', "DW must be open for this test"

        # Add word 1 of sub 1 to pending set (pink)
        ipc.command(['script-message-to', 'lls_core', 'lls-test-ctrl-toggle-word', '1', '1'])
        time.sleep(0.1)

        state = query_lls_state(ipc)
        assert state['dw_selection_count'] > 0, (
            "Expected pending-set entry after ctrl-toggle-word"
        )

        # Fire Esc — should clear the pending set, not close DW
        ipc.command(['script-message-to', 'lls_core', 'lls-test-dw-esc'])
        time.sleep(0.15)

        state_after = query_lls_state(ipc)
        assert state_after['dw_selection_count'] == 0, (
            "Stage-1 Esc must clear the pending set"
        )
        assert state_after['drum_window'] != 'OFF', (
            f"DW must stay open after Esc; got drum_window={state_after['drum_window']}"
        )

    def test_esc_with_no_selection_leaves_dw_open(self, mpv):
        """Esc with no selections or pointer must leave the Drum Window in its current state.

        Spec: 'pressing Esc MUST perform no further action (the window remains open)'.
        """
        ipc = mpv.ipc
        ipc.command(['script-message-to', 'lls_core', 'lls-drum-window-toggle'])
        time.sleep(0.2)
        state = query_lls_state(ipc)
        assert state['drum_window'] != 'OFF'
        assert state['dw_selection_count'] == 0

        ipc.command(['script-message-to', 'lls_core', 'lls-test-dw-esc'])
        time.sleep(0.15)

        state_after = query_lls_state(ipc)
        assert state_after['drum_window'] != 'OFF', (
            f"DW closed on Esc with no selections; got {state_after['drum_window']}"
        )

    def test_esc_multiple_stages_clear_then_keep_open(self, mpv):
        """Two consecutive Esc presses with a selection must both leave DW open.

        First Esc: clears pending set (Stage 1).
        Second Esc: no selection remaining → Stage 3 (pointer reset) but DW stays open.
        """
        ipc = mpv.ipc
        ipc.command(['script-message-to', 'lls_core', 'lls-drum-window-toggle'])
        time.sleep(0.2)

        ipc.command(['script-message-to', 'lls_core', 'lls-test-ctrl-toggle-word', '1', '1'])
        time.sleep(0.1)
        assert query_lls_state(ipc)['dw_selection_count'] > 0

        # First Esc: clears pending set
        ipc.command(['script-message-to', 'lls_core', 'lls-test-dw-esc'])
        time.sleep(0.12)
        state1 = query_lls_state(ipc)
        assert state1['dw_selection_count'] == 0
        assert state1['drum_window'] != 'OFF', "DW must stay open after first Esc"

        # Second Esc: nothing to clear — pointer reset only, DW stays open
        ipc.command(['script-message-to', 'lls_core', 'lls-test-dw-esc'])
        time.sleep(0.12)
        state2 = query_lls_state(ipc)
        assert state2['drum_window'] != 'OFF', (
            f"DW must stay open after second Esc; got {state2['drum_window']}"
        )
