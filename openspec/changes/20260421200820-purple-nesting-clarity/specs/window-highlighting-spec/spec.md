## MODIFIED Requirements

### Requirement: Two-Phase Match Evaluation
The rendering engine SHALL evaluate every word against the database using a tiered integrity model to determine the correct highlight palette.

#### Phase 1: Contiguous Adjacency (Orange)
- **Condition**: Both Sequential Adjacency (exact word sequence) AND Contextual Grounding (Multi-Pivot/Neighborhood) are satisfied.
- **Visual**: **Orange (#FF8800)** with depth-based darkening for stacked orange terms.
- **Goal**: Highlight "Perfect" matches that exist exactly as saved.

#### Phase 2: Split Match (Flat Purple)
- **Condition**: Contextually grounded via high-recall neighborhoods, but words are fragmented and lack strict sequence adjacency.
- **Visual**: **A single flat shade of `anki_split_depth_1` (default `#FF88B0` / pink-purple)**. NO depth-based darkening. All split-match words, regardless of how many terms cover them or their structural relationship, SHALL render in this single flat color.
- **Goal**: Highlight "Cool Path" pair-selected phrases or high-recall single vocabulary words scattered in a segment. Clarity over nesting information.
- **Rationale for flat color**: Depth-based darkening caused adjacent (non-nested) purple groups to incorrectly appear darker at their boundaries, creating ambiguity about which words belong to which group. Minimalism and clarity take precedence.

#### Phase 3: Mixed Orange + Purple
- **Condition**: Both orange and purple criteria are met simultaneously.
- **Visual**: **A single flat shade of `anki_mix_depth_1` (default `#4A4AD3`)**. NO depth-based scaling. The `purple_depth` value SHALL NOT influence the mix color selection.
