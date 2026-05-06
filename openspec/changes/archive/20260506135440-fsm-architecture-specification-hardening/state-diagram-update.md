## 12. Index Resolution & Padding (Deterministic Sentinel)
Defines the hierarchical logic for mapping the current `time_pos` to a subtitle index, ensuring audible tail protection and preventing Jerk-Back loops.

```mermaid
graph TD
    Start[master_tick / get_center_index] --> Sentinel{In Active Sub Padding?}
    
    Sentinel -- Yes --> Active[Return FSM.ACTIVE_IDX]
    Sentinel -- No --> BinarySearch[Perform Binary Search]
    
    BinarySearch --> Found[Index 'best' resolved]
    
    Found --> Overlap{Next Sub Padded Start begun?}
    
    Overlap -- Yes --> Next[Return best + 1]
    Overlap -- No --> Tail{Time <= best.end_time?}
    
    Tail -- Yes --> Best[Return best]
    Tail -- No --> Gap[Proximity Fallback]
    
    Gap --> BestOrNext[Return best or next based on proximity]

    subgraph Jerk-Back Guard
    Active -- PHRASE Mode --> LoopCheck{JUST_JERKED_TO?}
    LoopCheck -- Yes --> ForceActive[Return JUST_JERKED_TO]
    end
    
    %% Note for Sentinel logic
    Sentinel --- NoteSentinel[Crucial for Autopause: Ensures we stay on sub until audible tail finishes]
    style NoteSentinel fill:#f9f,stroke:#333,stroke-dasharray: 5 5
```
