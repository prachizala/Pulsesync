# Changes Log - PulseSync

## Overview
This log documents repository hygiene updates performed on branch `review-fixes`.

## Changes Made
1. **Repository Hygiene & `.gitignore` Updates**:
   - Inspected repository for tracked `.db` or SQLite files (`git ls-files`). Verified neither `backend/pulsesync.db` nor `backend/test_pulsesync.db` was committed into git tracking.
   - Updated `.gitignore` to ensure comprehensive database exclusion: explicitly added `*.sqlite` to accompany `*.sqlite3` and `*.db`.
2. **License**:
   - Added standard `LICENSE` (MIT License, Copyright (c) 2026 Prachi Zala).
3. **Verification**:
   - Executed existing backend unit test suite (`pytest tests/` in backend virtual environment):
     - Result: 8 passed, 0 failed.

## Manual Steps / History Cleanup (Optional)
If any previous branches or forks contain committed `.db` files that need to be completely purged from history:
```bash
# Using git filter-repo (recommended tool for history purging)
pip install git-filter-repo
git filter-repo --path backend/test_pulsesync.db --invert-paths
```
*Note: Rewriting git history is destructive. Ensure backups are made before running history rewrites.*
