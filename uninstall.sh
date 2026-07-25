#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
#  Claude Code Sound Notifications — Uninstall
# ─────────────────────────────────────────────

SETTINGS_FILE="$HOME/.claude/settings.json"
BACKUP_FILE="$HOME/.claude/settings.json.backup"
HOOK_MARKER="# claude-code-sound-notifications"

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

export CCNOTIF_SETTINGS_FILE="$SETTINGS_FILE"
export CCNOTIF_BACKUP_FILE="$BACKUP_FILE"
export CCNOTIF_HOOK_MARKER="$HOOK_MARKER"

removal_result="$(python3 << 'PYEOF'
import json
import os
import shutil
import tempfile

settings_file = os.environ["CCNOTIF_SETTINGS_FILE"]
backup_file = os.environ["CCNOTIF_BACKUP_FILE"]
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

try:
    with open(settings_file, "r") as settings_handle:
        settings = json.load(settings_handle)
except (OSError, json.JSONDecodeError) as error:
    raise SystemExit(f"Cannot safely update invalid settings JSON: {error}")

if not isinstance(settings, dict):
    raise SystemExit("Cannot safely update settings JSON: root must be an object")

hooks = settings.get("hooks")
if hooks is None:
    print("not-found")
    raise SystemExit(0)
if not isinstance(hooks, dict):
    raise SystemExit("Cannot safely update settings JSON: hooks must be an object")

stop_hooks = hooks.get("Stop")
if stop_hooks is None:
    print("not-found")
    raise SystemExit(0)
if not isinstance(stop_hooks, list):
    raise SystemExit("Cannot safely update settings JSON: hooks.Stop must be an array")

remaining_hooks = [entry for entry in stop_hooks if not is_owned_entry(entry)]
if len(remaining_hooks) == len(stop_hooks):
    print("not-found")
    raise SystemExit(0)

if remaining_hooks:
    hooks["Stop"] = remaining_hooks
else:
    del hooks["Stop"]
    if not hooks:
        del settings["hooks"]

shutil.copy2(settings_file, backup_file)
write_atomically(settings_file, settings)
print("removed")
PYEOF
)"

if [[ "$removal_result" == "not-found" ]]; then
  echo -e "${DIM}  No Claude Code Sound Notifications hook found. Nothing to remove.${NC}"
  exit 0
fi

echo -e "${GREEN}${BOLD}  Removed!${NC}"
echo -e "${DIM}  Notification hook removed from settings.json${NC}"
echo -e "${DIM}  Backup saved: $BACKUP_FILE${NC}"
echo ""
