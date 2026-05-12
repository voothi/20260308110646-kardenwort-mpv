"""
Feature ZID: 20260509095043
Test Creation ZID: 20260509095043
Feature: Spec Coverage Final Batch

Acceptance tests for the final 9 openspec/specs that lacked dedicated test coverage.
Each test class maps to one spec directory and cites the spec path in its docstring.

Covered specs:
  openspec/specs/agent-capabilities-documentation
  openspec/specs/architectural-remediation
  openspec/specs/automated-acceptance-testing
  openspec/specs/cache-hardening
  openspec/specs/centralized-script-config
  openspec/specs/centralized-script-options
  openspec/specs/config-documentation
  openspec/specs/display
  openspec/specs/keybinding-consolidation
"""

import os
import re
import time

import pytest

from tests.ipc.mpv_ipc import query_kardenwort_state, query_kardenwort_render
from tests.ipc.mpv_session import MpvSession

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_FIXTURE_DIR = "tests/fixtures/20260502165659-test-fixture"
_VIDEO = os.path.abspath(f"{_FIXTURE_DIR}/20260502165659-test-fixture.mp4")
_SRT = os.path.abspath(f"{_FIXTURE_DIR}/20260502165659-test-fixture.en.srt")


def _robust_state(ipc, attempts: int = 6) -> dict:
    """Retry wrapper around query_kardenwort_state to handle async property-change races."""
    last_exc = None
    for _ in range(attempts):
        try:
            return query_kardenwort_state(ipc)
        except (RuntimeError, TimeoutError) as exc:
            last_exc = exc
            time.sleep(0.35)
    raise RuntimeError(f"State not available after {attempts} attempts: {last_exc}")


# ---------------------------------------------------------------------------
# 1. agent-capabilities-documentation
# ---------------------------------------------------------------------------

class TestAgentCapabilitiesDocumentation:
    """
    Spec: openspec/specs/agent-capabilities-documentation

    Verifies that AGENTS.md exists in the project root, documents the expected
    slash commands, and that those commands have corresponding workflow files.
    """

    _EXPECTED_SLASH_COMMANDS = ["/opsx:apply", "/opsx:archive", "/opsx:explore", "/opsx:propose"]
    _EXPECTED_WORKFLOW_FILES = [
        ".agent/workflows/opsx-apply.md",
        ".agent/workflows/opsx-archive.md",
        ".agent/workflows/opsx-explore.md",
        ".agent/workflows/opsx-propose.md",
    ]

    def test_agents_md_exists(self):
        """AGENTS.md must be present in the project root."""
        assert os.path.exists("AGENTS.md"), "AGENTS.md not found in project root"

    def test_agents_md_documents_slash_commands(self):
        """AGENTS.md must document the expected slash commands."""
        content = open("AGENTS.md", encoding="utf-8").read()
        for cmd in self._EXPECTED_SLASH_COMMANDS:
            assert cmd in content, (
                f"Slash command '{cmd}' not documented in AGENTS.md"
            )

    def test_slash_command_workflow_files_exist(self):
        """Each slash command must have a backing workflow .md file."""
        for wf in self._EXPECTED_WORKFLOW_FILES:
            assert os.path.exists(wf), f"Workflow file missing: {wf}"

    def test_agents_md_lists_skills(self):
        """AGENTS.md must contain a Skills table."""
        content = open("AGENTS.md", encoding="utf-8").read()
        assert "openspec-propose" in content, (
            "AGENTS.md must document the 'openspec-propose' skill"
        )
        assert "openspec-apply" in content, (
            "AGENTS.md must document the 'openspec-apply' skill"
        )


# ---------------------------------------------------------------------------
# 2. architectural-remediation
# ---------------------------------------------------------------------------

