"""
Feature ZID: 20260606132838
Feature: Sub TTS Pipeline - Fit Subtitle to Recording
"""

import configparser
import importlib.util
from pathlib import Path
import pytest

_SCRIPT_PATH = (
    Path(__file__).resolve().parents[2]
    / "scripts"
    / "_tools"
    / "sub-tts"
    / "sub_tts.py"
)

def _load_sub_tts():
    spec = importlib.util.spec_from_file_location("sub_tts_under_test", _SCRIPT_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def _config():
    config = configparser.ConfigParser()
    config["tts_settings"] = {
        "fit_subtitle_to_recording": "true",
        "max_extra_gap_ms": "1000",
        "vad_silence_compression": "false",
    }
    return config

def test_plan_recording_timeline_expands_and_shifts(monkeypatch):
    # 5.1 Unit test: plan_recording_timeline expands a long cue's end and shifts later cues with no residual overlap
    sub_tts = _load_sub_tts()
    
    synthesis_results = [
        {"ok": True, "wav_path": Path("cue_1.wav"), "fit_duration_ms": 3000, "cue": {"index": 1, "start_ms": 1000, "end_ms": 2000, "text": "a"}}, # duration 3000 > 1000
        {"ok": True, "wav_path": Path("cue_2.wav"), "fit_duration_ms": 1500, "cue": {"index": 2, "start_ms": 2500, "end_ms": 3500, "text": "b"}},
    ]
    
    plan = sub_tts.plan_recording_timeline(synthesis_results, "ffmpeg")
    
    assert plan == [0, 1500]
    assert plan.explicit_ends_ms == {0: 4000, 1: 5500}
    assert plan.explicit_targets_ms == {0: 3000, 1: 1500}

def test_primary_trim_only_path_applies_no_tempo_change(monkeypatch, tmp_path):
    # 5.2 Unit test: primary trim-only path applies no tempo change (assert speed_factor == 1.0)
    sub_tts = _load_sub_tts()
    config = _config()
    
    monkeypatch.setattr(sub_tts, "trim_silence_for_cue", lambda i, f, t, ff, ve, ms: f)
    monkeypatch.setattr(sub_tts, "get_wav_duration_ms", lambda p, ff: 5000)
    
    synthesis_results = [
        {"ok": True, "wav_path": Path("cue_1.wav"), "cue": {"index": 1, "start_ms": 1000, "end_ms": 2000, "text": "a"}},
    ]
    
    adjusted = sub_tts.trim_cues_only(synthesis_results, tmp_path, "ffmpeg", config)
    
    assert len(adjusted) == 1
    assert adjusted[0]["speed_factor"] == 1.0
    assert not adjusted[0]["speed_limited"]

def test_speed_fit_to_slots(monkeypatch, tmp_path):
    # 5.3 Unit test: secondary cues anchored at canonical primary start times; longer secondary cue is sped up to fit its slot
    sub_tts = _load_sub_tts()
    config = _config()
    
    plan = sub_tts.ShiftPlan([0, 0])
    plan.explicit_targets_ms = {0: 2000} # primary slot is 2000ms
    
    monkeypatch.setattr(sub_tts, "get_wav_duration_ms", lambda p, ff: 4000) # secondary audio is 4000ms
    monkeypatch.setattr(sub_tts, "change_audio_speed", lambda i, o, s, f, h: True)
    
    synthesis_results = [
        {"ok": True, "wav_path": tmp_path / "cue_1.wav", "cue": {"index": 1, "start_ms": 1000, "end_ms": 2000, "text": "secondary"}},
    ]
    
    adjusted = sub_tts.speed_fit_to_slots(synthesis_results, plan, tmp_path, "ffmpeg", config)
    
    assert len(adjusted) == 1
    assert adjusted[0]["speed_factor"] == 2.0
    assert adjusted[0]["target_ms"] == 2000

def test_regression_with_flag_off_planning_behavior_unchanged(monkeypatch):
    # 5.4 Regression test: with the flag off, planning output and pipeline behavior are unchanged
    sub_tts = _load_sub_tts()
    config = _config()
    config["tts_settings"]["fit_subtitle_to_recording"] = "false"
    
    durations = {"cue_001.wav": 3000, "cue_002.wav": 1000}
    monkeypatch.setattr(sub_tts, "get_wav_duration_ms", lambda p, ff: durations[Path(p).name])
    
    synthesis_results = [
        {"ok": True, "wav_path": Path("cue_001.wav"), "cue": {"index": 1, "start_ms": 1000, "end_ms": 1500, "text": "a"}},
        {"ok": True, "wav_path": Path("cue_002.wav"), "cue": {"index": 2, "start_ms": 2000, "end_ms": 2500, "text": "b"}},
    ]
    
    plan = sub_tts.plan_subtitle_shifts(synthesis_results, "ffmpeg")
    assert plan == [0, 2000]
