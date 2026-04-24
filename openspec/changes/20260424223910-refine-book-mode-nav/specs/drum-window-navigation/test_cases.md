# Test Cases: Refined Book Mode Navigation

These test cases verify the stability and precision of the Drum Window navigation logic, specifically focusing on viewport scrolling and cursor independence.

## 1. Book Mode: Paged Scrolling (Playback)

| ID | Case | Action | Expected Result |
|----|------|--------|-----------------|
| BM-P-01 | Bottom Margin Jump | Play video until active subtitle hits the bottom margin (3 lines from edge). | Viewport jumps forward. The active subtitle is now at the TOP margin (3 lines from top). |
| BM-P-02 | Top Margin Jump | Seek back until active subtitle hits the top margin. | Viewport jumps backward. The active subtitle is now at the BOTTOM margin. |
| BM-P-03 | Configurable Margin | Set `dw_scrolloff=5`. Repeat BM-P-01. | Jump occurs exactly 5 lines from the edge. |

## 2. Book Mode: Manual Navigation (a/d)

| ID | Case | Action | Expected Result |
|----|------|--------|-----------------|
| BM-M-01 | Line-by-Line Push | Hold `d`. | Subtitles scroll smoothly line-by-line. White pointer moves forward. Viewport "pushes" only when necessary to keep white pointer visible. |
| BM-M-02 | Independent Yellow Cursor | Select a word (Yellow highlight). Use `d` to seek. | Video seeks forward. White pointer moves. Yellow cursor stays stationary on its original word (or is dismissed if seek logic dictates). |
| BM-M-03 | Rapid Seek Stability | Hold `d` for 5 seconds. | Video seeks rapidly without stutter. Viewport moves smoothly. No "fighting" or snapping back to player position. |

## 3. Regular Mode: Selection Behavior

| ID | Case | Action | Expected Result |
|----|------|--------|-----------------|
| RM-S-01 | Selection Following | Book Mode OFF. Play video. | Yellow line highlight follows the active playback line automatically. |
| RM-S-02 | Word Focus Reset | Select a word in Regular Mode. Let video play to next subtitle. | Yellow focus moves to next line, but the **word highlight is cleared** (resets to -1). |
| RM-S-03 | Manual Seek Dismissal | Select a word. Press `d`. | Video seeks. Yellow word focus is immediately dismissed. |

## 4. Stability & Regressions

| ID | Case | Action | Expected Result |
|----|------|--------|-----------------|
| ST-01 | ESC Dismissal | Active selection range. Press `Esc`. | Selection is dismissed. View remains stable. |
| ST-02 | Multi-Line Anchoring | Shift+Down to select multiple lines. Press `d`. | Selection range is preserved (or dismissed as per spec). View scrolls. |
| ST-03 | Crash Prevention | Spam `a`/`d` keys rapidly. | No Lua errors in console. No "nil value" crashes. |
| ST-04 | Initialization Stability | Open Drum Window (`w`) from various states (paused, playing, no subs). | Window opens reliably every time. No "attempt to call global (a nil value)" errors. |
