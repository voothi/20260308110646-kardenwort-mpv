## Context

Intermittent clipboard synchronization failures and keyboard layout inconsistencies (EN/RU) necessitated a more robust bridge between Kardenwort-mpv and GoldenDict. The legacy polling method in AHK was unreliable, and standard `.NET SendKeys` was prone to "garbage" character injection.

## Goals / Non-Goals

**Goals:**
- Provide a 100% layout-independent trigger for GoldenDict (EN/RU).
- Support dual-mode lookups (Side Popup vs. Main Window).
- Eliminate "garbage" character injection (`q`, `й`) during hotkey triggering.
- Ensure non-blocking execution of the notification bridge.

**Non-Goals:**
- Modifying external AHK scripts (logic must be layout-agnostic on the MPV side).

## Decisions

### 1. Unified Naming Standard
- **Decision**: Adopt the `gd_` prefix for all dictionary bridge settings and `dw_` for trigger keys.
- **Rationale**: Clearer separation of concerns in `mpv.conf` between the notification mechanism and the player's keybindings.

### 2. Layout-Independent VK Injection
- **Decision**: Use Win32 `keybd_event` via PowerShell `Add-Type` to send raw Virtual Key (VK) signals.
- **Rationale**: Unlike character-based `SendKeys`, VK codes are layout-agnostic and avoid "typing" letters, preventing search field pollution.

### 3. Dual-Mode Triggering
- **Decision**: Implement a `mode` parameter in copy commands to differentiate between `side` (popup) and `main` (full window) lookups.
- **Rationale**: Matches the existing AHK architecture while providing precise control from the player.

### 4. Asynchronous Bridge
- **Decision**: Execute the PowerShell notification process asynchronously via `mp.command_native_async`.
- **Rationale**: Prevents any UI lag or playback stutter during the OS-level key injection.

## Risks / Trade-offs

- **[Risk] Shell Overhead** → **Mitigation**: Asynchronous execution ensures the overhead doesn't impact the player's main thread.
- **[Risk] Type Compilation Delay** → **Mitigation**: Using a unique class name per call ensures session safety, while the 10ms micro-buffer ensures OS-level modifier stability.
