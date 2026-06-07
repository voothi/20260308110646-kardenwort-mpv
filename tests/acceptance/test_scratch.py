import time
import pytest
import json
from tests.ipc.mpv_ipc import query_kardenwort_state

def _state(ipc):
    return query_kardenwort_state(ipc)

def _seek(ipc, pos):
    ipc.command(["seek", pos, "absolute+exact"])
    time.sleep(0.2)

def _setup(ipc):
    ipc.command(['script-message-to', 'kardenwort', 'immersion-mode-set', 'PHRASE'])
    ipc.command(['script-message-to', 'kardenwort', 'autopause-set', 'ON'])
    ipc.command(['set_property', 'options/kardenwort-audio_padding_start', '1000'])
    ipc.command(['set_property', 'options/kardenwort-audio_padding_end', '1000'])
    time.sleep(0.2)

def _seek_time(ipc, direction):
    ipc.command(['script-message-to', 'kardenwort', 'test-seek-time', str(direction)])
    time.sleep(0.15)

def test_debug_fragment2(mpv_fragment2):
    ipc = mpv_fragment2.ipc
    _setup(ipc)
    _seek(ipc, 13.5)
    
    logs = []
    
    logs.append(f"Before seeks: time-pos={ipc.get_property('time-pos')}")
    logs.append(f"State: {json.dumps(_state(ipc))}")
    
    for i in range(3):
        _seek_time(ipc, -1)
        logs.append(f"After seek {i+1}: time-pos={ipc.get_property('time-pos')}")
        logs.append(f"State: {json.dumps(_state(ipc))}")
        
    logs.append("Unpausing...")
    ipc.command(["set_property", "pause", False])
    
    start = time.time()
    while time.time() - start < 4.0:
        if ipc.get_property("pause"):
            logs.append("Paused naturally!")
            break
        logs.append(f"time-pos during play: {ipc.get_property('time-pos')} State: {json.dumps(_state(ipc))}")
        time.sleep(0.1)
        
    logs.append(f"Final: time-pos={ipc.get_property('time-pos')}")
    logs.append(f"State: {json.dumps(_state(ipc))}")
    
    with open("scratch/scratch_debug.log", "w", encoding="utf-8") as f:
        f.write("\n".join(logs))
    
    assert False
