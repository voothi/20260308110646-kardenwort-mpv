"""
Feature ZID: 20260522163656
Test Creation ZID: 20260522163656
Feature: Tag Walk Regression Coverage v1.82.24..v1.82.26

Structural guardrails for regressions that are hard to execute in headless CI:
- Copy Mode B fallback to cached tooltip secondary subtitles.
- Copy mode cycle lock when no true secondary source exists.
- DW interactive key guards that bypass native subtitle visibility only when DW is ON.
"""
from pathlib import Path
import re

def assert_contains(haystack, needle, msg=None):
    def norm(s):
        return re.sub(r"[\s\n\r\t\"']+", "", s)
    assert norm(needle) in norm(haystack), msg or f"Expected {repr(needle)} to be in text, but not found."


def _lua_source() -> str:
    import os
    contents = []
    base_dir = "scripts/kardenwort"
    for filename in sorted(os.listdir(base_dir)):
        if filename.endswith(".lua") and filename not in ("main.lua", "test_hooks.lua"):
            with open(os.path.join(base_dir, filename), encoding="utf-8") as f:
                contents.append(f.read())
    with open(os.path.join(base_dir, "main.lua"), encoding="utf-8") as f:
        contents.append(f.read())
    with open(os.path.join(base_dir, "test_hooks.lua"), encoding="utf-8") as f:
        contents.append(f.read())
    return "\n".join(contents)


def _text_utils_source() -> str:
    return Path("scripts/kardenwort/text_utils.lua").read_text(encoding="utf-8")


def _osd_cards_source() -> str:
    return Path("scripts/kardenwort/osd_cards.lua").read_text(encoding="utf-8")


def _tsv_export_source() -> str:
    return Path("scripts/kardenwort/tsv_export.lua").read_text(encoding="utf-8")


def _search_source() -> str:
    return Path("scripts/kardenwort/search.lua").read_text(encoding="utf-8")


def _function_window(src: str, name: str, next_hint: str, span: int = 5000) -> str:
    start = src.find(name)
    assert start != -1, f"{name} not found"
    end = src.find(next_hint, start)
    if end == -1:
        end = start + span
    return src[start:end]

def _slice_from(src: str, marker: str, span: int = 1600) -> str:
    start = src.find(marker)
    assert start != -1, f"{marker} not found"
    return src[start:start + span]


def test_cycle_copy_mode_requires_real_secondary_or_cached_secondary():
    src = _lua_source()
    body = _function_window(src, "function cmd_cycle_copy_mode()", "function cmd_toggle_copy_ctx")

    assert_contains(body, "local has_sec =")
    assert_contains(body, "Tracks.sec.id ~= 0")
    assert_contains(body, "FSM.DW_TOOLTIP_SEC_SUBS")
    assert_contains(body, "if not has_sec then")
    assert_contains(body, "Copy Mode: Fixed to Primary (Single Track)")


def test_copy_context_falls_back_to_cached_secondary_subs_when_track_missing():
    src = _tsv_export_source()
    body = _function_window(src, "local function get_copy_context_text", "local function load_anki_mapping_ini")

    assert_contains(body, "local function append(path, is_ass, explicit_idx, provided_subs)")
    assert_contains(body, "if not path and not provided_subs then return end")
    assert_contains(body, "local subs = provided_subs")
    assert_contains(body, "elseif FSM.DW_TOOLTIP_SEC_SUBS and #FSM.DW_TOOLTIP_SEC_SUBS > 0 then")
    assert_contains(body, "append(nil, false, nil, FSM.DW_TOOLTIP_SEC_SUBS)")


def test_prepare_export_text_mode_b_falls_back_to_cached_secondary_subs():
    src = _tsv_export_source()
    body = _function_window(src, "local function prepare_export_text(params, options)", "local function extract_anki_context")

    assert_contains(body, 'if options.copy_mode == "B" then')
    assert_contains(body, "if Tracks.sec.subs and #Tracks.sec.subs > 0 then")
    assert_contains(body, "elseif FSM.DW_TOOLTIP_SEC_SUBS and #FSM.DW_TOOLTIP_SEC_SUBS > 0 then")
    assert_contains(body, "target_subs = FSM.DW_TOOLTIP_SEC_SUBS")


def test_visibility_guards_allow_dw_interaction_when_dw_window_on():
    src = _lua_source()
    search_src = _search_source()

    guards = [
        "local function cmd_dw_tooltip_pin(tbl)",
        "local function cmd_toggle_dw_tooltip_hover()",
        "local function cmd_dw_tooltip_toggle()",
        "local function cmd_dw_add_smart()",
        "local function cmd_dw_toggle_pink(tbl, was_mouse)",
        "local function cmd_toggle_anki_global()",
        "local function cmd_toggle_drum()",
        "function M.cmd_toggle_search()",
    ]

    for fn in guards:
        # cmd_toggle_search moved to search.lua (Phase 8); read from there.
        lookup_src = search_src if fn == "function M.cmd_toggle_search()" else src
        body = _slice_from(lookup_src, fn, span=1300)
        assert_contains(body, 'if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then', (
            f"Expected DW visibility bypass guard in {fn}"
        ))


def test_tick_dw_follow_mode_keeps_viewport_centered_outside_book_mode():
    src = _lua_source()
    body = _function_window(src, "local function tick_dw(time_pos, active_idx)", "local function tick_drum")

    assert_contains(body, "if FSM.DW_FOLLOW_PLAYER then")
    assert_contains(body, "elseif not FSM.BOOK_MODE then")
    assert_contains(body, "FSM.DW_VIEW_CENTER = active_idx")


