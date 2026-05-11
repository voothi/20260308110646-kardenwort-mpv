"""
Feature ZID: 20260511100252
Test Creation ZID: 20260511100252
Feature: RMB Hit-Testing Parity
Tests that RMB (and other mouse interactions) in Drum Mode work in the vertical gaps between lines.
"""
import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state

def test_drum_mode_gap_snapping(mpv_dual):
    """Mouse interactions in Drum Mode snap to the nearest line vertically."""
    ipc = mpv_dual.ipc
    
    # 1. Enable Drum Mode
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-drum-mode-set', 'ON'])
    time.sleep(0.2)
    
    # 2. Query hit zones to find a gap
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-query-hit-zones'])
    time.sleep(0.1)
    state = query_kardenwort_state(ipc)
    hit_zones = state.get('test_data', {}).get('drum_hit_zones', [])
    
    assert len(hit_zones) >= 2, "Need at least 2 hit zones to test gap snapping"
    
    # Find two adjacent zones with a gap
    zone1 = hit_zones[0]
    zone2 = hit_zones[1]
    
    # Check if they are vertically separated
    if zone1['y_bottom'] < zone2['y_top']:
        gap_y = (zone1['y_bottom'] + zone2['y_top']) / 2
        # Use center x of zone1
        target_x = zone1['x_start'] + zone1['total_width'] / 2
        
        # 3. Perform hit-test in the gap
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-hit-test', str(target_x), str(gap_y)])
        time.sleep(0.1)
        
        state = query_kardenwort_state(ipc)
        res = state.get('test_data', {}).get('hit_test_res', {})
        
        # It should hit either zone1 or zone2 (nearest one)
        assert res.get('line') is not None, f"Hit-test in gap {gap_y} should snap to a line. Zones: {zone1['y_bottom']} to {zone2['y_top']}"
        assert res['line'] in [zone1['sub_idx'], zone2['sub_idx']], f"Hit-test snapped to unexpected line: {res['line']}"
    else:
        pytest.skip("Could not find a vertical gap between zones 0 and 1")

def test_drum_mode_horizontal_strictness(mpv_dual):
    """Mouse interactions outside horizontal bounds do NOT snap."""
    ipc = mpv_dual.ipc
    
    # 1. Enable Drum Mode
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-drum-mode-set', 'ON'])
    time.sleep(0.2)
    
    # 2. Query hit zones
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-query-hit-zones'])
    time.sleep(0.1)
    state = query_kardenwort_state(ipc)
    hit_zones = state.get('test_data', {}).get('drum_hit_zones', [])
    
    if not hit_zones:
        pytest.skip("No hit zones available")
        
    zone = hit_zones[0]
    
    # Click far to the left of the text
    target_x = zone['x_start'] - 100
    target_y = (zone['y_top'] + zone['y_bottom']) / 2
    
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-hit-test', str(target_x), str(target_y)])
    time.sleep(0.1)
    
    state = query_kardenwort_state(ipc)
    res = state.get('test_data', {}).get('hit_test_res', {})
    # Handle empty Lua table being serialized as a list [] instead of {}
    if isinstance(res, list) or not res.get('line'):
        res = {}
        
    assert res.get('line') is None, "Should NOT snap horizontally when far outside bounds"




