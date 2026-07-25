#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
#  Claude Code Sound Notifications — Installer
# ─────────────────────────────────────────────

SETTINGS_FILE="$HOME/.claude/settings.json"
BACKUP_FILE="$HOME/.claude/settings.json.backup"
HOOK_MARKER="# claude-code-sound-notifications"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

if ! command -v python3 &>/dev/null; then
  echo -e "${RED}  python3 is required but not found.${NC}"
  exit 1
fi

if [[ "$OS" == "linux" ]]; then
  if ! command -v notify-send &>/dev/null; then
    echo -e "${YELLOW}  Warning: notify-send not found. Install libnotify.${NC}"
    echo -e "${DIM}  Ubuntu/Debian: sudo apt install libnotify-bin${NC}"
    echo -e "${DIM}  Arch: sudo pacman -S libnotify${NC}"
    exit 1
  fi
fi

# ── Sound selection ──

SOUND="Glass"
HAS_PAPLAY="false"

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

  # Preview sound
  echo ""
  echo -e "${DIM}  Previewing sound...${NC}"
  osascript -e "display notification \"This is your Claude Code notification\" with title \"Claude Code\" sound name \"$SOUND\""

else
  SOUND="default"
  if command -v paplay &>/dev/null; then
    HAS_PAPLAY="true"
  fi
  echo -e "  ${DIM}Using system notification sound${NC}"
fi

echo -e "  ${GREEN}Sound: ${BOLD}$SOUND${NC}"

# ── Check for existing settings ──

if [[ ! -d "$HOME/.claude" ]]; then
  mkdir -p "$HOME/.claude"
fi

HAD_SETTINGS="false"
if [[ -f "$SETTINGS_FILE" ]]; then
  HAD_SETTINGS="true"
fi

# ── Write settings using Python (handles all escaping correctly) ──

export CCNOTIF_SETTINGS_FILE="$SETTINGS_FILE"
export CCNOTIF_OS="$OS"
export CCNOTIF_SOUND="$SOUND"
export CCNOTIF_HAS_PAPLAY="$HAS_PAPLAY"
export CCNOTIF_BACKUP_FILE="$BACKUP_FILE"
export CCNOTIF_HOOK_MARKER="$HOOK_MARKER"

python3 << 'PYEOF'
import json
import os
import shutil
import tempfile

settings_file = os.environ["CCNOTIF_SETTINGS_FILE"]
backup_file = os.environ["CCNOTIF_BACKUP_FILE"]
detected_os = os.environ["CCNOTIF_OS"]
sound = os.environ["CCNOTIF_SOUND"]
has_paplay = os.environ["CCNOTIF_HAS_PAPLAY"] == "true"
hook_marker = os.environ["CCNOTIF_HOOK_MARKER"]

legacy_linux_commands = {
    "notify-send 'Claude Code' 'Claude Code finished' --urgency=normal",
    "notify-send 'Claude Code' 'Claude Code finished' --urgency=normal && "
    "paplay /usr/share/sounds/freedesktop/stereo/complete.oga",
}


def is_legacy_macos_command(command):
    prefix = "osascript -e 'display notification \"Claude Code finished\" "
    sound_prefix = "with title \"Claude Code\" sound name \""
    return (
        command.startswith(prefix + sound_prefix)
        and command.endswith("\"'")
        and len(command) > len(prefix + sound_prefix) + 2
        and "\"" not in command[len(prefix + sound_prefix):-2]
    )


def is_owned_entry(entry):
    if not isinstance(entry, dict) or entry.get("matcher") != "":
        return False
    hooks = entry.get("hooks")
    if not isinstance(hooks, list) or len(hooks) != 1:
        return False
    hook = hooks[0]
    if not isinstance(hook, dict) or hook.get("type") != "command":
        return False
    command = hook.get("command")
    if not isinstance(command, str):
        return False
    if hook_marker in command:
        return True
    if set(entry) != {"matcher", "hooks"} or set(hook) != {"type", "command"}:
        return False
    return command in legacy_linux_commands or is_legacy_macos_command(command)


def write_atomically(path, value):
    directory = os.path.dirname(path)
    file_descriptor, temporary_path = tempfile.mkstemp(
        dir=directory, prefix="settings.json.", suffix=".tmp"
    )
    try:
        with os.fdopen(file_descriptor, "w") as temporary_file:
            json.dump(value, temporary_file, indent=2)
            temporary_file.write("\n")
        os.replace(temporary_path, path)
    except BaseException:
        try:
            os.unlink(temporary_path)
        except FileNotFoundError:
            pass
        raise

# Build the command based on OS
if detected_os == "macos":
    hook_command = (
        f"osascript -e 'display notification \"Claude Code finished\" "
        f"with title \"Claude Code\" sound name \"{sound}\"'"
    )
else:
    hook_command = "notify-send 'Claude Code' 'Claude Code finished' --urgency=normal"
    if has_paplay:
        hook_command += " && paplay /usr/share/sounds/freedesktop/stereo/complete.oga"
hook_command += f" {hook_marker}"

# Load existing settings or start fresh
if os.path.exists(settings_file):
    try:
        with open(settings_file, "r") as settings_handle:
            settings = json.load(settings_handle)
    except (OSError, json.JSONDecodeError) as error:
        raise SystemExit(f"Cannot safely update invalid settings JSON: {error}")
else:
    settings = {}

if not isinstance(settings, dict):
    raise SystemExit("Cannot safely update settings JSON: root must be an object")

hooks = settings.setdefault("hooks", {})
if not isinstance(hooks, dict):
    raise SystemExit("Cannot safely update settings JSON: hooks must be an object")

stop_hooks = hooks.setdefault("Stop", [])
if not isinstance(stop_hooks, list):
    raise SystemExit("Cannot safely update settings JSON: hooks.Stop must be an array")

stop_hooks[:] = [entry for entry in stop_hooks if not is_owned_entry(entry)]
stop_hooks.append({
    "matcher": "",
    "hooks": [{"type": "command", "command": hook_command}],
})

if os.path.exists(settings_file):
    shutil.copy2(settings_file, backup_file)

write_atomically(settings_file, settings)
PYEOF

if [[ "$HAD_SETTINGS" == "true" ]]; then
  echo -e "${DIM}  Backup saved: $BACKUP_FILE${NC}"
fi

# ── Done ──

echo ""
echo -e "${GREEN}${BOLD}  Done!${NC}"
echo ""
echo -e "  ${DIM}Restart Claude Code to activate notifications.${NC}"
echo -e "  ${DIM}Run /hooks inside Claude Code to verify.${NC}"
echo ""