def test_dw_open_without_pointer_anchors_to_active_playback_line():
    src = _lua_source()
    body = _function_window(src, "function cmd_toggle_drum_window()", "function toggle_book_mode()", span=9000)

    assert_contains(body, "local has_pointer =")
    assert_contains(body, "local has_range =")
    assert_contains(body, "local has_pending =")
    assert_contains(body, "if has_pointer or has_range or has_pending then")
    assert_contains(body, "FSM.DW_CURSOR_LINE = active_idx")
    assert_contains(body, "FSM.DW_VIEW_CENTER = (FSM.DW_CURSOR_LINE and FSM.DW_CURSOR_LINE ~= -1) and FSM.DW_CURSOR_LINE or active_idx")


def test_dw_block_top_uses_stable_frame_when_not_overflowing():
    src = _lua_source()
    body = _function_window(src, "local function dw_calculate_block_top(view_center, active_idx, layout, total_height)", "-- draw_dw")

    assert_contains(body, "local block_top = center_y - (total_height / 2)")
    assert_contains(body, "if total_height > base_h - 2 * edge_margin then")
    assert_contains(body, "block_top = center_y - offset_y")


def test_dw_mouse_drag_starts_only_after_movement_threshold():
    src = _lua_source()
    update_body = _function_window(src, "local function dw_mouse_update_selection()", "local function dw_mouse_auto_scroll")
    auto_scroll_body = _function_window(src, "local function dw_mouse_auto_scroll()", "local function cmd_dw_tooltip_pin")
    handler_body = _function_window(src, "local function make_mouse_handler(is_shift, on_up_callback, on_down_callback, updates_selection)", "local cmd_dw_mouse_select")

    assert_contains(update_body, "if not FSM.DW_MOUSE_PENDING_DRAG then return end")
    assert_contains(update_body, "dw_pointer_exceeded_drag_threshold(osd_x, osd_y)")
    assert_contains(update_body, "FSM.DW_MOUSE_PENDING_DRAG = false")
    assert_contains(update_body, "FSM.DW_MOUSE_DRAGGING = true")
    assert_contains(update_body, "dw_sync_cursor_to_mouse()")

    assert_contains(handler_body, "FSM.DW_MOUSE_PENDING_DRAG = true")
    assert_contains(handler_body, "FSM.DW_MOUSE_DRAGGING = false")
    assert_contains(handler_body, "FSM.DW_MOUSE_SCROLL_TIMER = mp.add_periodic_timer(get_dw_mouse_auto_scroll_interval(), dw_mouse_auto_scroll)")
    assert_contains(handler_body, "if dw_pointer_exceeded_drag_threshold(osd_x, osd_y) and updates_selection then")

    assert_contains(auto_scroll_body, "dw_mouse_update_selection()")
    assert_contains(auto_scroll_body, "if not FSM.DW_MOUSE_DRAGGING then return end")


def test_dw_binding_builder_never_registers_nil_mouse_callback():
    src = _lua_source()
    body = _function_window(src, "manage_dw_bindings = function(enable_mouse, enable_kb)", "-- =========================================================================")

    assert_contains(body, "if type(mouse_fn) == \"function\" and MOUSE_HANDLERS[mouse_fn] then")
    assert_contains(body, "m_fn = mouse_fn")
    assert_contains(body, "elseif key_fn then")
    assert_contains(body, "if t and t.event == \"up\" then key_fn(t, true) end")
    assert_contains(body, "and type(k.fn) == \"function\"")


def test_rmb_tooltip_pin_uses_direct_handler_for_hold_drag_through():
    src = _lua_source()
    body = _function_window(src, "local MOUSE_HANDLERS = {}", "local function dw_anki_export_smart_callback")
    bindings = _function_window(src, "manage_dw_bindings = function(enable_mouse, enable_kb)", "-- =========================================================================")

    assert_contains(body, "MOUSE_HANDLERS[cmd_dw_tooltip_pin] = true")
    assert_contains(bindings, "{opt = \"dw_key_tooltip_pin\",          name = \"dw-tooltip-pin\",          mouse_fn = cmd_dw_tooltip_pin")
    assert_contains(bindings, "if type(mouse_fn) == \"function\" and MOUSE_HANDLERS[mouse_fn] then")
    assert_contains(bindings, "m_fn = mouse_fn")


def test_rmb_tooltip_pin_enters_holding_before_line_hit_resolution():
    src = _lua_source()
    body = _function_window(src, "local function cmd_dw_tooltip_pin(tbl)", "local function cmd_toggle_dw_tooltip_hover")

    down_idx = body.find('if tbl.event == "down" then')
    hold_idx = body.find("FSM.DW_TOOLTIP_HOLDING = true")
    resolve_idx = body.find("resolve_tooltip_target_line(subs, osd_x, osd_y, dw_mode)")
    up_idx = body.find('elseif tbl.event == "up" then')
    release_idx = body.find("FSM.DW_TOOLTIP_HOLDING = false")

    assert -1 not in (down_idx, hold_idx, resolve_idx, up_idx, release_idx)
    assert down_idx < hold_idx < resolve_idx
    assert up_idx < release_idx


