"""
Feature ZID: 20260509085155
Test Creation ZID: 20260509085637
Feature: Drum Osd Contains Color
"""

# Spec: openspec/changes/20260502165659-implement-spec-driven-testing/specs/automated-acceptance-testing/spec.md
# Scenario: Verifying highlight color
import re, time
from tests.ipc.mpv_ipc import query_kardenwort_render


def test_drum_osd_contains_color_tags(mpv):
    mpv.ipc.command(['script-binding', 'kardenwort/toggle-drum-mode'])
    time.sleep(0.1)
    render = query_kardenwort_render(mpv.ipc, 'drum')
    assert re.search(r'\\1c&H[0-9A-Fa-f]{6}&', render), \
        f'No \\1c color tag found in drum OSD. Got: {render[:200]}'