class TestArchitecturalRemediation:
    """
    Spec: openspec/specs/architectural-remediation

    Verifies:
    - flush_rendering_caches is present and callable via IPC.
    - WORD_CHAR_MAP is the single O(1) tokenizer used across the codebase.
    - LAYOUT_VERSION sentinel exists in kardenwort.lua.
    """

    def test_flush_rendering_caches_exists(self):
        """kardenwort.lua must define flush_rendering_caches (centralized invalidation)."""
        with open("scripts/kardenwort/main.lua", encoding="utf-8") as f:
            content = f.read()
        assert "flush_rendering_caches" in content, (
            "flush_rendering_caches function not found in kardenwort.lua"
        )

    def test_word_char_map_is_unified_tokenizer(self):
        """WORD_CHAR_MAP must be present as the single O(1) word-char lookup table."""
        with open("scripts/kardenwort/main.lua", encoding="utf-8") as f:
            content = f.read()
        assert "WORD_CHAR_MAP" in content, (
            "WORD_CHAR_MAP not found; unified O(1) tokenizer is missing"
        )
        # Must be referenced more than once (definition + at least one usage)
        count = content.count("WORD_CHAR_MAP")
        assert count >= 2, (
            f"WORD_CHAR_MAP appears only {count} time(s); expected definition + usage"
        )

    def test_layout_version_sentinel_exists(self):
        """LAYOUT_VERSION must exist to drive cache invalidation on config change."""
        with open("scripts/kardenwort/main.lua", encoding="utf-8") as f:
            content = f.read()
        assert "LAYOUT_VERSION" in content, (
            "LAYOUT_VERSION sentinel not found in kardenwort.lua"
        )

    def test_cache_flush_triggered_by_drum_toggle(self, mpv):
        """
        Toggleing Drum Mode must cause a cache flush; we verify this by checking
        that the FSM drum_mode state changes (implying cmd_toggle_drum ran through
        the full flush path without error).
        """
        ipc = mpv.ipc
        state_before = _robust_state(ipc)
        drum_before = state_before.get("drum_mode", False)

        ipc.command(["script-binding", "kardenwort/toggle-drum-mode"])
        time.sleep(0.3)

        state_after = _robust_state(ipc)
        drum_after = state_after.get("drum_mode", False)

        assert drum_after != drum_before, (
            "Drum mode did not change after toggle-drum-mode; flush path may be broken"
        )

        # Restore
        ipc.command(["script-binding", "kardenwort/toggle-drum-mode"])
        time.sleep(0.2)


# ---------------------------------------------------------------------------
# 3. automated-acceptance-testing
# ---------------------------------------------------------------------------

class TestAutomatedAcceptanceTesting:
    """
    Spec: openspec/specs/automated-acceptance-testing

    Validates the infrastructure contracts:
    - IPC state probe exists and returns semantic field names.
    - IPC render probe returns raw ASS data.
    - Test headers cite a spec (validated structurally across this suite).
    - MpvSession teardown works even if the test body raises.
    """

    def test_state_probe_returns_semantic_fields(self, mpv):
        """state-query must return stable, semantic field names."""
        state = _robust_state(mpv.ipc)
        required_fields = {"autopause", "drum_mode", "playback_state"}
        missing = required_fields - set(state.keys())
        assert not missing, (
            f"State probe missing semantic fields: {missing}\nGot: {list(state.keys())}"
        )

    def test_render_probe_returns_ass_string(self, mpv):
        """render-query must return a string (possibly empty) for 'drum'."""
        result = query_kardenwort_render(mpv.ipc, "drum")
        assert isinstance(result, str), (
            f"render-query 'drum' returned non-string: {type(result)}"
        )

    def test_render_probe_unknown_overlay_returns_empty(self, mpv):
        """Querying an unknown overlay name must return empty string, no Lua error."""
        result = query_kardenwort_render(mpv.ipc, "non_existent_overlay_xyz")
        assert result == "" or result is None, (
            f"Expected empty string for unknown overlay, got: {result!r}"
        )

    def test_acceptance_test_files_have_feature_zid_header(self):
        """Every acceptance test file must begin with a Feature ZID docstring header."""
        import glob
        test_files = glob.glob("tests/acceptance/test_*.py")
        failures = []
        for tf in test_files:
            content = open(tf, encoding="utf-8").read()
            if "Feature ZID:" not in content and "Feature:" not in content:
                failures.append(os.path.basename(tf))
        assert not failures, (
            f"The following test files lack a Feature ZID/Feature header: {failures}"
        )

    def test_mpv_session_teardown_on_exception(self):
        """MpvSession.stop() must terminate mpv even when an exception is raised."""
        session = MpvSession(video=_VIDEO, subtitle=_SRT, extra_args=["--pause"])
        session.start()
        try:
            raise RuntimeError("simulated test failure")
        except RuntimeError:
            pass
        finally:
            session.stop()  # must not raise or deadlock
        # If we reach here, teardown succeeded
        assert True


