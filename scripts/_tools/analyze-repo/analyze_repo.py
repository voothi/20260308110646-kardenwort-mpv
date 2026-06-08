#!/usr/bin/env python3
"""
Repository Analytics Script for mpv Language Acquisition Suite.
Usage: git log --pretty=format:"%ad" --date=iso-strict | python scripts/_tools/analyze-repo/analyze_repo.py
"""

import sys
import os
import glob
import subprocess
from datetime import datetime

def find_project_root_vault():
    try:
        with open("openspec/config.yaml", "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                if line.startswith("projectRoot:"):
                    return line.split(":", 1)[1].strip()
    except Exception:
        pass
    return r"U:\voothi.vault\kardenwort-mpv"

def get_git_structure():
    branches = 0
    tags = 0
    try:
        res = subprocess.run(["git", "branch", "--list"], capture_output=True, text=True, check=True)
        branches = len([l for l in res.stdout.splitlines() if l.strip()])
    except Exception:
        pass
    try:
        res = subprocess.run(["git", "tag"], capture_output=True, text=True, check=True)
        tags = len([l for l in res.stdout.splitlines() if l.strip()])
    except Exception:
        pass
    return branches, tags

def get_lines_of_code():
    project_files = [
        "scripts/kardenwort/main.lua",
        "scripts/kardenwort/resume.lua",
        "scripts/kardenwort/utils.lua",
        "mpv.conf",
        "input.conf"
    ]
    project_loc = 0
    for fpath in project_files:
        try:
            if os.path.exists(fpath):
                with open(fpath, "r", encoding="utf-8", errors="ignore") as f:
                    project_loc += sum(1 for _ in f)
        except Exception:
            pass
            
    additions_loc = 0
    if os.path.exists("scripts/_tools"):
        for root, _, files in os.walk("scripts/_tools"):
            for file in files:
                try:
                    fpath = os.path.join(root, file)
                    with open(fpath, "r", encoding="utf-8", errors="ignore") as f:
                        additions_loc += sum(1 for _ in f)
                except Exception:
                    pass
                    
    tests_loc = 0
    if os.path.exists("tests"):
        for root, _, files in os.walk("tests"):
            for file in files:
                if file.endswith(".py"):
                    try:
                        fpath = os.path.join(root, file)
                        with open(fpath, "r", encoding="utf-8", errors="ignore") as f:
                            tests_loc += sum(1 for _ in f)
                    except Exception:
                        pass
                        
    total_loc = project_loc + additions_loc + tests_loc
    return total_loc, project_loc, additions_loc, tests_loc

def get_total_requests():
    vault_dir = find_project_root_vault()
    conversations_dir = os.path.join(vault_dir, "conversations")
    active_requests_count = 0
    if os.path.exists(conversations_dir):
        active_conv_files = glob.glob(os.path.join(conversations_dir, "*conversation.md"))
        if active_conv_files:
            latest_file = max(active_conv_files, key=os.path.getmtime)
            try:
                with open(latest_file, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        if line.startswith("- [["):
                            active_requests_count += 1
            except Exception:
                pass
    archived_requests_count = 3277
    return archived_requests_count + active_requests_count, active_requests_count, archived_requests_count

def analyze_git_log(log_output):
    times = []
    for line in log_output.strip().split('\n'):
        line_clean = line.strip().replace('\ufeff', '')
        if line_clean:
            try:
                times.append(datetime.fromisoformat(line_clean))
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
    
    # Calculate streak (days in a row)
    unique_dates = sorted(list({t.date() for t in times}))
    max_streak = 0
    current_streak = 0
    prev_date = None
    for d in unique_dates:
        if prev_date is None:
            current_streak = 1
        elif (d - prev_date).days == 1:
            current_streak += 1
        elif (d - prev_date).days > 1:
            if current_streak > max_streak:
                max_streak = current_streak
            current_streak = 1
        prev_date = d
    if current_streak > max_streak:
        max_streak = current_streak

    # Calculate average break in days between sessions
    breaks = []
    for i in range(len(sessions) - 1):
        end_curr = sessions[i][1]
        start_next = sessions[i+1][0]
        break_sec = (start_next - end_curr).total_seconds()
        breaks.append(break_sec / 86400.0)
    avg_break = sum(breaks) / len(breaks) if breaks else 0.0

    return {
        "total_hours": total_duration,
        "first_commit": times[0],
        "last_commit": times[-1],
        "total_commits": len(times),
        "sessions": sessions,
        "max_streak": max_streak,
        "avg_break": avg_break
    }
 
if __name__ == "__main__":
    content = sys.stdin.read()
    results = analyze_git_log(content)
    if results:
        # Extra calculations
        num_sessions = len(results['sessions'])
        avg_session = results['total_hours'] / num_sessions if num_sessions else 0
        intensity = results['total_commits'] / results['total_hours'] if results['total_hours'] else 0
        
        branches, tags = get_git_structure()
        total_loc, proj_loc, add_loc, test_loc = get_lines_of_code()
        total_reqs, active_reqs, arch_reqs = get_total_requests()
        
        # README friendly print format
        print("=== README Development Analytics Output ===")
        print(f"- **Project Inception**: {results['first_commit'].strftime('%B %d, %Y')}")
        print(f"- **Total Hours Spent**: {results['total_hours']:.2f}h (across {num_sessions} work sessions, average session of {avg_session:.2f}h; human-AI paired, not autonomous)")
        print(f"- **Current Maturity**: ~{results['total_commits']} Commits")
        print(f"- **Consecutive Days Streak**: {results['max_streak']} days in a row")
        print(f"- **Average Break**: {results['avg_break']:.2f} days between work sessions")
        print(f"- **Total Requests**: {total_reqs:,} human requests ({active_reqs} in active log, {arch_reqs:,} in archive)")
        print(f"- **Intensity Profile**: {intensity:.1f} Commits/Hour")
        print(f"- **Git Structure**: {branches} local branches, {tags} tags")
        print(f"- **Lines of Code**: {total_loc:,} LOC ({proj_loc:,} project, {add_loc:,} additions, {test_loc:,} tests)")
        print("- **AI Subscriptions Cost**: 150 EUR")
        print("===========================================")
        
        print(f"\nTotal Hours Spent: {results['total_hours']:.2f}h")
        print(f"Total Commits: {results['total_commits']}")
        print(f"Development Began: {results['first_commit']}")
        print(f"Latest Commit: {results['last_commit']}")
        print(f"Work Sessions: {len(results['sessions'])}")
        print(f"Consecutive Days Streak: {results['max_streak']} days")
        print(f"Average Break Between Sessions: {results['avg_break']:.2f} days")
        print("\n--- Session Breakdown ---")
        for i, s in enumerate(results['sessions'], 1):
            print(f"Session {i}: {s[0]} to {s[1]} ({s[2]:.2f}h)")
    else:
        print("No commit data found.")
