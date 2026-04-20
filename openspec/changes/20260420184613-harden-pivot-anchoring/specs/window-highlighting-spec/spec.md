## MODIFIED Requirements

### Phase 2: Local Fuzzy Match (Green)
- **Condition**: Contextually grounded but fails Sequential Adjacency; term exists as a single word or partial sequence on the current line.
- **Visual**: **Green (#00FF00)**.
- **Goal**: Highlight single-word cards or slightly modified phrase matches on the origin line.

#### Scenario: Rendering Local Fuzzy Match in Green
- **GIVEN** a saved multi-word phrase: "Netto Globus"
- **AND** a subtitle line contains "Netto" but "Globus" is on the NEXT line.
- **THEN** both words SHALL be highlighted in **Purple**.
- **GIVEN** the same phrase, but both words are on the SAME line with an extra word between them.
- **THEN** both words SHALL be highlighted in **Green**.