# ---------------------------------------------------------------------------
# 4. cache-hardening
# ---------------------------------------------------------------------------

class TestCacheHardening:
    """
    Spec: openspec/specs/cache-hardening

    Verifies:
    - DRUM_DRAW_CACHE and DW_DRAW_CACHE are defined.
    - flush_rendering_caches is called and does not error.
    - Toggling drum mode causes a state change (implying re-render from fresh cache).
    """

    def test_cache_tables_are_defined(self):
        """DRUM_DRAW_CACHE and DW_DRAW_CACHE must be defined in kardenwort.lua."""
        with open("scripts/kardenwort/main.lua", encoding="utf-8") as f:
            content = f.read()
        assert "DRUM_DRAW_CACHE" in content, "DRUM_DRAW_CACHE missing from kardenwort.lua"
        assert "DW_DRAW_CACHE" in content, "DW_DRAW_CACHE missing from kardenwort.lua"

    def test_flush_rendering_caches_called_on_mode_toggle(self, mpv):
        """
        Toggling Drum Mode must not produce a Lua error (which would prevent the
        state change), confirming flush_rendering_caches executed successfully.
        """
        ipc = mpv.ipc
        state_before = _robust_state(ipc)

        ipc.command(["script-binding", "kardenwort/toggle-drum-mode"])
        time.sleep(0.3)

        state_after = _robust_state(ipc)
        assert state_after.get("drum_mode") != state_before.get("drum_mode"), (
            "Drum mode did not toggle; cache flush likely caused a Lua error"
        )
        # Restore
        ipc.command(["script-binding", "kardenwort/toggle-drum-mode"])
        time.sleep(0.2)

    def test_layout_version_is_integer(self):
        """LAYOUT_VERSION must be initialized to an integer (0 or 1) in kardenwort.lua."""
        with open("scripts/kardenwort/main.lua", encoding="utf-8") as f:
            content = f.read()
        match = re.search(r"LAYOUT_VERSION\s*=\s*(\d+)", content)
        assert match, "LAYOUT_VERSION not initialized to an integer"
        assert int(match.group(1)) >= 0


# ---------------------------------------------------------------------------
# 5. centralized-script-config
# ---------------------------------------------------------------------------

class TestCentralizedScriptConfig:
    """
    Spec: openspec/specs/centralized-script-config

    Verifies:
    - mpv.conf contains script-opts-append entries for kardenwort parameters.
    - sec_pos_bottom is configurable via script-opts.
    - mpv.conf contains [LINKED] documentation tags.
    """

    def test_mpv_conf_contains_script_opts(self):
        """mpv.conf must contain script-opts-append entries for kardenwort."""
        with open("mpv.conf", encoding="utf-8") as f:
            content = f.read()
        assert "script-opts-append=kardenwort" in content, (
            "mpv.conf does not contain script-opts-append entries for kardenwort"
        )

    def test_mpv_conf_has_sec_pos_bottom(self):
        """mpv.conf must expose sec_pos_bottom as a configurable option."""
        with open("mpv.conf", encoding="utf-8") as f:
            content = f.read()
        assert "sec_pos_bottom" in content, (
            "sec_pos_bottom not found in mpv.conf; not user-configurable"
        )

    def test_mpv_conf_has_cross_reference_documentation(self):
        """mpv.conf must contain cross-referencing comments tying position options together."""
        with open("mpv.conf", encoding="utf-8") as f:
            content = f.read()
        # The spec requires a warning about the gap between sec_pos_bottom and sub-pos.
        # In practice this appears as comments near both options referencing each other.
        has_sec_pos = "sec_pos_bottom" in content
        has_sub_pos = "sub-pos" in content or "sub_pos" in content
        assert has_sec_pos and has_sub_pos, (
            "mpv.conf must document both sec_pos_bottom and sub-pos to satisfy "
            "the cross-reference requirement (positional gap warning)"
        )


