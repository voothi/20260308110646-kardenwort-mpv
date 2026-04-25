# Spec: Platform Detection Logic

## Context
The script must identify the host OS at runtime to select the correct clipboard tool.

## Requirements
- Use `package.config:sub(1,1)` to check for the Windows backslash (`\`).
- If backslash is not found, assume a Unix-like environment.
- In Unix environments, use `uname` to further distinguish between macOS and other systems.
- Store the platform type in a persistent variable (e.g., `PLATFORM`) during script initialization.

## Verification
- Log the detected platform on script startup.
- Verify that Windows 11 is correctly identified as "windows".
- Verify that a macOS or Linux system is correctly branched to the Unix logic.