def test_dw_mouse_drag_and_scroll_tuning_are_option_driven():
    src = _lua_source()
    opts = _function_window(src, "Options = {", "options.read_options(Options, \"kardenwort\")", span=12000)
    update_body = _function_window(src, "local function dw_mouse_update_selection()", "local function dw_mouse_auto_scroll")
    handler_body = _function_window(src, "local function make_mouse_handler(is_shift, on_up_callback, on_down_callback, updates_selection)", "local cmd_dw_mouse_select")

    assert_contains(opts, "dw_mouse_drag_threshold_px = 5")
    assert_contains(opts, "dw_mouse_auto_scroll_interval = 0.05")
    assert_contains(opts, "dw_mouse_edge_scroll_ratio = 0.15")
    assert "local drag_threshold_px = 5" not in update_body
    assert "if (dx > 5 or dy > 5) and updates_selection then" not in handler_body
    assert "mp.add_periodic_timer(0.05, dw_mouse_auto_scroll)" not in handler_body


def test_dw_mouse_auto_scroll_uses_base_height_instead_of_hardcoded_1080():
    src = _lua_source()
    auto_scroll_body = _function_window(src, "local function dw_mouse_auto_scroll()", "local function cmd_dw_tooltip_pin")

    assert_contains(auto_scroll_body, "Options.font_base_height or 1080")
    assert_contains(auto_scroll_body, "local edge_ratio = tonumber(Options.dw_mouse_edge_scroll_ratio) or 0.15")
    assert_contains(auto_scroll_body, "local edge_zone = base_h * edge_ratio")
    assert_contains(auto_scroll_body, "local bottom_scroll_trigger = base_h - edge_zone")
    assert_contains(auto_scroll_body, "elseif osd_y > (bottom_scroll_trigger + edge_activation_pad) then")


def test_dw_mouse_auto_scroll_keeps_edge_triggers_reachable_when_block_overflows():
    src = _lua_source()
    auto_scroll_body = _function_window(src, "local function dw_mouse_auto_scroll()", "local function cmd_dw_tooltip_pin")

    pad_idx = auto_scroll_body.find("local edge_activation_pad = math.max(2, math.floor(get_dw_drag_threshold_px() / 2))")
    overflow_idx = auto_scroll_body.find("local dw_overflows_top = first_zone.y_top and first_zone.y_top <= edge_activation_pad")
    assert -1 not in (pad_idx, overflow_idx)
    assert pad_idx < overflow_idx
    assert_contains(auto_scroll_body, "local dw_overflows_top = first_zone.y_top and first_zone.y_top <= edge_activation_pad")
    assert_contains(auto_scroll_body, "local dw_overflows_bottom = last_zone.y_bottom and last_zone.y_bottom >= (base_h - edge_activation_pad)")
    assert_contains(auto_scroll_body, "if dw_overflows_top then")
    assert_contains(auto_scroll_body, "top_scroll_trigger = edge_zone")
    assert_contains(auto_scroll_body, "if dw_overflows_bottom then")
    assert_contains(auto_scroll_body, "bottom_scroll_trigger = base_h - edge_zone")


def test_dw_mouse_auto_scroll_helper_stays_non_local_for_lua_limit():
    src = _lua_source()
    assert "function dw_get_auto_scroll_block_zones(" in src
    assert "local function dw_get_auto_scroll_block_zones(" not in src


# ---------------------------------------------------------------------------
# v1.82.26..v1.84.0 review (ZID 20260523121327): add semantic guardrails
# beyond the existing structural string-matching tests so a future regression
# in geometry/binding logic cannot silently slip through.
# ---------------------------------------------------------------------------


def test_dw_calculate_block_top_overflow_branch_uses_edge_margin_not_hardcoded_y():
    """The block-top math must derive screen geometry from Options
    (no hardcoded 540, no hardcoded 1080) so users can re-target the
    safe-area, and the function must clamp using dw_edge_margin."""
    src = _lua_source()
    body = _function_window(
        src,
        "local function dw_calculate_block_top(view_center, active_idx, layout, total_height)",
        "-- draw_dw",
    )

    # Geometry must come from Options.
    assert "Options.font_base_height or 1080" in body
    assert "Options.dw_edge_margin or 0" in body

    # The non-overflow branch must keep a stable, centered frame (no
    # focused-line anchoring) - this is the legacy DW behavior restored
    # at ZID 20260522230925.
    assert "local block_top = center_y - (total_height / 2)" in body

    # Overflow branch must clamp against dw_edge_margin (top and bottom),
    # not against zero - this is the v1.84.0 safe-area behavior.
    assert "if total_height > base_h - 2 * edge_margin then" in body
    assert "block_top = edge_margin" in body
    assert "block_top = base_h - edge_margin - total_height" in body


def test_dw_block_top_and_total_height_are_exposed_for_diagnostics():
    """Test harness needs to read the post-render DW geometry; the FSM
    must publish it after every successful draw_dw call so
    test_20260521133435_dw_top_alignment.py acceptance asserts work."""
    src = _lua_source()
    draw_body = _function_window(src, "local function draw_dw(subs, view_center, active_idx)", "local function draw_dw_tooltip")

    assert "FSM.DW_BLOCK_TOP = block_top" in draw_body
    assert "FSM.DW_TOTAL_HEIGHT = total_height" in draw_body

    probe_body = _function_window(src, "function kardenwortProbe._snapshot()", "kardenwortProbe.tests = {}", span=4000)
    assert_contains(probe_body, "dw_block_top")
    assert_contains(probe_body, "dw_total_height")


