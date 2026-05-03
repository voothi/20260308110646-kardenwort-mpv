## Proposal: High-Performance Hardened Clipboard Bridge (v1.58.58)

## Problem Statement
The GoldenDict clipboard synchronization bridge suffered from three primary failure modes:
1. **Recursion Loops**: AHK's mandatory `^c` feedback triggered redundant dictionary lookups in MPV (Ghost Windows).
2. **Synchronization Race Conditions**: Dictionary triggers firing before the OS clipboard buffer was fully committed.
3. **Trigger Latency**: Overhead of PowerShell process initialization (~1s).

## Proposed Solution
Implement a **Triple-Tier Decoupled Copy Engine** with a multi-method trigger abstraction:

1. **Decoupled Actions**: 
   - `Standard Copy`: Pure clipboard update (mode `none`).
   - `Popup Lookup`: Copy + Popup hotkey (mode `side`).
   - `Main Lookup`: Copy + Main window hotkey (mode `main`).
2. **Global Trigger Lock**: A time-based recursion block (`gd_trigger_lock_duration`) to ignore AHK-generated `^c` signals.
3. **Multi-Method Trigger Engine**:
   - `PowerShell`: Dependency-free Win32 bridge using `Add-Type`.
   - `Python`: Instantaneous `ctypes` injection with configurable `python_trigger_delay`.
4. **OSD Stabilization**: Configurable `copy_osd_cooldown` to suppress redundant notification flashes.

## Anchor Traceability
- Logic Refinement: 20260503173127, 20260503181916, 20260503182433
- Python Injector: 20260503165247, 20260503170635
- Configurable Delays: 20260503171625, 20260503175957

## Capabilities

### Modified Capabilities
- `unified-clipboard-abstraction`: Enhanced with a high-reliability, layout-agnostic, multi-mode notification engine.

## Impact

- **Affected Code**: `scripts/lls_core.lua`, `mpv.conf`.
- **UX**: Near-instantaneous dictionary popups that are 100% reliable regardless of active keyboard layout, with zero "garbage" characters in the search field.
