## 1. Configure Options

- [x] 1.1 Add `win_clipboard_retries` (default 5) to `Options` table in `scripts/lls_core.lua`.
- [x] 1.2 Add `win_clipboard_retry_delay` (default 50) to `Options` table in `scripts/lls_core.lua`.
- [x] 1.3 Add `win_clipboard_retries` and `win_clipboard_retry_delay` documentation and defaults to `mpv.conf`.

## 2. Refactor Clipboard Function

- [x] 2.1 Locate `set_clipboard(text)` in `scripts/lls_core.lua`.
- [x] 2.2 Update the PowerShell command template to use `Options.win_clipboard_retries` and `Options.win_clipboard_retry_delay`.
- [x] 2.3 Verify that string formatting for the PowerShell command remains safe (quoting and encoding).

## 3. Verification

- [x] 3.1 Verify that normal copy operations still work on Windows.
- [x] 3.2 Test with a high retry count and observe the behavior if the clipboard is manually locked.
- [x] 3.3 Verify that UTF-8 characters are still correctly copied.
