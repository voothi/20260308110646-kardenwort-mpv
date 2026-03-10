#!/usr/bin/env python3
"""
Repository Analytics Script for mpv Language Learning Suite.
Usage: git log --pretty=format:"%ad" --date=iso-strict | python docs/analyze_repo.py
"""

import sys
from datetime import datetime

def analyze_git_log(log_output):
    times = []
    for line in log_output.strip().split('\n'):
        if line.strip():
            try:
                times.append(datetime.fromisoformat(line.strip()))
            except ValueError:
                continue
    
    if not times:
        return None
    
    times.sort()
    
    total_duration = 0
    # Session timeout in minutes (if break > 2 hours, start new session)
    TIMEOUT_MINUTES = 120 
    # Buffer added to each session for setup/context (15 mins each side)
    BUFFER_MINUTES = 15 
    
    if len(times) == 0:
        return None

    sessions = []
    session_start = times[0]
    last_time = times[0]

    for i in range(1, len(times)):
        diff = (times[i] - last_time).total_seconds() / 60
        if diff > TIMEOUT_MINUTES:
            # End current session
            duration_hrs = (last_time - session_start).total_seconds() / 3600
            duration_hrs += (BUFFER_MINUTES * 2) / 60 
            total_duration += duration_hrs
            sessions.append((session_start, last_time, duration_hrs))
            
            # Start new session
            session_start = times[i]
        last_time = times[i]
        
    # Final session
    duration_hrs = (last_time - session_start).total_seconds() / 3600
    duration_hrs += (BUFFER_MINUTES * 2) / 60
    total_duration += duration_hrs
    sessions.append((session_start, last_time, duration_hrs))
    
    return {
        "total_hours": total_duration,
        "first_commit": times[0],
        "last_commit": times[-1],
        "total_commits": len(times),
        "sessions": sessions
    }

if __name__ == "__main__":
    content = sys.stdin.read()
    results = analyze_git_log(content)
    if results:
        print(f"Total Hours Spent: {results['total_hours']:.2f}h")
        print(f"Total Commits: {results['total_commits']}")
        print(f"Development Began: {results['first_commit']}")
        print(f"Latest Commit: {results['last_commit']}")
        print(f"Work Sessions: {len(results['sessions'])}")
        print("\n--- Session Breakdown ---")
        for i, s in enumerate(results['sessions'], 1):
            print(f"Session {i}: {s[0]} to {s[1]} ({s[2]:.2f}h)")
    else:
        print("No commit data found.")