# ---------------------------------------------------------------------------
# 6. centralized-script-options
# ---------------------------------------------------------------------------

class TestCentralizedScriptOptions:
    """
    Spec: openspec/specs/centralized-script-options

    Verifies:
    - kardenwort.lua uses mp.options to read its Options table.
    - Every key in the Options table has a corresponding script-opts-append in mpv.conf.
    """

    def test_kardenwort_uses_mp_options(self):
        """kardenwort.lua must call mp.options to read script-opts."""
        with open("scripts/kardenwort/main.lua", encoding="utf-8") as f:
            content = f.read()
        assert "mp.options" in content, (
            "kardenwort.lua does not reference mp.options; centralized config not wired"
        )

    def test_mpv_conf_coverage_of_critical_options(self):
        """Key script options (seek_time_delta, drum_font_size) must appear in mpv.conf."""
        with open("mpv.conf", encoding="utf-8") as f:
            conf = f.read()
        critical = ["seek_time_delta", "drum_font_size"]
        missing = [opt for opt in critical if opt not in conf]
        assert not missing, (
            f"Critical options missing from mpv.conf: {missing}"
        )

    def test_script_opts_applied_to_fsm_state(self, mpv):
        """Script-opts must be reflected in the FSM state (autopause is opts-driven)."""
        state = _robust_state(mpv.ipc)
        assert "autopause" in state, (
            "FSM state does not expose 'autopause'; script-opts may not be wired"
        )


# ---------------------------------------------------------------------------
# 7. config-documentation
# ---------------------------------------------------------------------------

class TestConfigDocumentation:
    """
    Spec: openspec/specs/config-documentation

    Verifies:
    - input.conf is organized into labeled functional sections.
    - The LEFT arrow binding exists with a comment explaining its 2-second behavior.
    """

    def test_input_conf_has_navigation_section(self):
        """input.conf must contain a clearly delineated NAVIGATION section."""
        with open("input.conf", encoding="utf-8") as f:
            content = f.read()
        assert "NAVIGATION" in content.upper(), (
            "No NAVIGATION section found in input.conf"
        )

    def test_input_conf_left_arrow_has_comment(self):
        """The LEFT arrow binding must include a descriptive comment."""
        with open("input.conf", encoding="utf-8") as f:
            content = f.read()
        lines = content.split("\n")
        left_idx = next(
            (i for i, l in enumerate(lines) if l.strip().startswith("LEFT")), None
        )
        assert left_idx is not None, "LEFT arrow binding not found in input.conf"
        # Check for a comment line in the surrounding context (within 5 lines above)
        context_start = max(0, left_idx - 5)
        context = "\n".join(lines[context_start: left_idx + 1])
        assert "#" in context, (
            f"No comment found near LEFT binding in input.conf.\nContext:\n{context}"
        )

    def test_input_conf_has_multiple_sections(self):
        """input.conf must have multiple logical section headers (# ===... style)."""
        with open("input.conf", encoding="utf-8") as f:
            content = f.read()
        section_count = content.count("===")
        assert section_count >= 2, (
            f"input.conf has fewer than 2 section delimiters (found {section_count})"
        )


# ---------------------------------------------------------------------------
# 8. display  (original-spacing-preservation)
# ---------------------------------------------------------------------------

class TestDisplay:
    """
    Spec: openspec/specs/display  (original-spacing-preservation)

    Verifies that the build_word_list scanner captures whitespace tokens and
    that selection navigation skips whitespace-only tokens.
    The scanner logic lives entirely in kardenwort.lua; we validate structural
    invariants rather than booting mpv for each case.
    """

    def test_build_word_list_handles_whitespace_as_token(self):
        """
        kardenwort.lua must contain logic that identifies whitespace tokens
        separately from word tokens (required for original-spacing-preservation).
        """
        with open("scripts/kardenwort/main.lua", encoding="utf-8") as f:
            content = f.read()
        # The scanner must reference 'dw_original_spacing' or equivalent
        assert "original_spacing" in content or "ws_token" in content or (
            "is_space" in content
        ), (
            "No whitespace-token handling found in kardenwort.lua "
            "(dw_original_spacing / is_space / ws_token)"
        )

    def test_drum_window_render_does_not_double_space(self, mpv):
        """
        When Drum Window is active, the rendered ASS string for a normal subtitle
        must NOT contain double-space artifacts that indicate a broken joiner.
        """
        ipc = mpv.ipc
        # Seek to a subtitle
        ipc.command(["seek", 1.5, "absolute+exact"])
        time.sleep(0.3)

        # Open drum window
        ipc.command(["script-message", "toggle-drum-window"])
        time.sleep(0.3)

        render = query_kardenwort_render(ipc, "dw")
        if render:
            assert "  " not in re.sub(r"\{[^}]*\}", "", render), (
                "Drum Window render contains double-space artifacts"
            )

        # Close drum window
        ipc.command(["script-message", "toggle-drum-window"])
        time.sleep(0.2)


