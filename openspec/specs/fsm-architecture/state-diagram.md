# FSM State Architecture Specification
**ZID: 20260506104409**

This document specifies the Finite State Machine (FSM) architecture for the Kardenwort immersion engine. It serves as the "Source of Truth" for the AI agent to verify codebase consistency and behavior.

## 1. Global UI Rendering FSM (Mutual Exclusion)
The system ensures that only one primary rendering engine is active at a time to prevent overlay flickering and coordinate conflicts.

```mermaid
stateDiagram-v2
    [*] --> NATIVE_SRT: Boot
    
    state "Native / Styled SRT" as NATIVE_SRT
    state "Drum Mode (OSD)" as DRUM_MODE
    state "Drum Window (Docked)" as DRUM_WINDOW
    state "Search Overlay" as SEARCH_MODE

    NATIVE_SRT --> DRUM_MODE : Toggle Drum (FSM.DRUM='ON')
    DRUM_MODE --> NATIVE_SRT : Toggle Drum (FSM.DRUM='OFF')
    
    NATIVE_SRT --> DRUM_WINDOW : Toggle DW (FSM.DRUM_WINDOW='DOCKED')
    DRUM_MODE --> DRUM_WINDOW : Toggle DW (Force hide Drum OSD)
    
    DRUM_WINDOW --> NATIVE_SRT : Toggle DW OFF
    
    state RENDERING_ACTIVE {
        DRUM_WINDOW --> SEARCH_MODE : Ctrl+F
        SEARCH_MODE --> DRUM_WINDOW : ESC / Enter
        
        NATIVE_SRT --> SEARCH_MODE : Ctrl+F
        DRUM_MODE --> SEARCH_MODE : Ctrl+F
    }
    
    note right of NATIVE_SRT
        Hides native if custom 
        fonts/borders are active.
    end note
    
    note left of DRUM_WINDOW
        Hijacks Arrow keys and 
        Enter for navigation.
    end note
```

## 2. Immersion Mode FSM (Playback Behavior)
Controls how the playhead interacts with subtitle boundaries.

```mermaid
stateDiagram-v2
    [*] --> PHRASE_MODE : Default
    
    state "Phrase Mode (Padded)" as PHRASE_MODE
    state "Movie Mode (Gapless)" as MOVIE_MODE
    
    PHRASE_MODE --> MOVIE_MODE : Cycle (Shift+O)
    MOVIE_MODE --> PHRASE_MODE : Cycle (Shift+O)
    
    state PHRASE_MODE {
        [*] --> IDLE
        IDLE --> JERK_BACK : Boundary Crossed & Padded
        JERK_BACK --> IDLE : Seek to s_next
    }
    
    state MOVIE_MODE {
        [*] --> SEAMLESS
        SEAMLESS --> HANDOVER : Boundary Reached
        HANDOVER --> SEAMLESS : stop = next.start - pad
    }
```

## 3. Autopause & Spacebar Lifecycle
Manages the "Sticky Hold" and automated halt behavior.

```mermaid
stateDiagram-v2
    [*] --> AP_RUNNING
    
    state "Running (AP:ON)" as AP_RUNNING
    state "Boundary Paused" as AP_PAUSED
    state "Sticky Holding" as AP_HOLDING
    
    AP_RUNNING --> AP_PAUSED : Time >= sub.end + pad
    AP_PAUSED --> AP_RUNNING : Space Tap (Resumed)
    
    AP_RUNNING --> AP_HOLDING : Space Down (Pre-emptive)
    AP_PAUSED --> AP_HOLDING : Space Down
    
    AP_HOLDING --> AP_RUNNING : Space Up (Ghost Shielded)
    
    note right of AP_HOLDING
        FSM.SPACEBAR = 'HOLDING'
        Prevents AP from firing
        even at boundaries.
    end note
```

## 4. Selection & Interactivity FSM (The "Color Tiers")
Specifies the priority of selection types for copy operations.

```mermaid
stateDiagram-v2
    [*] --> NO_SELECTION
    
    state "Yellow Pointer (Hover/Cursor)" as POINTER
    state "Yellow Range (Shift+Drag)" as RANGE
    state "Pink Set (Ctrl+Click)" as PINK_SET
    
    NO_SELECTION --> POINTER : Click / Key Nav
    POINTER --> RANGE : Shift + Nav/Click
    
    ANY_SELECTION --> PINK_SET : Ctrl + Click
    
    PINK_SET --> NO_SELECTION : ESC (Clear Set)
    RANGE --> POINTER : ESC (Clear Range)
    POINTER --> NO_SELECTION : ESC (Clear Pointer)
    
    note right of PINK_SET
        Highest Export Priority.
        Non-contiguous members.
    end note
```

## 5. Media State Matrix (Codec/Track Detection)
Determines capability availability based on loaded media.

| MEDIA_STATE | Capability: Autopause | Capability: Drum/DW | Capability: Search |
| :--- | :--- | :--- | :--- |
| `NO_SUBS` | Disabled | Blocked | Blocked |
| `SINGLE_SRT` | Full | Full | Full |
| `SINGLE_ASS` | Full | Blocked (Native Only) | Full (External Only) |
| `DUAL_SRT` | Synced | Dual-Track View | Combined |
| `DUAL_ASS` | Synced | Blocked (Native Only) | Combined |

---
**Verification Schema:**
1. `FSM.DRUM_WINDOW == 'DOCKED'` MUST suppress `native-sub-visibility`.
2. `FSM.IMMERSION_MODE == 'PHRASE'` MUST trigger `mp.commandv("seek", s_next, "absolute+exact")` when `time-pos` crosses into padded overlap.
3. `FSM.SPACEBAR == 'HOLDING'` MUST bypass `tick_autopause`.
4. `FSM.SEARCH_MODE == true` MUST hijack all character input keys.
