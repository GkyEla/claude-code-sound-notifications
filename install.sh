#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
#  Claude Code Sound Notifications — Installer
# ─────────────────────────────────────────────

SETTINGS_FILE="$HOME/.claude/settings.json"
BACKUP_FILE="$HOME/.claude/settings.json.backup"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "${CYAN}${BOLD}  Claude Code Sound Notifications${NC}"
echo -e "${DIM}  ─────────────────────────────────${NC}"
echo ""

# ── Detect OS ──

OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS="linux"
fi

if [[ "$OS" == "unknown" ]]; then
  echo -e "${RED}  Unsupported OS: $OSTYPE${NC}"
  echo -e "${DIM}  Supported: macOS, Linux${NC}"
  exit 1
fi

echo -e "${DIM}  OS detected:${NC} ${BOLD}$OS${NC}"

# ── Check dependencies ──

if [[ "$OS" == "linux" ]]; then
  if ! command -v notify-send &>/dev/null; then
    echo -e "${YELLOW}  Warning: notify-send not found. Install libnotify.${NC}"
    echo -e "${DIM}  Ubuntu/Debian: sudo apt install libnotify-bin${NC}"
    echo -e "${DIM}  Arch: sudo pacman -S libnotify${NC}"
    exit 1
  fi
fi

# ── Sound selection ──

echo ""
echo -e "${BOLD}  Choose a sound profile:${NC}"
echo ""

if [[ "$OS" == "macos" ]]; then
  echo -e "  ${CYAN}1)${NC} Glass      ${DIM}— clean, subtle (default)${NC}"
  echo -e "  ${CYAN}2)${NC} Ping       ${DIM}— classic notification${NC}"
  echo -e "  ${CYAN}3)${NC} Pop        ${DIM}— quick, light${NC}"
  echo -e "  ${CYAN}4)${NC} Hero       ${DIM}— bold, triumphant${NC}"
  echo -e "  ${CYAN}5)${NC} Purr       ${DIM}— soft, gentle${NC}"
  echo -e "  ${CYAN}6)${NC} Submarine  ${DIM}— deep, distinct${NC}"
  echo -e "  ${CYAN}7)${NC} Frog       ${DIM}— fun, unmissable${NC}"
  echo -e "  ${CYAN}8)${NC} Sosumi     ${DIM}— the OG Mac sound${NC}"
  echo -e "  ${CYAN}9)${NC} Tink       ${DIM}— minimal, delicate${NC}"
  echo ""
  echo -ne "  ${BOLD}Pick a number [1]: ${NC}"
  read -r choice

  case "${choice:-1}" in
    1) SOUND="Glass" ;;
    2) SOUND="Ping" ;;
    3) SOUND="Pop" ;;
    4) SOUND="Hero" ;;
    5) SOUND="Purr" ;;
    6) SOUND="Submarine" ;;
    7) SOUND="Frog" ;;
    8) SOUND="Sosumi" ;;
    9) SOUND="Tink" ;;
    *) SOUND="Glass" ;;
  esac

  HOOK_COMMAND="osascript -e 'display notification \"Claude Code finished\" with title \"Claude Code\" sound name \"$SOUND\"'"

  # Preview sound
  echo ""
  echo -e "${DIM}  Previewing sound...${NC}"
  osascript -e "display notification \"This is your Claude Code notification\" with title \"Claude Code\" sound name \"$SOUND\""

else
  SOUND="default"
  if command -v paplay &>/dev/null; then
    HOOK_COMMAND="notify-send 'Claude Code' 'Claude Code finished' --urgency=normal && paplay /usr/share/sounds/freedesktop/stereo/complete.oga"
  else
    HOOK_COMMAND="notify-send 'Claude Code' 'Claude Code finished' --urgency=normal"
  fi
fi

echo -e "  ${GREEN}Sound: ${BOLD}$SOUND${NC}"

# ── Build hook JSON ──

HOOK_JSON=$(cat <<ENDJSON
{
  "Stop": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "$HOOK_COMMAND"
        }
      ]
    }
  ]
}
ENDJSON
)

# ── Check for existing settings ──

if [[ ! -d "$HOME/.claude" ]]; then
  mkdir -p "$HOME/.claude"
fi

if [[ -f "$SETTINGS_FILE" ]]; then
  # Check if hooks already exist
  if grep -q '"Stop"' "$SETTINGS_FILE" 2>/dev/null; then
    echo ""
    echo -e "${YELLOW}  Stop hook already exists in settings.json${NC}"
    echo -ne "  ${BOLD}Overwrite? [y/N]: ${NC}"
    read -r overwrite
    if [[ "${overwrite}" != "y" && "${overwrite}" != "Y" ]]; then
      echo -e "${DIM}  Aborted.${NC}"
      exit 0
    fi
  fi

  # Backup
  cp "$SETTINGS_FILE" "$BACKUP_FILE"
  echo -e "${DIM}  Backup saved: $BACKUP_FILE${NC}"

  # Merge hooks into existing settings using python (available on macOS and most Linux)
  python3 -c "
import json, sys

with open('$SETTINGS_FILE', 'r') as f:
    settings = json.load(f)

hook = json.loads('''$HOOK_JSON''')

if 'hooks' not in settings:
    settings['hooks'] = {}

settings['hooks']['Stop'] = hook['Stop']

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
"

else
  # Create new settings file
  python3 -c "
import json

settings = {'hooks': json.loads('''$HOOK_JSON''')}

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
"
fi

# ── Done ──

echo ""
echo -e "${GREEN}${BOLD}  Done!${NC}"
echo ""
echo -e "  ${DIM}Restart Claude Code to activate notifications.${NC}"
echo -e "  ${DIM}Run /hooks inside Claude Code to verify.${NC}"
echo ""
