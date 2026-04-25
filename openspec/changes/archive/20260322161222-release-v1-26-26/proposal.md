# Proposal: Cross-Platform Clipboard Support (v1.26.26)

## Problem
The suite's clipboard operations (copying/pasting subtitles) were hardcoded to use Windows PowerShell, preventing functionality on macOS, Linux, and Android (Termux). Users on non-Windows platforms could not use core features like Copy Mode or substrate search.

## Proposed Change
Implement a unified clipboard abstraction layer that automatically detects the host operating system and selects the appropriate command-line utility for clipboard interactions.

## Objectives
- Remove the hard dependency on Windows for clipboard operations.
- Support macOS (`pbcopy`/`pbpaste`), Linux (`wl-copy`/`xclip`), and Android/Termux.
- Centralize clipboard logic to simplify maintenance and improve robustness.
- Refactor existing copy/paste functions to use the new abstraction.

## Key Features
- **Platform Detection**: Automated OS identification using `package.config`.
- **Unified Abstraction**: Helper functions `get_clipboard()` and `set_clipboard(text)`.
- **Multi-Utility Support**: Compatible with PowerShell, Wayland, X11, and Termux environments.
- **Clean Refactoring**: Removal of platform-specific escaping from main command functions.
