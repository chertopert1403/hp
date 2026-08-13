#!/bin/bash
# Hermes backup script - backs up critical data to GitHub (secrets safe)
set -e

REPO_DIR="/tmp/hermes-hermes-backup"
REPO_URL="https://chertopert1981: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@github.com/chertopert1981/hermes-backup.git"
HERMES_DIR="/data/.hermes"
TIMESTAMP=$(date --utc +"%Y%m%d_%H%M%S_UTC")
BACKUP_DIR="backup_${TIMESTAMP}"

# Clean up any previous clone
rm -rf "$REPO_DIR"

# Clone the repo
git clone --quiet "$REPO_DIR" 2>&1 || git clone --quiet "$REPO_URL" "$REPO_DIR" 2>&1
cd "$REPO_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# === CRITICAL FILES (no secrets) ===

# 1. Memories (durable facts - user profile + agent notes)
if [ -d "$HERMES_DIR/memories" ] && [ "$(ls -A $HERMES_DIR/memories 2>/dev/null)" ]; then
    cp -r "$HERMES_DIR/memories" "$BACKUP_DIR/"
    echo "  ✓ memories/"
fi

# 2. Skills (reusable procedures)
if [ -d "$HERMES_DIR/skills" ]; then
    mkdir -p "$BACKUP_DIR/skills"
    find "$HERMES_DIR/skills" -name "SKILL.md" | while read f; do
        rel_path="${f#$HERMES_DIR/}"
        mkdir -p "$BACKUP_DIR/$(dirname "$rel_path")"
        cp "$f" "$BACKUP_DIR/$(dirname "$rel_path")/"
    done
    echo "  ✓ skills/ (SKILL.md files)"
fi

# 3. Config (safe - tiny, no secrets)
cp "$HERMES_DIR/config.yaml" "$BACKUP_DIR/" && echo "  ✓ config.yaml"

# 4. SOUL.md (system prompt)
cp "$HERMES_DIR/SOUL.md" "$BACKUP_DIR/" && echo "  ✓ SOUL.md"

# 5. Cron executions DB (master schedule - small, no tokens)
if [ -f "$HERMES_DIR/cron/executions.db" ]; then
    cp "$HERMES_DIR/cron/executions.db" "$BACKUP_DIR/" && echo "  ✓ cron/executions.db"
fi
if [ -d "$HERMES_DIR/cron/output" ] && [ "$(ls -A $HERMES_DIR/cron/output 2>/dev/null)" ]; then
    cp -r "$HERMES_DIR/cron/output" "$BACKUP_DIR/cron_output" && echo "  ✓ cron/output/"
fi

# 6. Gateway state (safe)
if [ -f "$HERMES_DIR/gateway_state.json" ]; then
    cp "$HERMES_DIR/gateway_state.json" "$BACKUP_DIR/" && echo "  ✓ gateway_state.json"
fi

# 7. Channel directory (safe - user-readable)
if [ -f "$HERMES_DIR/channel_directory.json" ]; then
    cp "$HERMES_DIR/channel_directory.json" "$BACKUP_DIR/" && echo "  ✓ channel_directory.json"
fi

# 8. Kanban DB (task board - safe)
if [ -f "$HERMES_DIR/kanban.db" ]; then
    cp "$HERMES_DIR/kanban.db" "$BACKUP_DIR/" && echo "  ✓ kanban.db"
fi

# 9. Provider models cache (safe)
if [ -f "$HERMES_DIR/provider_models_cache.json" ]; then
    cp "$HERMES_DIR/provider_models_cache.json" "$BACKUP_DIR/" && echo "  ✓ provider_models_cache.json"
fi

# 10. Skills prompt snapshot
if [ -f "$HERMES_DIR/.skills_prompt_snapshot.json" ]; then
    cp "$HERMES_DIR/.skills_prompt_snapshot.json" "$BACKUP_DIR/" && echo "  ✓ .skills_prompt_snapshot.json"
fi

# 11. Auth config (structure only - secrets redacted)
if [ -f "$HERMES_DIR/auth.json" ]; then
    python3 -c "
import json
with open('$HERMES_DIR/auth.json') as f:
    d = json.load(f)
if 'credential_pool' in d:
    for k in d['credential_pool']:
        d['credential_pool'][k] = ['**REDACTED**']
if 'providers' in d:
    d['providers'] = '**REDACTED**'
with open('$BACKUP_DIR/auth.json', 'w') as f:
    json.dump(d, f, indent=2)
" && echo "  ✓ auth.json (secrets redacted)"
fi

# 12. Sessions metadata (not full logs)
if [ -d "$HERMES_DIR/sessions" ] && [ "$(ls -A $HERMES_DIR/sessions 2>/dev/null)" ]; then
    cp "$HERMES_DIR/sessions"/*.json "$BACKUP_DIR/sessions/" 2>/dev/null && echo "  ✓ sessions/ (metadata)"
fi

# === NOT backed up (contain secrets or too large) ===
# - state.db       (SQLite DB - contains PAT tokens from sessions)
# - models_dev_cache.json  (too large, regeneratable)
# - kanban.db.*.lock       (lock files)
# - gateway.pid / gateway.lock  (runtime state)

# === Write a manifest ===
cat > "$BACKUP_DIR/MANIFEST.md" << EOF
# Hermes Backup - $TIMESTAMP

## Contents
$(for f in "$BACKUP_DIR"/*; do echo "- $(basename "$f") ($(du -sh "$f" 2>/dev/null | cut -f1))"; done 2>/dev/null)

## Skills included
$(find "$BACKUP_DIR/skills" -name "SKILL.md" 2>/dev/null | sed 's|.*skills/|  - skills/|' | sed 's|/SKILL.md||')

## Excluded (secrets or regeneratable)
- state.db (contains session PAT tokens)
- models_dev_cache.json (3.2MB, regeneratable)
- Runtime files (pid, lock, heartbeat)

## Notes
- Auth tokens are REDACTED in auth.json
- Full session binary logs are NOT backed up
EOF

echo "  ✓ MANIFEST.md"

# === Commit & Push ===
git add -A
git commit -m "Backup $TIMESTAMP" --quiet
git push --quiet 2>&1

# Cleanup
cd /
rm -rf "$REPO_DIR"

echo ""
echo "✅ Backup complete: $TIMESTAMP pushed to GitHub"