#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

FAKE_BIN="$TEST_ROOT/bin"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/notify-send" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$FAKE_BIN/notify-send"

run_install() {
  local home_dir="$1"
  printf '\n' | HOME="$home_dir" PATH="$FAKE_BIN:$PATH" bash "$REPO_ROOT/install.sh" >/dev/null
}

run_uninstall() {
  local home_dir="$1"
  HOME="$home_dir" PATH="$FAKE_BIN:$PATH" bash "$REPO_ROOT/uninstall.sh" >/dev/null
}

assert_json() {
  local settings_file="$1"
  local assertion="$2"
  python3 - "$settings_file" "$assertion" <<'PYEOF'
import json
import sys

settings_file, assertion = sys.argv[1:]
with open(settings_file, "r") as settings_handle:
    settings = json.load(settings_handle)
exec(assertion, {"settings": settings})
PYEOF
}

test_install_preserves_and_is_idempotent() {
  local home_dir="$TEST_ROOT/install"
  local settings_file="$home_dir/.claude/settings.json"
  mkdir -p "$home_dir/.claude"
  cat > "$settings_file" <<'EOF'
{
  "theme": "dark",
  "hooks": {
    "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "pre-tool"}]}],
    "Stop": [
      {"matcher": "unrelated", "hooks": [{"type": "command", "command": "other-tool --flag"}], "extra": {"keep": [1, 2]}},
      {"matcher": "", "hooks": [{"type": "command", "command": "osascript -e 'display notification \"Claude Code finished\" with title \"Claude Code\" sound name \"Ping\"'"}]},
      {"matcher": "", "hooks": [{"type": "command", "command": "notify-send old # claude-code-sound-notifications"}]}
    ]
  }
}
EOF
  cp "$settings_file" "$TEST_ROOT/original.json"

  run_install "$home_dir"
  cmp "$TEST_ROOT/original.json" "$settings_file.backup"
  assert_json "$settings_file" '
stop = settings["hooks"]["Stop"]
assert settings["theme"] == "dark"
assert settings["hooks"]["PreToolUse"] == [{"matcher": "Bash", "hooks": [{"type": "command", "command": "pre-tool"}]}]
assert stop[0] == {"matcher": "unrelated", "hooks": [{"type": "command", "command": "other-tool --flag"}], "extra": {"keep": [1, 2]}}
owned = [entry for entry in stop if "# claude-code-sound-notifications" in entry["hooks"][0]["command"]]
assert len(owned) == 1
assert len(stop) == 2
'
  cp "$settings_file" "$TEST_ROOT/after-first-install.json"

  run_install "$home_dir"
  cmp "$TEST_ROOT/after-first-install.json" "$settings_file"
  assert_json "$settings_file" '
stop = settings["hooks"]["Stop"]
assert len([entry for entry in stop if "# claude-code-sound-notifications" in entry["hooks"][0]["command"]]) == 1
assert stop[0]["extra"] == {"keep": [1, 2]}
'
}

test_uninstall_removes_only_owned_entries() {
  local home_dir="$TEST_ROOT/uninstall"
  local settings_file="$home_dir/.claude/settings.json"
  mkdir -p "$home_dir/.claude"
  cat > "$settings_file" <<'EOF'
{
  "hooks": {
    "Stop": [
      {"matcher": "", "hooks": [{"type": "command", "command": "other notification"}]},
      {"matcher": "", "hooks": [{"type": "command", "command": "notify-send 'Claude Code' 'Claude Code finished' --urgency=normal # claude-code-sound-notifications"}]}
    ],
    "SessionStart": [{"matcher": "", "hooks": [{"type": "command", "command": "session-tool"}]}]
  },
  "custom": true
}
EOF
  cp "$settings_file" "$TEST_ROOT/pre-uninstall.json"

  run_uninstall "$home_dir"
  cmp "$TEST_ROOT/pre-uninstall.json" "$settings_file.backup"
  assert_json "$settings_file" '
assert settings["custom"] is True
assert settings["hooks"]["SessionStart"] == [{"matcher": "", "hooks": [{"type": "command", "command": "session-tool"}]}]
assert settings["hooks"]["Stop"] == [{"matcher": "", "hooks": [{"type": "command", "command": "other notification"}]}]
'
}

test_uninstall_removes_legacy_linux_and_macos() {
  local home_dir="$TEST_ROOT/legacy-uninstall"
  local settings_file="$home_dir/.claude/settings.json"
  mkdir -p "$home_dir/.claude"
  cat > "$settings_file" <<'EOF'
{
  "hooks": {
    "Stop": [
      {"matcher": "keep", "hooks": [{"type": "command", "command": "keep-me"}]},
      {"matcher": "", "hooks": [{"type": "command", "command": "notify-send 'Claude Code' 'Claude Code finished' --urgency=normal && paplay /usr/share/sounds/freedesktop/stereo/complete.oga"}]},
      {"matcher": "", "hooks": [{"type": "command", "command": "osascript -e 'display notification \"Claude Code finished\" with title \"Claude Code\" sound name \"Glass\"'"}]}
    ]
  }
}
EOF

  run_uninstall "$home_dir"
  assert_json "$settings_file" '
assert settings["hooks"]["Stop"] == [{"matcher": "keep", "hooks": [{"type": "command", "command": "keep-me"}]}]
'
}

test_invalid_json_is_never_overwritten() {
  local script home_dir settings_file
  for script in install uninstall; do
    home_dir="$TEST_ROOT/invalid-$script"
    settings_file="$home_dir/.claude/settings.json"
    mkdir -p "$home_dir/.claude"
    printf '{ invalid json\n' > "$settings_file"
    cp "$settings_file" "$TEST_ROOT/invalid-$script-original"

    if [[ "$script" == "install" ]]; then
      if run_install "$home_dir" 2>/dev/null; then
        echo "install unexpectedly accepted invalid JSON" >&2
        return 1
      fi
    else
      if run_uninstall "$home_dir" 2>/dev/null; then
        echo "uninstall unexpectedly accepted invalid JSON" >&2
        return 1
      fi
    fi

    cmp "$TEST_ROOT/invalid-$script-original" "$settings_file"
    [[ ! -e "$settings_file.backup" ]]
  done
}

test_install_preserves_and_is_idempotent
test_uninstall_removes_only_owned_entries
test_uninstall_removes_legacy_linux_and_macos
test_invalid_json_is_never_overwritten

echo "All installer safety tests passed."
