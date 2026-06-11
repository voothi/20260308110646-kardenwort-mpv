"""
Feature ZID: 20260611004849
Feature: Album Art Detection & Black Video Fallback for Audio-Only Media with Embedded Cover Art

Validated against openspec spec: audio-only-media
"""

import shutil
import time
import subprocess
import pytest
from pathlib import Path
from tests.ipc.mpv_session import MpvSession
from tests.ipc.mpv_ipc import query_kardenwort_state

def _wait_until(predicate, timeout=5.0, interval=0.1):
    start = time.time()
    while time.time() - start < timeout:
        if predicate():
            return True
        time.sleep(interval)
    return False

def _create_mp3_with_album_art(mp3_path, duration=5):
    work = mp3_path.parent
    jpg_path = work / "cover.jpg"
    # Create a small blue image
    subprocess.run([
        "ffmpeg", "-y", "-f", "lavfi", "-i", "color=c=blue:s=128x128",
        "-frames:v", "1", str(jpg_path)
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    # Create MP3 with album art
    subprocess.run([
        "ffmpeg", "-y", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo",
        "-i", str(jpg_path),
        "-map", "0:a", "-map", "1:v", "-c:a", "libmp3lame", "-c:v", "mjpeg",
        "-id3v2_version", "3", "-metadata:s:v", 'title="Album cover"',
        "-t", str(duration), str(mp3_path)
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def test_mp3_with_album_art_loads_black_mp4_fallback():
    """Regression test: an MP3 with album art (which mpv sees as a video track)
    must still trigger the loading of black.mp4 fallback because album art
    is not a 'real' seekable study video.
    """
    work = Path("scratch/acceptance/mp3-album-art-fallback")
    if work.exists(): shutil.rmtree(work)
    work.mkdir(parents=True)
    
    media_mp3 = work / "sample.mp3"
    media_srt = work / "sample.en.srt"
    
    _create_mp3_with_album_art(media_mp3)
    media_srt.write_text("1\n00:00:01,000 --> 00:00:02,000\nLine One\n", encoding="utf-8")
    
    session = MpvSession(
        video=str(media_mp3),
        subtitle=str(media_srt),
        extra_args=[
            "--pause",
            "--script-opts=kardenwort-companion_subtitle_attach_on_load=no",
        ],
    )
    session.start()
    try:
        ipc = session.ipc
        
        # Wait for kardenwort to initialize
        def kardenwort_ready():
            state = query_kardenwort_state(ipc)
            return state.get("playback_state") != "INIT"
        
        assert _wait_until(kardenwort_ready, timeout=10.0), "Kardenwort did not initialize"
        
        # Check track list
        tracks = ipc.get_property("track-list")
        video_tracks = [t for t in tracks if t['type'] == 'video']
        
        print(f"DEBUG video_tracks: {video_tracks}")
        
        # We expect at least TWO video tracks: the album art and black.mp4
        # and black.mp4 should be the one selected (selected=True).
        
        # In modern mpv, black.mp4 filename will be in the 'title' or 'filename' of the track
        # but we can also check if any track with albumart=False is selected.
        
        selected_non_album_art = False
        for t in video_tracks:
            # mpv might mark album art with 'albumart': True
            is_album_art = t.get('albumart') or t.get('image')
            if not is_album_art and t.get('selected'):
                selected_non_album_art = True
                break
        
        assert selected_non_album_art, "Black.mp4 fallback was not selected for MP3 with album art"
        
    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)

def test_companion_video_depth_1_recursion():
    """Regression test: companion video tracks must be found in depth-1 subdirectories."""
    work = Path("scratch/acceptance/companion-depth-1")
    if work.exists(): shutil.rmtree(work)
    work.mkdir(parents=True)
    
    media_mp3 = work / "lesson.mp3"
    media_srt = work / "lesson.en.srt"
    
    # Put companion video in a subdirectory
    sub_dir = work / "videos"
    sub_dir.mkdir()
    companion_mp4 = sub_dir / "lesson.mp4"
    
    # Create silent MP3 and silent MP4
    subprocess.run([
        "ffmpeg", "-y", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo",
        "-t", "5", str(media_mp3)
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    subprocess.run([
        "ffmpeg", "-y", "-f", "lavfi", "-i", "color=c=black:s=640x480",
        "-t", "5", str(companion_mp4)
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    media_srt.write_text("1\n00:00:01,000 --> 00:00:02,000\nLine One\n", encoding="utf-8")
    
    session = MpvSession(
        video=str(media_mp3),
        subtitle=str(media_srt),
        extra_args=[
            "--pause",
            "--script-opts=kardenwort-companion_subtitle_attach_on_load=no",
        ],
    )
    session.start()
    try:
        ipc = session.ipc
        
        def companion_loaded():
            tracks = ipc.get_property("track-list")
            video_tracks = [t for t in tracks if t['type'] == 'video']
            print(f"DEBUG current video_tracks: {video_tracks}")
            for t in video_tracks:
                # mpv often puts the filename in 'filename' or 'title'
                fn = t.get('filename') or ""
                title = t.get('title') or ""
                if t.get('selected') and ("lesson.mp4" in fn or "ORIGINAL" in title):
                    return True
            return False

            
        assert _wait_until(companion_loaded, timeout=10.0), "Companion video in depth-1 subdir was not loaded"
        
    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)
