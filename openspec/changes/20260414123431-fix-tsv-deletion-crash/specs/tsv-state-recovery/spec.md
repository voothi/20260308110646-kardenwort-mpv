# Spec: TSV State Recovery

## Requirements

### R1: Atomic Presence Checking
The script MUST verify if the TSV file exists on every load request (synchronous startup and periodic).

### R2: State Clearing
If the TSV file is missing, the in-memory highlight state MUST be cleared (`{} `) to prevent displaying stale information from a deleted file.

### R3: Header Robustness
The parsing routine MUST identify the header row dynamically by comparing the first column against the field name bound to `source_word` in the configuration. 

### R4: Parsing Resilience
The parsing loop MUST be isolated to prevent a single malformed line or I/O error from crashing the script's main thread.
