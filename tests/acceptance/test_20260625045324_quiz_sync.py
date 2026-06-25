"""
Feature ZID: 20260624170848
Test Creation ZID: 20260625045324
Feature: Quiz Sync (MPV -> Quiz)
"""

import time
from tests.ipc.mpv_session import MpvSession
from tests.ipc.mpv_ipc import query_kardenwort_state


def test_quiz_sync_disabled_by_default(mpv):
    # Verify that the quiz_integration option is false by default
    state = query_kardenwort_state(mpv.ipc)
    assert state["options"].get("quiz_integration") is False

    # Triggering the keybinding with integration disabled should be a no-op
    # and should not cause any exceptions or errors in the player
    mpv.ipc.command(["script-binding", "kardenwort/sync-to-quiz"])
    time.sleep(0.1)


def test_quiz_sync_enabled_trigger(mpv):
    # Enable quiz integration and set a dummy pipe path via test-set-option
    mpv.ipc.command(["script-message-to", "kardenwort", "test-set-option", "quiz_integration", "true"])
    mpv.ipc.command(["script-message-to", "kardenwort", "test-set-option", "quiz_pipe_path", "\\\\.\\pipe\\non-existent-test-pipe"])
    time.sleep(0.05)

    # Verify options are updated
    state = query_kardenwort_state(mpv.ipc)
    assert state["options"].get("quiz_integration") is True
    assert state["options"].get("quiz_pipe_path") == "\\\\.\\pipe\\non-existent-test-pipe"

    # Trigger the sync. Since the pipe does not exist, the background python command
    # will run and exit with a failure/error, but it should do so asynchronously without blocking the player.
    mpv.ipc.command(["script-binding", "kardenwort/sync-to-quiz"])
    time.sleep(0.2)