def test_mp_callback_safety_shim_logs_invalid_callbacks_via_msg_error():
    """The global mp.* shim must surface programming errors via msg.error
    (not silently swallow them); otherwise nil-callback regressions get
    hidden and recur. Coupling note: shim wraps mp APIs before any
    auxiliary module is required."""
    src = _lua_source()
    shim = src[: src.find("require 'resume'")]

    assert_contains(shim, "local function validate_callback(kind, name, fn)")
    assert_contains(shim, "if type(fn) == \"function\" then return true end")
    assert_contains(shim, "msg.error(string.format(\"[kardenwort] Skipping invalid %s '%s': callback is %s\",")

    for api in (
        "mp.add_key_binding",
        "mp.add_forced_key_binding",
        "mp.add_timeout",
        "mp.add_periodic_timer",
        "mp.register_event",
        "mp.observe_property",
        "mp.register_script_message",
    ):
        assert_contains(shim, f"{api} = function", f"shim must wrap {api}")
        # Each wrapper must call validate_callback before delegating.
        wrap = shim[shim.find(f"{api} = function"):]
        wrap = wrap[: wrap.find("end\n")]
        assert_contains(wrap, "validate_callback(", f"{api} wrapper must validate first")


def test_dw_binding_loop_has_no_empty_event_down_block():
    """The wrapped_fn at the binding-registration loop must not contain
    an empty `if t.event == \"down\" then end` placeholder.

    Why: the empty block was leftover after removing inline shield logic,
    and it now masks intent (no-op branch reads like a TODO). A future
    contributor might add code here without realizing nav() already
    sets the shield timestamp for the keys that need it."""
    src = _lua_source()
    body = _function_window(src, "manage_dw_bindings = function(enable_mouse, enable_kb)", "-- =========================================================================")

    # Normalize whitespace inside the wrapped_fn block.
    wrapped_fn_idx = body.find("local wrapped_fn = function(t)")
    assert wrapped_fn_idx != -1
    wrapped_fn_block = body[wrapped_fn_idx: wrapped_fn_idx + 400]

    # Empty branch should not be present.
    assert "if t and t.event == \"down\" then\n\n                    end" not in wrapped_fn_block
    # Functional contract must still hold: the inner call delegates to k.fn(t).
    assert_contains(wrapped_fn_block, "return k.fn(t)")


def test_dw_mouse_edge_scroll_ratio_clamp_uses_named_constant():
    """The 0.49 upper bound on dw_mouse_edge_scroll_ratio is a magic
    number - it should be a named constant so the intent (\"never let
    top+bottom edge zones cover the entire screen\") is documented."""
    src = _lua_source()
    auto_scroll_body = _function_window(src, "local function dw_mouse_auto_scroll()", "local function cmd_dw_tooltip_pin")

    # After refactor the literal must be replaced with a named local.
    assert_contains(auto_scroll_body, "DW_EDGE_SCROLL_RATIO_MAX")
    assert_contains(auto_scroll_body, "if edge_ratio > DW_EDGE_SCROLL_RATIO_MAX then")
    assert_contains(auto_scroll_body, "edge_ratio = DW_EDGE_SCROLL_RATIO_MAX")


def test_dw_vline_height_helper_replaces_duplicate_formula():
    """`(Options.dw_font_size * wrap_mul) + Options.dw_vsp` was duplicated
    in 3 places (dw_build_layout, draw_dw, ensure_sub_layout). Consolidate
    behind a helper so a future change to wrapped-line spacing is local."""
    src = _lua_source()

    # The helper must exist and use the wrap_line_height_mul fallback chain.
    assert_contains(src, "function dw_vline_height()")
    helper = _function_window(src, "function dw_vline_height()", "\nfunction ", span=400)
    assert_contains(helper, "Options.dw_wrap_line_height_mul or Options.dw_line_height_mul")
    assert_contains(helper, "Options.dw_vsp")

    # Call sites must use the helper instead of repeating the formula.
    build_layout = _function_window(src, "local function dw_build_layout(subs, view_center)", "local function dw_calculate_block_top")
    ensure = _function_window(src, "local function ensure_sub_layout(sub)", "local function get_word_boundary", span=4000)

    for body in (build_layout, ensure):
        assert_contains(body, "dw_vline_height()")
        assert "(Options.dw_font_size * wrap_mul) + Options.dw_vsp" not in body


def test_dw_hit_test_fallback_uses_horizontal_and_vertical_distance():
    """The previous fallback in dw_hit_test had a copy-paste bug:
    `dist = math.abs(z.y_top - best_zone.y_top)` was invariant across all
    words inside a single zone, so the loop returned the LAST word of the
    vertically-closest zone instead of the horizontally-closest one.

    Why: when a visual line has only spacer/punctuation tokens (rare but
    possible with custom token sets) the click should snap to the nearest
    selectable word in the same subtitle - by vertical proximity first,
    then by horizontal cursor distance.

    The fix lives in `dw_resolve_neighbor_word`; behavior is exercised by
    tests/unit/test_dw_pure_logic.py via a Python port of the algorithm."""
    src = _lua_source()
    hit_test = _function_window(src, "local function dw_hit_test(osd_x, osd_y)", "local function dw_tooltip_hit_test")

    # The buggy line must be gone.
    assert "math.abs(z.y_top - best_zone.y_top)" not in hit_test

    # The fallback must call the named helper with the right inputs.
    assert_contains(hit_test, "dw_resolve_neighbor_word(")
    assert_contains(hit_test, "FSM.DW_HIT_ZONES")
    assert_contains(hit_test, "best_zone.sub_idx")
    assert_contains(hit_test, "best_zone.y_top")
    assert_contains(hit_test, "osd_x")

    # The helper itself must compute BOTH a vertical zone-pick and a
    # horizontal in-zone pick (the two-stage algorithm).
    helper = _function_window(src, "function dw_resolve_neighbor_word(zones, target_sub_idx, ref_y_top, osd_x)", "\nlocal function ", span=2000)
    assert_contains(helper, "best_dy", "must track vertical distance to pick the nearest zone")
    assert_contains(helper, "best_dx", "must track horizontal distance to pick the nearest word")
    assert_contains(helper, "word.x_offset", "must use word geometry for in-zone pick")
    assert_contains(helper, "word.width", "must use word geometry for in-zone pick")


