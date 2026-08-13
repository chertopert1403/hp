#!/usr/bin/env python3
"""
Scrape shahvani.com/dastans, extract story URLs from the second panel-body,
create a text file, and push to GitHub daily_stories folder.
"""

import os
import sys
import subprocess
import glob

# Ensure dependencies are installed
subprocess.run([sys.executable, "-m", "pip", "install", "--quiet", "beautifulsoup4", "python-docx", "requests"],
               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

import requests
from bs4 import BeautifulSoup
from datetime import datetime

BASE_URL = "https://shahvani.com"
LIST_URL = f"{BASE_URL}/dastans"
REPO_DIR = "/tmp/hermes-backup-git"
GITHUB_USER = "chertopert1981"
GITHUB_REPO = "chertopert1981/hermes-backup"
GITHUB_PAT = "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"
GIT_REPO_URL = f"https://{GITHUB_USER}:{GITHUB_PAT}@github.com/{GITHUB_REPO}.git"

def main():
    date_str = datetime.now().strftime("%Y%m%d")
    filename = f"stories_{date_str}.txt"

    # 1. Scrape
    print(f"\U0001f4e5 Fetching {LIST_URL}...")
    resp = requests.get(LIST_URL, headers={"User-Agent": "Mozilla/5.0"}, timeout=30)
    soup = BeautifulSoup(resp.text, "html.parser")

    panel_bodies = soup.select("div.panel-body")
    if len(panel_bodies) < 2:
        print("\u274c Error: Could not find second panel-body.")
        return 1

    target_body = panel_bodies[1]

    links = []
    for a in target_body.select("td a[href^='/dastan/']"):
        links.append(f"{BASE_URL}{a.get('href')}")

    if not links:
        print("\u26a0\ufe0f No links found in second panel-body.")
        return 1

    # 2. Save to file
    with open(filename, "w") as f:
        for link in links:
            f.write(link + "\n")
    print(f"\u2705 Extracted {len(links)} links to {filename}")

    # 3. Git: clean local changes, then pull
    if os.path.exists(REPO_DIR):
        # Remove local daily_stories files to avoid conflicts
        for path in glob.glob(f"{REPO_DIR}/daily_stories/stories_*"):
            try:
                os.remove(path)
            except Exception:
                pass
        # Also remove any .txt in scripts/ from previous runs
        for path in glob.glob(f"{REPO_DIR}/scripts/stories_*"):
            try:
                os.remove(path)
            except Exception:
                pass
        subprocess.run(["git", "-C", REPO_DIR, "checkout", "--", "daily_stories/"], check=False)
        subprocess.run(["git", "-C", REPO_DIR, "clean", "-fd", "daily_stories/"], check=False)
        subprocess.run(["git", "-C", REPO_DIR, "pull", "--rebase"], check=True)
    else:
        subprocess.run(["git", "clone", "--quiet", GIT_REPO_URL, REPO_DIR], check=True)
        subprocess.run(["git", "-C", REPO_DIR, "checkout", "main"], check=True)

    os.makedirs(f"{REPO_DIR}/daily_stories", exist_ok=True)
    import shutil
    shutil.copy(filename, f"{REPO_DIR}/daily_stories/{filename}")

    # Check if file already exists in git
    result = subprocess.run(["git", "-C", REPO_DIR, "ls-files", f"daily_stories/{filename}"], capture_output=True, text=True)
    if not result.stdout.strip():
        subprocess.run(["git", "-C", REPO_DIR, "add", f"daily_stories/{filename}"], check=True)
        subprocess.run(["git", "-C", REPO_DIR, "commit", "-m", f"Daily stories {date_str}"], check=True)
        subprocess.run(["git", "-C", REPO_DIR, "push", "--quiet"], check=True)
        print("\u2705 Pushed to GitHub daily_stories/")
    else:
        print(f"\u2139 File {filename} already exists in repository, skipping commit/push")

if __name__ == "__main__":
    main()
