## Context

Intermittent clipboard synchronization failures and keyboard layout inconsistencies (EN/RU) necessitated a more robust bridge between Kardenwort-mpv and GoldenDict. The legacy polling method in AHK was unreliable, and standard `.NET SendKeys` was prone to "garbage" character injection.

## Goals / Non-Goals

# Design: Hardened Clipboard State Machine (v1.58.58)

## Architectural Overview
The bridge is designed as a non-blocking, event-driven service that mediates between MPV's Lua environment and the Windows operating system. It prioritizes **Atomicity** (ensuring clipboard data is ready before signaling) and **Idempotency** (ignoring redundant signals).

## State Management
A global Finite State Machine (FSM) tracks trigger timing to ensure that programmatically generated copy events (feedback from AHK) do not cause cascading UI lookups.

| Parameter | Type | Purpose |
| :--- | :--- | :--- |
| `gd_trigger_lock_duration` | `float` | Duration to ignore subsequent trigger calls (sec) |
| `copy_osd_cooldown` | `float` | Suppression window for duplicate OSD messages (sec) |
| `gd_trigger_method` | `enum` | Selection between `powershell` and `python` engines |

## Component Breakdown

### 1. The Trigger Abstraction Layer
The `set_clipboard` function acts as the gateway. It handles three distinct operational modes:
- **`none`**: Standard clipboard persistence only.
- **`side`**: Activates the GoldenDict Popup (Scan mode).
- **`main`**: Activates the GoldenDict Main window.

### 2. Multi-Engine VK Injection
The engine translates human-readable hotkeys (e.g., `Ctrl+Alt+Shift+Q`) into raw Virtual Key (VK) codes. 
- **Python Engine**: Uses `ctypes.windll.user32.keybd_event`. 
- **PowerShell Engine**: Uses `Add-Type` to define a P/Invoke signature for `keybd_event`.

### 3. Synchronization Buffering
To eliminate "empty search" errors, the Python engine utilizes configurable delays:
- `python_trigger_delay_popup` (default 0.1s)
- `python_trigger_delay_main` (default 0.5s)

## Sequence Diagram
1. User presses `Alt+C` (Main Lookup).
2. MPV updates clipboard and sets `FSM.LAST_TRIGGER_TIME`.
3. MPV fires the Python trigger after `0.5s` delay.
4. GoldenDict activates.
5. AHK sends `^c` back to MPV to ensure sync.
6. MPV receives `^c`, but the `gd_trigger_lock_duration` blocks a second trigger.

### 4. Asynchronous Bridge
- **Decision**: Execute the PowerShell notification process asynchronously via `mp.command_native_async`.
- **Rationale**: Prevents any UI lag or playback stutter during the OS-level key injection.

## Risks / Trade-offs

- **[Risk] Shell Overhead** → **Mitigation**: Asynchronous execution ensures the overhead doesn't impact the player's main thread.
- **[Risk] Type Compilation Delay** → **Mitigation**: Using a unique class name per call ensures session safety, while the 10ms micro-buffer ensures OS-level modifier stability.