def test_manage_dw_bindings_is_table_driven():
    """The 30+ repetitive `parse_and_collect(...)` lines have been replaced
    by a single binding schema iterated once. New keys should be added to
    the schema, not as ad-hoc procedure calls."""
    src = _lua_source()
    body = _function_window(src, "manage_dw_bindings = function(enable_mouse, enable_kb)", "-- =========================================================================")

    # Single schema table with named fields.
    assert_contains(body, "local binding_defs = {")
    for required_field in ("opt =", "name =", "key_fn ="):
        assert_contains(body, required_field, f"binding schema must use field {required_field}")

    # Single iteration replaces the repetitive calls.
    assert_contains(body, "for _, d in ipairs(binding_defs) do")
    assert_contains(body, "parse_and_collect(")

    # No more than one direct parse_and_collect call in the function body
    # (plus the local function definition). Counting from the body slice:
    assert body.count("parse_and_collect(") == 2
    # And no remaining lines of the old `parse_and_collect(Options.dw_key_..., ` form.
    assert "parse_and_collect(Options.dw_key_add" not in body
    assert "parse_and_collect(Options.dw_key_select" not in body




def test_tooltip_visibility_engages_ui_border_override():
    src = _lua_source()
    helper = _function_window(src, "local apply_tooltip_ass", "local function clear_tooltip_overlay", span=2200)

    assert_contains(helper, "apply_tooltip_ass = function(ass)")
    assert_contains(helper, "local will_visible =")
    assert_contains(helper, "local wants_override = false")
    assert_contains(helper, "local style_ctx = build_tooltip_style_context(get_tooltip_parent_mode())")
    assert_contains(helper, "wants_override = style_ctx.needs_override")
    assert_contains(helper, "local has_override = (FSM.DW_TOOLTIP_BORDER_OVERRIDE == true)")
    assert_contains(helper, "manage_ui_border_override(true)")
    assert_contains(helper, "manage_ui_border_override(false)")
    assert_contains(helper, "FSM.DW_TOOLTIP_BORDER_OVERRIDE = has_override")
    assert_contains(helper, "dw_tooltip_osd.data = ass")

    # All tooltip writes should be routed through the helper.
    assert src.count("dw_tooltip_osd.data =") == 1


def test_manage_ui_border_override_is_forward_declared():
    src = _lua_source()
    head = src[: src.find("local Diagnostic")]
    assert_contains(head, "local manage_ui_border_override")
    assert src.find("local apply_tooltip_ass") < src.find("function manage_ui_border_override(enable)")


def test_show_osd_uses_single_neutralized_card_renderer():
    src = _osd_cards_source()
    body = _function_window(src, "local function show_osd(msg, dur)", "local function setup_seek_osd")

    assert_contains(body, 'Options.seek_bg_color')
    assert_contains(body, 'Options.seek_bg_opacity')
    assert 'mp.osd_message(' not in body
    assert 'FSM.DRUM_WINDOW' not in body
    assert_contains(body, 'local bg_rect = string.format(')
    assert_contains(body, 'local text_event = string.format(')
    assert body.count("{\\\\3a&HFF&}{\\\\4a&HFF&}") >= 2
    assert_contains(body, 'FSM.notice_osd.data = bg_rect .. "\\n" .. text_event')
    assert_contains(body, 'FSM.notice_osd:update()')
    assert_contains(body, 'FSM.notice_timer = mp.add_timeout(duration, function()')
    assert "volume_suspension" not in body


def test_notice_and_seek_cards_neutralize_background_box_on_shape_and_text():
    src = _osd_cards_source()
    show_body = _function_window(src, "local function show_osd(msg, dur)", "local function setup_seek_osd")
    seek_body = _function_window(src, "local function show_seek_osd(msg, alignment)", "function M.setup")

    for name, body in {
        "show_osd": show_body,
        "show_seek_osd": seek_body,
    }.items():
        bg_start = body.find("local bg_rect = string.format(")
        text_start = body.find("local text_event = string.format(")
        assert bg_start != -1, f"{name}: missing vector card background"
        assert text_start != -1, f"{name}: missing text event"

        data_start = body.find("data = bg_rect", text_start)
        assert data_start != -1, f"{name}: missing combined card/text overlay assignment"

        bg_event = body[bg_start:text_start]
        text_event = body[text_start:data_start]
        neutral = "{\\\\3a&HFF&}{\\\\4a&HFF&}"

        assert_contains(bg_event, neutral, f"{name}: vector card must neutralize native background-box")
        assert_contains(text_event, neutral, f"{name}: text line must neutralize native background-box")
        assert_contains(bg_event, "{\\\\p1}", f"{name}: card background must remain a vector ASS shape")
        assert "mp.osd_message(" not in body, f"{name}: native OSD fallback would reintroduce DM/DW hue drift"
        assert "FSM.DRUM_WINDOW" not in body, f"{name}: renderer must not branch between DM and DW"


