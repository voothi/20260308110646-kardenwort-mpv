import time
from tests.ipc.mpv_ipc import query_kardenwort_state


def test_20260517200951_test_truncate_utf8_boundary_safe(mpv):
    ipc = mpv.ipc

    # 4 ASCII + 1 Cyrillic, truncated at 5 chars: byte slicing would corrupt the Cyrillic edge.
    ipc.command(["script-message-to", "kardenwort", "test-truncate", "abcdйefgh", "5"])
    time.sleep(0.1)

    state = query_kardenwort_state(ipc)
    truncated = state.get("test_data", {}).get("test_truncated_str", "")

    assert truncated == "abcdй..."
    assert "Ñ" not in truncated


def test_20260517200951_copy_preview_builder_utf8_clean(mpv):
    ipc = mpv.ipc

    text = "коробку и затем кладет ее в фургон."
    ipc.command(["script-message-to", "kardenwort", "test-build-copy-preview", "DW", text, "22"])
    time.sleep(0.1)

    state = query_kardenwort_state(ipc)
    preview = state.get("test_data", {}).get("test_copy_preview", "")

    assert preview == "DW Copied: коробку и затем кладет..."
    assert "Ñ" not in preview
    assert "�" not in preview
