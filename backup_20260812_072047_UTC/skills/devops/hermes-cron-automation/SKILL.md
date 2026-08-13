---
name: hermes-cron-automation
description: Manage Hermes cron jobs for backups, scraping, reminders.
---

# Hermes Cron Job Automation

## Overview
Hermes cron jobs are managed via the `cronjob` tool. Jobs run in isolated sessions with no chat context. They execute scripts located in `~/.hermes/scripts/`.

## Key Patterns

### Creating a Cron Job
```
cronjob(action="create", name="<name>", schedule="<cron>", script="<filename.sh or .py>", no_agent=true)
```
- `schedule` format: `every 12h`, `0 8 * * *` (cron expression), or ISO timestamp
- `script` must be a **relative filename** (e.g., `backup-hermes-full.sh`), located in `~/.hermes/scripts/`
- `no_agent=true` for script-only jobs (no LLM reasoning needed)
- `deliver="origin"` sends output back to the originating chat

### Common Pitfalls
1. **Script path must be relative** — never use absolute paths in the `script` field
2. **Environment variables** — cron jobs run in isolated sessions. Do NOT rely on `.env` variables being loaded. Hardcode credentials or use `export` at the top of the script
3. **Git authentication** — hardcode PAT in scripts (not in `.env` that cron may not load). Use `https://user:pat@github.com/repo.git` format
4. **Python dependencies** — cron sessions may not have the same venv. Add `subprocess.run([sys.executable, "-m", "pip", "install", "--quiet", "bs4", "python-docx", "requests"])` at the top of Python scripts
5. **Git push conflicts** — always `git pull --rebase` before pushing in cron scripts
6. **Duplicate commits** — check if file already exists in git before committing (`git ls-files`)
7. **Git pull fails with unstaged changes** — if a script creates local files in the repo dir (e.g., `stories_YYYYMMDD.txt`) before `git pull --rebase`, the pull will fail with "You have unstaged changes". **Fix:** before `git pull`, clean local changes:
   ```python
   import glob
   for path in glob.glob(f"{REPO_DIR}/daily_stories/stories_*"):
       try: os.remove(path)
       except: pass
   subprocess.run(["git", "-C", REPO_DIR, "checkout", "--", "daily_stories/"], check=False)
   subprocess.run(["git", "-C", REPO_DIR, "clean", "-fd", "daily_stories/"], check=False)
   subprocess.run(["git", "-C", REPO_DIR, "pull", "--rebase"], check=True)
   ```
8. **Script creates file THEN tries git pull** — the link scraper writes `stories_YYYYMMDD.txt` locally first, then clones/pulls the repo. If the repo already exists, the local file conflicts with pull. Move the scrape AFTER the git pull, or clean before pull.

### Fixing Cron Job Failures
1. Check `last_status` and `last_error` via `cronjob(action="list")`
2. Test the script manually: `bash ~/.hermes/scripts/<script>.sh` or `python3 ~/.hermes/scripts/<script>.py`
3. Verify `.env` variables are loaded: `source ~/.hermes/.env && env | grep VAR_NAME`
4. For Python scripts, ensure `bs4`, `python-docx`, `requests` are installed in the cron environment

### Iran Time Conversion
- Iran (IRST) = UTC+3:30 (standard), UTC+4:30 (DST)
- 6:00 AM Iran = 02:30 UTC (standard) / 01:30 UTC (DST)
- 7:00 AM Iran = 03:30 UTC (standard) / 02:30 UTC (DST)
- 8:00 AM Iran = 04:30 UTC (standard) / 03:30 UTC (DST)
- 9:00 AM Iran = 05:30 UTC (standard) / 04:30 UTC (DST)

## Shahvani Scraper Pipeline (Iran Time)
1. **6:00 AM** → `scrape_shahvani_links.py`: Extract `/dastan/` links from second `div.panel-body` on `shahvani.com/dastans` → save `stories_YYYYMMDD.txt` → push to `daily_stories/` on GitHub
2. **7:00 AM** → `scrape_story_content.py`: Read `stories_YYYYMMDD.txt` → fetch each story → extract `div.panel-body` content (stop before `div#loginorregister`) → create Word doc `stories_YYYYMMDD.docx` → push to `daily_stories/` on GitHub