def test_show_seek_osd_uses_single_compact_card_renderer():
    src = _osd_cards_source()
    body = _function_window(src, "local function show_seek_osd(msg, alignment)", "function M.setup")

    assert_contains(body, 'Options.seek_bg_color')
    assert_contains(body, 'Options.seek_bg_opacity')
    assert 'mp.osd_message(' not in body
    assert 'FSM.DRUM_WINDOW' not in body
    assert_contains(body, 'local bg_rect = string.format(')
    assert_contains(body, 'local text_event = string.format(')
    assert body.count("{\\\\3a&HFF&}{\\\\4a&HFF&}") >= 2
    assert_contains(body, 'seek_osd.data = bg_rect .. "\\n" .. text_event')
    assert_contains(body, 'seek_osd:update()')
    assert_contains(body, 'seek_timer = mp.add_timeout(Options.seek_osd_duration, function()')


def test_notice_and_seek_overlay_layers_are_configurable_and_reloadable():
    src = _lua_source()
    conf = Path("mpv.conf").read_text(encoding="utf-8")

    assert_contains(src, "seek_osd_layer = 5")
    assert_contains(src, "notice_osd_layer = 5")
    assert_contains(src, "FSM.notice_osd.z = Options.notice_osd_layer")
    assert_contains(src, "seek_osd.z = Options.seek_osd_layer")
    assert_contains(src, "script-opts")

    reload_body = _slice_from(src, 'mp.observe_property("script-opts", "string", function()', span=700)
    assert_contains(reload_body, "options.read_options(Options, \"kardenwort\")")
    assert_contains(reload_body, "FSM.notice_osd.z = Options.notice_osd_layer")
    assert_contains(reload_body, "seek_osd.z = Options.seek_osd_layer")

    assert_contains(conf, "script-opts-append=kardenwort-seek_osd_layer=5")
    assert_contains(conf, "script-opts-append=kardenwort-notice_osd_layer=5")


def test_dw_get_str_width_cyrillic_estimate_at_least_052():
    src = _lua_source()
    body = _function_window(src, "local function dw_get_str_width_proportional(str, fs)", "local function calculate_sub_gap")
    assert_contains(body, "elseif #c > 1 then w = w + (fs * 0.52)")
    assert "elseif #c > 1 then w = w + (fs * 0.45)" not in body


def test_tooltip_target_line_resolves_secondary_dm_hits_to_primary_timeline():
    src = _lua_source()
    body = _function_window(src, "local function resolve_tooltip_target_line(subs, osd_x, osd_y, dw_mode)", "local function kardenwort_hit_test_all")

    assert_contains(body, "local line_idx, _, hit_pri = drum_osd_hit_test(osd_x, osd_y)")
    assert_contains(body, "if hit_pri then return line_idx end")
    assert_contains(body, "local sec_subs = (Tracks.sec.subs and #Tracks.sec.subs > 0) and Tracks.sec.subs or FSM.DW_TOOLTIP_SEC_SUBS")
    assert_contains(body, "local midpoint = (sec_sub.start_time + sec_sub.end_time) / 2")
    assert_contains(body, "local pri_idx = get_center_index(subs, midpoint)")


def test_get_tooltip_line_y_falls_back_to_non_primary_zone_when_needed():
    src = _lua_source()
    body = _function_window(src, "local function get_tooltip_line_y(line_idx, fallback_y)", "local function update_font_scale")

    assert_contains(body, "local fallback_zone_y = nil")
    assert_contains(body, "local zone_center_y = (zone.y_top + zone.y_bottom) / 2")
    assert_contains(body, "if zone.is_pri then")
    assert_contains(body, "fallback_zone_y = zone_center_y")
    assert_contains(body, "return fallback_zone_y or fallback_y")


def test_tooltip_click_mode_dismisses_only_on_explicit_different_line():
    src = _lua_source()
    body = _function_window(src, "local function dw_tooltip_mouse_update()", "local function dw_anki_export_selection")

    assert_contains(body, "if dw_mode and line_idx and line_idx ~= FSM.DW_TOOLTIP_LINE then")
    assert "if line_idx ~= FSM.DW_TOOLTIP_LINE then" not in body


def test_tooltip_vertical_clamp_accounts_for_padding():
    src = _lua_source()
    body = _function_window(src, "local function draw_dw_tooltip(subs, target_line_idx, osd_y)", "local function dw_get_mouse_osd")

    assert_contains(body, "local pad_top = pad_y + math.max(0, tonumber(Options.tooltip_top_pad_extra) or 0)")
    assert_contains(body, "local half_h_with_pad = half_h + pad_top")
    assert_contains(body, "local rect_top = block_top - pad_top")
    assert_contains(body, "local rect_h = math.max(1, block_height + (2 * pad_top))")
    assert_contains(body, "local line_center_y = cur_y + (layout_line_h / 2)")
    assert_contains(body, "format_tooltip_text_event(style_ctx, anchor_x, line_center_y, vl.line_text)")
    assert_contains(body, "if final_y - half_h_with_pad < margin then")
    assert_contains(body, "elseif final_y + half_h_with_pad > screen_h - margin then")


def test_dm_tooltip_background_box_mode_uses_single_measured_vector_card():
    src = _lua_source()
    body = _function_window(src, "local function draw_dw_tooltip(subs, target_line_idx, osd_y)", "local function dw_get_mouse_osd")

    assert_contains(body, "local style_ctx = build_tooltip_style_context(get_tooltip_parent_mode())")
    assert_contains(body, "local rect_bg_alpha = style_ctx.card_alpha")
    assert_contains(body, "local bg_rect = format_tooltip_card_event(style_ctx, rect_left, rect_top, rect_w, rect_h, rect_bg_alpha)")
    assert_contains(body, "local line_ass = format_tooltip_text_event(style_ctx, anchor_x, line_center_y, vl.line_text)")
    assert "line_bgbox_neutral" not in body
    assert "{\\\\bord0}{\\\\shad0}" not in body


