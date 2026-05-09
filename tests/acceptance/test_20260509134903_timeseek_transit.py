"""
Feature ZID: 20260509130924 (rewind transit fix)
Test Creation ZID: 20260509134903

Feature: Time-Based Seek Transit (Shift+A/D)

When Shift+A/D (cmd_seek_time) is used in PHRASE/MOVIE + Autopause ON:
  - Active loop and scheduled replay are cancelled immediately.
  - A TIMESEEK_INHIBIT_UNTIL sentinel is set to the pre-seek time position.
  - Autopause is suppressed while time_pos <= TIMESEEK_INHIBIT_UNTIL (transit zone).
  - PHRASE jerk-back is suppressed while the sentinel is set.
  - The sentinel clears (strict >) AFTER jerk-back is evaluated, so the boundary
    tick itself is still fully protected.
  - Forward seek (dir > 0) clears the sentinel immediately.
  - Multiple backward presses accumulate: sentinel = max of all pre-seek positions.

Edge cases verified:
  - Sub 3/4 tight overlap (40 ms gap, 1000 ms padding) in fragment1 fixture.
  - Autopause fires correctly at the final subtitle boundary after the transit.

Sub timeline fragment1 (DE, audio_padding_start=1000ms, audio_padding_end=1000ms default):
  Sub 1: 4.295 – 5.295   eff: 3.295 – 6.295
  Sub 2: 6.555 – 11.088  eff: 5.555 – 12.088
  Sub 3: 11.175 – 12.722 eff: 10.175 – 13.722
  Sub 4: 12.762 – 15.117 eff: 11.762 – 16.117
  Sub 5: 15.716 – 20.049 eff: 14.716 – 21.049

Integration test strategy:
  The fixture starts paused, so `pause` state is unreliable as a test signal
  (it is always True regardless of whether autopause fired or was suppressed).
  Instead, FSM.last_paused_sub_end is used:
    - cmd_seek_time clears it to nil.
    - Direct seeks clear it via the jump-detection block.
    - If autopause fires it is set to the subtitle boundary value.
    - If autopause is suppressed it stays nil.
  This gives a deterministic signal without requiring live playback.
"""

import re
import time
import pytest
from tests.ipc.mpv_ipc import query_lls_state


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _src():
    with open("scripts/lls_core.lua", encoding="utf-8") as f:
        return f.read()


def _state(ipc, retries=6):
    for _ in range(retries):
        s = query_lls_state(ipc)
        if s and "options" in s:
            return s
        time.sleep(0.3)
    return query_lls_state(ipc)


def _setup_phrase_autopause(ipc):
    ipc.command(['script-message-to', 'lls_core', 'lls-immersion-mode-set', 'PHRASE'])
    ipc.command(['script-message-to', 'lls_core', 'lls-autopause-set', 'ON'])
    time.sleep(0.1)


def _seek(ipc, pos):
    ipc.command(['seek', pos, 'absolute+exact'])
    time.sleep(0.15)


def _seek_time(ipc, direction):
    """Trigger cmd_seek_time(direction) via IPC test message."""
    ipc.command(['script-message-to', 'lls_core', 'lls-test-seek-time', str(direction)])
    time.sleep(0.15)


def _func_body(src, name):
    """Return the body of the Lua function `name` up to the next top-level function."""
    for prefix in (f"local function {name}", f"function LlsProbe.{name}", f"function {name}"):
        idx = src.find(prefix)
        if idx != -1:
            break
    assert idx != -1, f"function {name} not found in lls_core.lua"
    end = src.find("\nlocal function ", idx + 1)
    return src[idx: end if end != -1 else idx + 4000]


# ---------------------------------------------------------------------------
# 1. Static / structural tests (source-code inspection)
# ---------------------------------------------------------------------------

