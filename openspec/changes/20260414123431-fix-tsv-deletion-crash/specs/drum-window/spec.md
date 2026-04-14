# Spec: Drum Window Resilience

## Requirements

### R1: Empty Source Guard
The Drum Window MUST NOT initialize its UI state if the primary subtitle source is empty or missing. It MUST show a clear OSD notification explaining the missing dependency.

### R2: Force Refresh
Opening the Drum Window MUST trigger a forced synchronous reload of the TSV state to ensure the view represents the current state of the file system.

### R3: Initialization Safety
All UI setup logic MUST be protected to ensure that an invalid layout calculation (e.g. on empty subs) does not crash the script's visual rendering loop.