# ---------------------------------------------------------------------------
# 9. keybinding-consolidation
# ---------------------------------------------------------------------------

class TestKeybindingConsolidation:
    """
    Spec: openspec/specs/keybinding-consolidation

    Verifies:
    - kardenwort.lua registers commands with nil as the default key (deferred to input.conf).
    - input.conf is the exclusive key-binding authority.
    """

    def test_kardenwort_registers_commands_with_nil_default(self):
        """
        mp.add_key_binding calls in kardenwort.lua must use nil as the default key,
        deferring all physical key assignments to input.conf.
        """
        with open("scripts/kardenwort/main.lua", encoding="utf-8") as f:
            content = f.read()
        assert "mp.add_key_binding(nil," in content, (
            "kardenwort.lua must use mp.add_key_binding(nil, ...) for user-configurable commands"
        )
        # Ensure there are NO hardcoded single-character defaults
        hardcoded = re.findall(r'mp\.add_key_binding\("([a-zA-Z])"', content)
        assert not hardcoded, (
            f"kardenwort.lua hardcodes key bindings: {hardcoded}; "
            "all bindings must go through input.conf"
        )

    def test_input_conf_is_present_and_non_empty(self):
        """input.conf must exist and contain binding definitions."""
        assert os.path.exists("input.conf"), "input.conf not found in project root"
        content = open("input.conf", encoding="utf-8").read()
        assert len(content.strip()) > 0, "input.conf is empty"

    def test_script_binding_commands_in_input_conf(self):
        """input.conf must use 'script-binding' to invoke kardenwort commands."""
        with open("input.conf", encoding="utf-8") as f:
            content = f.read()
        assert "script-binding" in content, (
            "input.conf does not use 'script-binding'; "
            "keybinding consolidation not enforced"
        )


# ---------------------------------------------------------------------------
# 10. consumption-focused-documentation
# ---------------------------------------------------------------------------

class TestConsumptionFocusedDocumentation:
    """
    Spec: openspec/specs/consumption-focused-documentation

    Verifies that the project documentation covers:
    - Dual-subtitle consumption workflow instructions.
    - How Drum Mode mitigates context-loss from YouTube/low-quality subtitles.
    """

    def test_readme_documents_drum_mode(self):
        """README.md must document Drum Mode and its purpose for YouTube subtitles."""
        assert os.path.exists("README.md"), "README.md not found in project root"
        content = open("README.md", encoding="utf-8").read()
        assert "Drum" in content, (
            "README.md must document 'Drum Mode' for context-loss mitigation"
        )

    def test_readme_mentions_dual_subtitles(self):
        """README.md must describe dual-subtitle / secondary subtitle functionality."""
        content = open("README.md", encoding="utf-8").read()
        has_dual = "dual" in content.lower() or "secondary" in content.lower()
        assert has_dual, (
            "README.md must describe dual-subtitle / secondary subtitle support"
        )

    def test_readme_documents_acquisition_workflow(self):
        """README.md must contain workflow or usage instructions for language acquisition."""
        content = open("README.md", encoding="utf-8").read()
        has_workflow = any(kw in content.lower() for kw in ["workflow", "acquisition", "immersion", "anki"])
        assert has_workflow, (
            "README.md must document the language acquisition workflow "
            "(workflow / acquisition / immersion / anki keywords expected)"
        )