class TestTimseekTransitStructural:
    """Verify the fix is wired correctly in lls_core.lua source."""

    def test_fsm_declares_timeseek_inhibit_until(self):
        """FSM must declare TIMESEEK_INHIBIT_UNTIL so the field is always initialised."""
        assert "TIMESEEK_INHIBIT_UNTIL" in _src(), (
            "FSM.TIMESEEK_INHIBIT_UNTIL not declared — rewind transit inhibit is missing"
        )

    def test_tick_autopause_uses_inclusive_check(self):
        """tick_autopause must use <= (inclusive) so the boundary tick is still suppressed."""
        body = _func_body(_src(), "tick_autopause")
        assert "time_pos <= FSM.TIMESEEK_INHIBIT_UNTIL" in body, (
            "tick_autopause does not use <= for TIMESEEK_INHIBIT_UNTIL — "
            "boundary tick is unprotected"
        )

    def test_tick_autopause_does_not_clear_inhibit(self):
        """tick_autopause must NOT clear TIMESEEK_INHIBIT_UNTIL (clear happens after jerk-back)."""
        body = _func_body(_src(), "tick_autopause")
        assert "TIMESEEK_INHIBIT_UNTIL = nil" not in body, (
            "tick_autopause clears TIMESEEK_INHIBIT_UNTIL internally — "
            "jerk-back would fire in the same tick"
        )

    def test_jerkback_gated_by_timeseek_inhibit(self):
        """Jerk-back logic must check `not FSM.TIMESEEK_INHIBIT_UNTIL`."""
        src = _src()
        # The check appears somewhere in the source; verify it exists and is near Jerk-Back
        assert "not FSM.TIMESEEK_INHIBIT_UNTIL" in src, (
            "not FSM.TIMESEEK_INHIBIT_UNTIL not found — jerk-back will fire during rewind transit"
        )
        # Also verify it is adjacent to the PHRASE / MANUAL_NAV_COOLDOWN condition
        idx = src.find("not FSM.TIMESEEK_INHIBIT_UNTIL")
        context = src[max(0, idx - 300): idx + 50]
        assert "IMMERSION_MODE" in context or "Jerk Back" in context, (
            "not FSM.TIMESEEK_INHIBIT_UNTIL found but not adjacent to the Jerk-Back block"
        )

    def test_inhibit_clears_after_jerkback_with_strict_gt(self):
        """TIMESEEK_INHIBIT_UNTIL must clear with `>` (strict) AFTER jerk-back evaluates."""
        src = _src()
        # The strict-greater-than guard must exist
        assert "time_pos > FSM.TIMESEEK_INHIBIT_UNTIL" in src, (
            "time_pos > FSM.TIMESEEK_INHIBIT_UNTIL not found — "
            "inhibit is not cleared (or cleared with >= allowing boundary-tick races)"
        )
        # The clear must appear AFTER the Jerk-Back comment
        jb_idx = src.find('Phrases Mode "Jerk Back" Logic')
        assert jb_idx != -1
        clear_idx = src.find("TIMESEEK_INHIBIT_UNTIL = nil", jb_idx)
        assert clear_idx != -1, "TIMESEEK_INHIBIT_UNTIL = nil not found after Jerk-Back block"
        guard_idx = src.rfind("time_pos > FSM.TIMESEEK_INHIBIT_UNTIL", 0, clear_idx + 100)
        assert guard_idx > jb_idx, (
            "time_pos > guard not found before the nil-clear after the Jerk-Back block"
        )

    def test_cmd_seek_time_cancels_loop_mode(self):
        """cmd_seek_time must set LOOP_MODE = 'OFF' to cancel active loops."""
        body = _func_body(_src(), "cmd_seek_time")
        assert 'LOOP_MODE = "OFF"' in body, (
            "cmd_seek_time does not cancel LOOP_MODE — loop fires after rewind"
        )

    def test_cmd_seek_time_cancels_scheduled_replay(self):
        """cmd_seek_time must nil SCHEDULED_REPLAY_START/END to cancel replays."""
        body = _func_body(_src(), "cmd_seek_time")
        assert "SCHEDULED_REPLAY_START = nil" in body, (
            "cmd_seek_time does not cancel SCHEDULED_REPLAY_START"
        )
        assert "SCHEDULED_REPLAY_END = nil" in body, (
            "cmd_seek_time does not cancel SCHEDULED_REPLAY_END"
        )

    def test_cmd_seek_time_sets_inhibit_on_backward(self):
        """cmd_seek_time must set TIMESEEK_INHIBIT_UNTIL = max(..., current_pos) when dir < 0."""
        body = _func_body(_src(), "cmd_seek_time")
        assert "TIMESEEK_INHIBIT_UNTIL" in body, (
            "cmd_seek_time does not set TIMESEEK_INHIBIT_UNTIL on backward seek"
        )
        assert "math.max" in body, (
            "cmd_seek_time does not use math.max for accumulating the inhibit position"
        )

    def test_cmd_seek_time_clears_inhibit_on_forward(self):
        """cmd_seek_time must clear TIMESEEK_INHIBIT_UNTIL = nil when dir > 0."""
        body = _func_body(_src(), "cmd_seek_time")
        assert "TIMESEEK_INHIBIT_UNTIL = nil" in body, (
            "cmd_seek_time does not clear TIMESEEK_INHIBIT_UNTIL on forward seek"
        )

    def test_state_snapshot_exposes_rewind_transit(self):
        """LlsProbe._snapshot must expose rewind_transit_active and rewind_transit_until."""
        src = _src()
        assert "rewind_transit_active" in src, "rewind_transit_active not in state snapshot"
        assert "rewind_transit_until" in src, "rewind_transit_until not in state snapshot"

    def test_state_snapshot_exposes_last_paused_sub_end(self):
        """LlsProbe._snapshot must expose last_paused_sub_end for integration testing."""
        assert "last_paused_sub_end" in _func_body(_src(), "_snapshot"), (
            "last_paused_sub_end not in state snapshot — integration tests cannot verify autopause"
        )

    def test_test_seek_time_message_registered(self):
        """lls-test-seek-time script message must be registered for IPC testing."""
        assert '"lls-test-seek-time"' in _src(), (
            "lls-test-seek-time message not registered — IPC test trigger missing"
        )