def test_tooltip_native_box_policy_option_is_declared_with_auto_default():
    src = _lua_source()
    opts = _function_window(src, "Options = {", "options.read_options(Options, \"kardenwort\")", span=18000)
    assert_contains(opts, 'tooltip_native_box_policy = "auto"')
    assert_contains(opts, 'tooltip_bg_alpha = ""')
    assert_contains(opts, 'tooltip_dw_bg_alpha = ""')
    assert_contains(opts, 'tooltip_dm_bg_alpha = "FF"')
    assert_contains(opts, 'tooltip_srt_bg_alpha = "FF"')
    assert "tooltip_dw_bg_opacity" not in opts
    assert "tooltip_dm_bg_opacity" not in opts
    assert "tooltip_srt_bg_opacity" not in opts


def test_tooltip_style_context_supports_auto_neutralize_and_override_modes():
    src = _lua_source()
    body = _function_window(src, "function normalize_tooltip_native_box_policy()", "apply_tooltip_ass = function(ass)", span=5000)
    assert_contains(body, 'policy ~= "auto" and policy ~= "neutralize" and policy ~= "override"')
    assert_contains(body, 'return "srt"')
    assert_contains(body, 'if policy == "override" then')
    assert_contains(body, 'elseif policy == "neutralize" then')
    assert_contains(body, "neutralize_inband = style_is_bgbox")
    assert_contains(body, 'if parent_mode == "dw" then')
    assert_contains(body, 'elseif style_is_bgbox then')
    assert_contains(body, "neutralize_inband = true")
    assert_contains(body, 'if needs_override then')
    assert_contains(body, "neutralize_inband = false")
    assert_contains(body, "local base_alpha = Options.tooltip_bg_alpha")
    assert_contains(body, "base_alpha = Options.tooltip_bg_opacity")
    assert_contains(body, 'if parent_mode == "dw" then')
    assert_contains(body, "Options.tooltip_dw_bg_alpha")
    assert_contains(body, 'elseif parent_mode == "dm" then')
    assert_contains(body, "Options.tooltip_dm_bg_alpha")
    assert_contains(body, 'elseif parent_mode == "srt" then')
    assert_contains(body, "Options.tooltip_srt_bg_alpha")
    assert "Options.tooltip_dw_bg_opacity" not in body
    assert "Options.tooltip_dm_bg_opacity" not in body
    assert "Options.tooltip_srt_bg_opacity" not in body
    assert_contains(body, "card_alpha = calculate_ass_alpha(card_alpha)")


def test_dm_tooltip_auto_policy_preserves_parent_background_box_frame():
    src = _lua_source()
    body = _function_window(src, "function build_tooltip_style_context(parent_mode)", "apply_tooltip_ass = function(ass)", span=3500)

    dw_override = body.find('if parent_mode == "dw" then')
    dm_neutralize = body.find('elseif style_is_bgbox then', dw_override)
    assert dw_override != -1
    assert dm_neutralize != -1
    assert_contains(body[dm_neutralize:], "neutralize_inband = true")


def test_tooltip_text_event_neutralization_is_emitted_after_shadow_tags():
    src = _lua_source()
    body = _function_window(src, "function format_tooltip_text_event(style_ctx, anchor_x, line_center_y, line_text)", "local function draw_dw_tooltip", span=2000)
    assert_contains(body, 'local neutralize_bgbox = style_ctx.neutralize_inband and "{\\\\3a&HFF&}{\\\\4a&HFF&}" or ""')
    # Regression guard: neutralization token is concatenated after the line-level 3a/4a style tags.
    assert_contains(body, '{\\\\3a&H%s&}{\\\\4a&H%s&}{\\\\q2}%s%s')


def test_dm_tooltip_sticky_guards_avoid_transient_clear():
    src = _lua_source()
    body = _function_window(src, "local function dw_tooltip_mouse_update()", "local function dw_anki_export_selection")

    assert_contains(body, "if dw_mode then")
    assert_contains(body, "clear_tooltip_overlay(\"forced-target-missing\")")
    assert_contains(body, "clear_tooltip_overlay(\"target-y-missing\")")
    assert_contains(body, "clear_tooltip_overlay(\"hover-gap\")")


def test_flush_rendering_caches_does_not_blank_forced_tooltip():
    src = _lua_source()
    body = _function_window(src, "local function flush_rendering_caches()", "local function invalidate_dw_tooltip_cache")

    assert_contains(body, "if not FSM.DW_TOOLTIP_FORCE then")
    assert_contains(body, "apply_tooltip_ass(\"\")")


def test_tooltip_update_ignores_transient_empty_render_in_dm_mode():
    src = _lua_source()
    body = _function_window(src, "local function dw_tooltip_mouse_update()", "local function dw_anki_export_selection")

    assert_contains(body, "if new_ass ~= \"\" then")
    assert_contains(body, "clear_tooltip_overlay(\"forced-render-empty\")")
    assert_contains(body, "clear_tooltip_overlay(\"hover-render-empty\")")


def test_tooltip_activation_paths_only_publish_non_empty_ass():
    src = _lua_source()
    pin_body = _function_window(src, "local function cmd_dw_tooltip_pin(tbl)", "local function cmd_toggle_dw_tooltip_hover")
    toggle_body = _function_window(src, "local function cmd_dw_tooltip_toggle()", "local function dw_tooltip_mouse_update")

    assert_contains(pin_body, "if ass ~= \"\" then")
    assert_contains(toggle_body, "if ass ~= \"\" then")


