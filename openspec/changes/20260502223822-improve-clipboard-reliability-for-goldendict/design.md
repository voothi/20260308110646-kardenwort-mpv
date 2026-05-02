## Context

The `set_clipboard` function on Windows uses `powershell` with a `Set-Clipboard` command. To handle OS-level clipboard locking (common with dictionary tools like GoldenDict), it includes a retry loop. Currently, this loop is hardcoded to 5 attempts with a 50ms sleep. Users have reported intermittent synchronization gaps, suggesting these parameters need to be adjustable.

## Goals / Non-Goals

**Goals:**
- Externalize the clipboard retry parameters into the `Options` table.
- Use these options to construct the PowerShell command dynamically.
- Enable user-driven debugging of clipboard synchronization gaps.

**Non-Goals:**
- Rewriting the clipboard engine (e.g., using `clip.exe` or custom C extensions).
- Modifying non-Windows clipboard implementations.

## Decisions

### 1. New Options in `Options` Table
Add the following fields to the `Options` table in `lls_core.lua`:
- `win_clipboard_retries`: Total number of attempts (default: 5).
- `win_clipboard_retry_delay`: Delay between attempts in milliseconds (default: 50).

### 2. Dynamic Command Construction
Refactor `set_clipboard(text)` to inject these variables into the PowerShell string template.
- Use `%d` for the loop count.
- Use `%d` for the `Start-Sleep -Milliseconds` value.

### 3. Error Handling
The `ErrorAction Stop` in the `try/catch` block will remain to ensure the catch block is triggered on locking errors.

## Risks / Trade-offs

- **PowerShell Overhead**: Repeatedly spawning PowerShell is slow. If `win_clipboard_retries` is set too high, each copy operation might hang the script temporarily.
- **Mitigation**: Keep defaults low and only advise users to increase them if they experience gaps.
