## Context

The `populate_token_meta` function is a central service in `lls_core.lua` responsible for determining the color and priority of tokens during rendering. It currently relies on global `Options` (specifically `dw_highlight_color` and `dw_ctrl_select_color`), which prevents the Translation Tooltip from having its own distinct selection aesthetics. With the transition to `Consolas` and high-contrast background boxes, the "yellow" selection can feel overly bright in the secondary tooltip context.

## Goals / Non-Goals

**Goals:**
- Decouple selection highlighting from the global `dw_` namespace.
- Enable independent color calibration for the Translation Tooltip.
- Maintain $O(1)$ rendering performance through efficient parameter passing.

**Non-Goals:**
- Changing the default colors (they will remain identical unless overridden in `mpv.conf`).
- Modifying the core hit-testing logic (only visual representation is affected).

## Decisions

### 1. Parameterized `populate_token_meta`
Instead of internalizing global lookups, `populate_token_meta` will accept `h_color` and `ctrl_color` as arguments.
- **Rationale**: This allows the caller (Drum Window core vs. Tooltip renderer) to decide which palette to use without duplication of logic.
- **Alternative**: Creating a `populate_tooltip_token_meta` function was rejected to avoid logic drift and code duplication.

### 2. Defaulting to `dw_` variants in `Options`
The new `tooltip_` options will default to the existing `dw_` values in the `Options` table.
- **Rationale**: Ensures backward compatibility and zero visual change for users who haven't customized their `mpv.conf`.

## Risks / Trade-offs

- **[Risk] Parameter Pollution** → **Mitigation**: Use optional arguments with logical fallbacks (`or Options.dw_highlight_color`) to keep call sites clean where defaults are sufficient.
- **[Trade-off] Slightly longer function signatures** → **Mitigation**: The architectural benefit of decoupling outweighs the negligible overhead of passing two additional strings.