# ---------------------------------------------------------------------------
# 2. State / IPC tests (runtime, fragment1 fixture)
# ---------------------------------------------------------------------------

class TestTimseekTransitState:
    """Verify FSM state transitions via IPC after backward/forward time seeks."""

    def test_backward_seek_activates_inhibit(self, mpv_fragment1):
        """Backward time-seek must set rewind_transit_active = True."""
        ipc = mpv_fragment1.ipc
        _setup_phrase_autopause(ipc)
        _seek(ipc, 14.5)

        _seek_time(ipc, -1)

        state = _state(ipc)
        assert state.get('rewind_transit_active') is True, (
            f"rewind_transit_active should be True after backward seek, got: {state}"
        )

    def test_backward_seek_records_pre_seek_position(self, mpv_fragment1):
        """rewind_transit_until must approximate the position before the backward seek."""
        ipc = mpv_fragment1.ipc
        _setup_phrase_autopause(ipc)
        _seek(ipc, 14.5)

        _seek_time(ipc, -1)

        state = _state(ipc)
        until = state.get('rewind_transit_until', 0)
        assert 14.0 <= until <= 15.0, (
            f"rewind_transit_until should be ~14.5 (pre-seek pos), got {until}"
        )

    def test_multiple_backward_seeks_keep_max_inhibit(self, mpv_fragment1):
        """Multiple backward seeks must keep inhibit at the FIRST (highest) position."""
        ipc = mpv_fragment1.ipc
        _setup_phrase_autopause(ipc)
        _seek(ipc, 14.5)

        _seek_time(ipc, -1)  # 14.5 → ~12.5, TIMESEEK_INHIBIT_UNTIL = 14.5
        _seek_time(ipc, -1)  # 12.5 → ~10.5, max(14.5, 12.5) = 14.5

        state = _state(ipc)
        until = state.get('rewind_transit_until', 0)
        assert until >= 14.0, (
            f"rewind_transit_until dropped to {until} — max() accumulation is broken"
        )

    def test_forward_seek_clears_inhibit(self, mpv_fragment1):
        """Forward time-seek must clear rewind_transit_active (inhibit = nil)."""
        ipc = mpv_fragment1.ipc
        _setup_phrase_autopause(ipc)
        _seek(ipc, 14.5)
        _seek_time(ipc, -1)

        _seek_time(ipc, 1)

        state = _state(ipc)
        assert state.get('rewind_transit_active') is False, (
            f"rewind_transit_active should be False after forward seek, got: {state}"
        )

    def test_backward_seek_cancels_active_loop(self, mpv_fragment1):
        """Backward time-seek must cancel an active LOOP_MODE (from 's' with Autopause OFF)."""
        ipc = mpv_fragment1.ipc
        ipc.command(['script-message-to', 'lls_core', 'lls-autopause-set', 'OFF'])
        time.sleep(0.1)
        _seek(ipc, 4.8)
        ipc.command(['script-message-to', 'lls_core', 'lls-test-replay'])
        time.sleep(0.2)

        state_before = _state(ipc)
        assert state_before.get('loop_mode') == 'ON', (
            f"Precondition failed: loop_mode should be ON, got {state_before.get('loop_mode')}"
        )

        _seek_time(ipc, -1)

        state = _state(ipc)
        assert state.get('loop_mode') == 'OFF', (
            f"loop_mode should be OFF after backward time-seek, got {state.get('loop_mode')}"
        )
        assert state.get('replay_remaining') == 0, (
            f"replay_remaining should be 0, got {state.get('replay_remaining')}"
        )

    def test_backward_seek_cancels_scheduled_replay(self, mpv_fragment1):
        """Backward time-seek must cancel scheduled replay (from 's' with Autopause ON)."""
        ipc = mpv_fragment1.ipc
        _setup_phrase_autopause(ipc)
        ipc.command(['set_property', 'options/lls-replay_count', '3'])
        time.sleep(0.1)
        _seek(ipc, 4.8)
        ipc.command(['script-message-to', 'lls_core', 'lls-test-replay'])
        time.sleep(0.2)

        state_before = _state(ipc)
        assert state_before.get('replay_remaining', 0) > 0, (
            "Precondition failed: replay_remaining should be > 0 after triggering replay"
        )

        _seek_time(ipc, -1)

        state = _state(ipc)
        assert state.get('replay_remaining') == 0, (
            f"replay_remaining should be 0 after backward time-seek, got {state.get('replay_remaining')}"
        )


