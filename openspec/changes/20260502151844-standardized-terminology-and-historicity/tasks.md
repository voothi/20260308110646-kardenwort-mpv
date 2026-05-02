## 1. Core Specification Artifacts

- [x] 1.1 Create the canonical specification directory `openspec/specs/project-terminology-and-historicity/`.
- [x] 1.2 Populate `openspec/specs/project-terminology-and-historicity/spec.md` with the finalized thesaurus, evolutionary ledger, and dual-notation standards.

## 2. Existing Specification Audit

- [x] 2.1 Update `openspec/specs/window-highlighting-spec/spec.md` to enforce Dual-Notation (BGR | RGB) and use canonical terms (Warm/Cool Path).
- [x] 2.2 Update `openspec/specs/search-ui-styling/spec.md` to align with the "Warm Path" (Orange) color requirement.
- [x] 2.3 Update `openspec/specs/osd-uniformity/spec.md` to formalize the White active subtitle standard.

## 3. Core Script Metadata Synchronization

- [x] 3.1 Update the `Options` table comments in `scripts/lls_core.lua` to include Dual-Notation for all color hexes.
- [x] 3.2 Align `lls_core.lua` code comments with the canonical terminology (e.g., replacing "vibrant yellow" references with "Gold").

## 4. Configuration Audit

- [x] 4.1 Update `mpv.conf` comments to use the standardized domain terms.
- [x] 4.2 Verify all script-option color hexes in `mpv.conf` have dual-notation annotations for AI readability.

## 5. Final Validation

- [x] 5.1 Perform a project-wide audit for legacy color mentions ("Yellow", "Blue", "Green") and functional modes ("Reel", "Reading").
- [x] 5.2 Extract and document technical architecture terms (FSM, Master Tick, UPSR, Isotropic Mapping) from the `openspec/specs` folders.
- [x] 5.3 Finalize and archive the change.
