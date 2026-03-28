#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
#  Claude Code Sound Notifications — Uninstall
# ─────────────────────────────────────────────

SETTINGS_FILE="$HOME/.claude/settings.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "${CYAN}${BOLD}  Claude Code Sound Notifications — Uninstall${NC}"
echo -e "${DIM}  ──────────────────────────────────────────────${NC}"
echo ""

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo -e "${DIM}  No settings.json found. Nothing to remove.${NC}"
  exit 0
fi

if ! grep -q '"Stop"' "$SETTINGS_FILE" 2>/dev/null; then
  echo -e "${DIM}  No Stop hook found in settings. Nothing to remove.${NC}"
  exit 0
fi

cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"

python3 -c "
import json

with open('$SETTINGS_FILE', 'r') as f:
    settings = json.load(f)

if 'hooks' in settings and 'Stop' in settings['hooks']:
    del settings['hooks']['Stop']
    if not settings['hooks']:
        del settings['hooks']

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
"

echo -e "${GREEN}${BOLD}  Removed!${NC}"
echo -e "${DIM}  Stop hook removed from settings.json${NC}"
echo -e "${DIM}  Backup saved: $SETTINGS_FILE.backup${NC}"
echo ""