# ---------------------------------------------------------------------------
# 3. Integration tests
#
# The fixture starts paused, so `pause` state is unreliable.
# We use FSM.last_paused_sub_end as the autopause trigger indicator:
#   - cmd_seek_time clears it to nil.
#   - Each direct seek (jump > 0.3s) also clears it via the jump-detection block.
#   - If autopause fires → last_paused_sub_end = subtitle boundary value (non-nil).
#   - If suppressed → stays nil.
#
# Boundary positions for fragment1 with audio_padding = 1000 ms:
#   Sub 3 eff end = 12.722 + 1.0 = 13.722   (intermediate — must NOT trigger)
#   Sub 4 eff end = 15.117 + 1.0 = 16.117   (final — MUST trigger after transit)
# ---------------------------------------------------------------------------

class TestTimseekTransitIntegration:

    def test_autopause_suppressed_at_sub3_boundary_during_transit(self, mpv_fragment1):
        """Direct seek to sub 3 eff end (13.722) inside inhibit zone must NOT set last_paused_sub_end."""
        ipc = mpv_fragment1.ipc
        _setup_phrase_autopause(ipc)
        _seek(ipc, 14.5)         # prime ACTIVE_IDX at sub 4; TIMESEEK_INHIBIT_UNTIL = nil
        _seek_time(ipc, -1)      # → ~12.5, inhibit = 14.5, last_paused_sub_end = nil
        _seek_time(ipc, -1)      # → ~10.5

        # Simulate playback reaching sub 3's effective end — within the inhibit zone
        _seek(ipc, 13.722)       # jump clears last_paused_sub_end; autopause must be suppressed

        state = _state(ipc)
        assert state.get('last_paused_sub_end') is None, (
            f"Autopause fired at sub 3 boundary (13.722) during rewind transit — "
            f"last_paused_sub_end={state.get('last_paused_sub_end')} (expected None)"
        )

    def test_inhibit_clears_once_past_original_position(self, mpv_fragment1):
        """Direct seek past the original pre-seek position must clear the inhibit."""
        ipc = mpv_fragment1.ipc
        _setup_phrase_autopause(ipc)
        _seek(ipc, 14.5)
        _seek_time(ipc, -1)
        _seek_time(ipc, -1)

        _seek(ipc, 14.6)  # 14.6 > 14.5 → strict > clears inhibit

        state = _state(ipc)
        assert state.get('rewind_transit_active') is False, (
            f"rewind_transit_active should be False after crossing inhibit boundary "
            f"(time_pos=14.6 > inhibit~14.5), got: {state}"
        )

    def test_autopause_fires_at_final_boundary_after_transit(self, mpv_fragment1):
        """After transit ends, direct seek to sub 4 eff end (15.317) must set last_paused_sub_end."""
        ipc = mpv_fragment1.ipc
        _setup_phrase_autopause(ipc)
        _seek(ipc, 14.5)
        _seek_time(ipc, -1)
        _seek_time(ipc, -1)

        # Advance past inhibit to clear it; ACTIVE_IDX remains on sub 4
        _seek(ipc, 14.6)
        state_mid = _state(ipc)
        assert state_mid.get('rewind_transit_active') is False, (
            "Precondition: inhibit must be clear at 14.6"
        )

        # Seek to sub 4's effective end (15.117 + 1000ms padding = 16.117) — autopause must fire.
        # ACTIVE_IDX = 4 carries over from tick at 14.6 (sticky sentinel, sub 4 eff: 11.762-16.117).
        _seek(ipc, 16.117)

        state = _state(ipc)
        lpe = state.get('last_paused_sub_end')
        assert lpe is not None and abs(lpe - 16.117) < 0.05, (
            f"Autopause did not fire at sub 4 eff end (16.117) — "
            f"last_paused_sub_end={lpe} (expected ~16.117)"
        )

    def test_movie_mode_transit_no_pause_at_sub3_boundary(self, mpv_fragment1):
        """In MOVIE mode: direct seek to sub 3 eff end inside inhibit zone must not set last_paused_sub_end."""
        ipc = mpv_fragment1.ipc
        ipc.command(['script-message-to', 'lls_core', 'lls-immersion-mode-set', 'MOVIE'])
        ipc.command(['script-message-to', 'lls_core', 'lls-autopause-set', 'ON'])
        time.sleep(0.1)

        _seek(ipc, 14.5)
        _seek_time(ipc, -1)
        _seek_time(ipc, -1)

        _seek(ipc, 13.722)

        state = _state(ipc)
        assert state.get('last_paused_sub_end') is None, (
            f"Autopause fired at sub 3 boundary in MOVIE mode during rewind transit — "
            f"last_paused_sub_end={state.get('last_paused_sub_end')}"
        )

    def test_no_inhibit_without_backward_seek(self, mpv_fragment1):
        """Without a time-seek, rewind_transit_active must remain False."""
        ipc = mpv_fragment1.ipc
        _setup_phrase_autopause(ipc)
        _seek(ipc, 14.5)

        state = _state(ipc)
        assert state.get('rewind_transit_active') is False, (
            "rewind_transit_active is True without any backward seek — spurious inhibit"
        )

    def test_inhibit_not_set_by_direct_seek(self, mpv_fragment1):
        """Direct IPC seek (not cmd_seek_time) must NOT set rewind_transit_active."""
        ipc = mpv_fragment1.ipc
        _setup_phrase_autopause(ipc)

        _seek(ipc, 10.5)  # raw IPC seek — NOT a time-seek

        state = _state(ipc)
        assert state.get('rewind_transit_active') is False, (
            "Direct IPC seek set rewind_transit_active — only cmd_seek_time should do this"
        )