def test_normalize_inline_break_markers_helper_definition_and_substitutions():
    src = _text_utils_source()
    body = _function_window(src, "local function normalize_inline_break_markers(text)", "local function get_sub_tokens", span=2000)

    assert_contains(body, '{ pat = "\\\\+N", repl = "\\n", tag = "\\\\N" }')
    assert_contains(body, '{ pat = "\\\\+n", repl = "\\n", tag = "\\\\n" }')
    assert_contains(body, '{ pat = "\\\\+h", repl = " ", tag = "\\\\h" }')
    assert_contains(body, 'text = text:gsub(rule.pat, rule.repl)')
    assert_contains(body, 'text = text:gsub("[ \\t]*\\n[ \\t]*", "\\n")')
    assert_contains(body, "if not text or text == \"\" then return text or \"\" end")


def test_anki_context_extraction_normalizes_inline_break_markers():
    src = _lua_source()

    point_ctx = _function_window(
        src,
        'params = { type = "POINT", line = cl, word = cw }',
        "if pivot_pos == -1 then pivot_pos = char_offset / 2 end",
        span=2000,
    )
    assert_contains(point_ctx, 'normalize_inline_break_markers(subs[k].text):gsub("{[^}]+}", "")')

    set_ctx = _function_window(
        src,
        '-- Requirement: Unified Paired Export',
        "local context_line = table.concat(ctx_parts",
        span=3000,
    )
    assert_contains(set_ctx, 'normalize_inline_break_markers(subs[k].text):gsub("{[^}]+}", "")')


def test_search_in_dm_mode_does_not_take_global_border_override():
    src = _lua_source()
    search_src = _search_source()
    fsm = _function_window(src, "FSM = {", "-- =========================================================================", span=8000)
    draw_body = _function_window(search_src, "local function draw_search_ui()", "local function move_search_cursor", span=9000)
    bindings_body = _function_window(search_src, "local function manage_search_bindings(enable)", "function M.cmd_toggle_search", span=9000)

    assert_contains(fsm, "SEARCH_BORDER_OVERRIDE = false")
    assert_contains(bindings_body, 'FSM.SEARCH_BORDER_OVERRIDE = (FSM.DRUM_WINDOW ~= "OFF")')
    assert_contains(bindings_body, "if FSM.SEARCH_BORDER_OVERRIDE then")
    assert_contains(bindings_body, "manage_ui_border_override(true)")
    assert_contains(bindings_body, "manage_ui_border_override(false)")
    assert_contains(bindings_body, "FSM.SEARCH_BORDER_OVERRIDE = false")

    assert_contains(draw_body, 'local text_bgbox_neutral = (FSM.osd_border_style == "background-box" and not FSM.SEARCH_BORDER_OVERRIDE)')
    assert_contains(draw_body, '"{\\\\3a&HFF&}{\\\\4a&HFF&}"')
    assert draw_body.count("text_bgbox_neutral") >= 4


def test_console_and_osd_frame_suspension_in_dw_mode():
    src = _lua_source()
    
    # 1. Assert console visibility observer exists
    assert_contains(src, 'mp.observe_property("user-data/mpv/console/open", "bool"')
    assert_contains(src, 'FSM.console_active = val')
    
    # 2. Assert apply_border_override_state supports console active flag
    apply_body = _function_window(src, "function apply_border_override_state()", "function manage_ui_border_override")
    assert_contains(apply_body, "FSM.console_active")
    assert "FSM.seek_osd_active" not in apply_body
    assert "FSM.notice_osd_active" not in apply_body

    # 3. Assert show_osd has no notice_osd_active dynamic suspension flags (to protect DW card frame rendering stability)
    show_osd_body = _function_window(_osd_cards_source(), "local function show_osd(msg, dur)", "local function setup_seek_osd")
    assert "FSM.notice_osd_active = true" not in show_osd_body
    assert "FSM.notice_osd_active = false" not in show_osd_body

    # 4. Assert show_seek_osd has no seek_osd_active dynamic suspension flags
    seek_osd_body = _function_window(_osd_cards_source(), "local function show_seek_osd(msg, alignment)", "function M.setup")
    assert "FSM.seek_osd_active = true" not in seek_osd_body
    assert "FSM.seek_osd_active = false" not in seek_osd_body


def test_calculate_osd_line_meta_includes_punctuation_in_hit_zones():
    """drum-context: Drum Mode Punctuation Selection requirement.

    Task 2.4 removed the `is_word` gate from the hit-zone word-collection loop
    inside calculate_osd_line_meta so that sentence-ending punctuation tokens
    (`.`, `?`, `!`) are included in FSM.DW_HIT_ZONES and become clickable/
    selectable in both Drum Mode and Drum Window, matching the spec scenario.

    Regression guard: re-introducing the guard would silently make punctuation
    untargetable without any other test catching it.
    """
    src = _lua_source()
    body = _function_window(
        src,
        "local function calculate_osd_line_meta",
        "local function dw_build_layout",
        span=4000,
    )

    assert "if t.is_word and t.logical_idx then" not in body, (
        "drum-context: is_word gate must be absent from calculate_osd_line_meta "
        "so punctuation tokens are included in hit-zones"
    )
    assert_contains(body, "if t.logical_idx then", (
        "drum-context: logical_idx-only check must be present so punctuation "
        "tokens with a logical_idx are added to the hit-zone word list"
    ))


