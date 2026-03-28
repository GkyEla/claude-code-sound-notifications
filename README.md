<div align="center">

# 🔔 Claude Code Sound Notifications

**Never miss when Claude finishes. Get sound + banner notifications on any terminal.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS | Linux](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey.svg)](#)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-2.x-blueviolet.svg)](https://claude.ai)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing)

<br>

**One command install · Works on every terminal · No dependencies**

[Quick Start](#quick-start) · [Manual Setup](#manual-setup) · [Sound Profiles](#sound-profiles) · [Troubleshooting](#troubleshooting)

</div>

---

## The Problem

Claude Code uses terminal escape sequences for notifications. **They don't work.**

| Terminal / Setup | Result |
|---|---|
| Ghostty (even with `desktop-notifications = true`) | ❌ Silent |
| Any terminal + Zellij or tmux | ❌ Multiplexer strips escape codes |
| Alacritty, Warp, VS Code, Terminal.app | ❌ No notification support |
| `skipDangerousModePermissionPrompt: true` | ❌ `Notification` event never fires |

> You leave to grab coffee. You come back. Claude finished 5 minutes ago. No sound. No banner. Nothing.

**This repo fixes that — permanently, on every terminal.**

---

## Quick Start

### One-line install

**macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/GkyEla/claude-code-sound-notifications/main/install.sh | bash
```

**Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/GkyEla/claude-code-sound-notifications/main/install.sh | bash
```

The installer will:
- Auto-detect your OS
- Let you pick a notification sound
- Preview the sound before applying
- Safely merge into your existing `settings.json` (with backup)

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/GkyEla/claude-code-sound-notifications/main/uninstall.sh | bash
```

---

## Manual Setup

Add the `hooks` block to `~/.claude/settings.json`:

<details>
<summary><b>macOS</b></summary>

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code finished\" with title \"Claude Code\" sound name \"Glass\"'"
          }
        ]
      }
    ]
  }
}
```

</details>

<details>
<summary><b>Linux</b></summary>

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Code' 'Claude Code finished' --urgency=normal"
          }
        ]
      }
    ]
  }
}
```

</details>

<details>
<summary><b>Linux (with sound)</b></summary>

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Code' 'Claude Code finished' --urgency=normal && paplay /usr/share/sounds/freedesktop/stereo/complete.oga"
          }
        ]
      }
    ]
  }
}
```

</details>

<details>
<summary><b>Full settings.json example</b></summary>

```json
{
  "alwaysThinkingEnabled": true,
  "effortLevel": "high",
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code finished\" with title \"Claude Code\" sound name \"Glass\"'"
          }
        ]
      }
    ]
  }
}
```

</details>

Restart Claude Code after saving. Run `/hooks` inside Claude Code to verify.

---

## Why `Stop` Instead of `Notification`?

Claude Code has a built-in `Notification` event — but it's broken for most users:

| Event | When It Fires | Reliability |
|---|---|---|
| `Notification` | Permission prompts, idle state, auth | ❌ Never fires with `skipDangerousModePermissionPrompt` |
| **`Stop`** | **Every time Claude finishes responding** | ✅ **Always fires** |

Most power users enable dangerous mode. If you do, the `Notification` event is completely dead.
**`Stop` is the only reliable event.**

---

## How It Works

```
  Claude Code finishes responding
              │
              ▼
       "Stop" hook fires
              │
              ▼
    osascript / notify-send
              │
              ▼
      OS Notification Center
              │
              ▼
       Sound + Banner 🔔
```

No terminal escape sequences. No dependency on Ghostty, Kitty, or any terminal feature.
Direct OS-level notification that **always works**.

---

## Sound Profiles

### macOS Built-in Sounds

| # | Sound | Vibe | Try it |
|---|---|---|---|
| 1 | **Glass** | Clean, subtle | `osascript -e 'display notification "test" with title "test" sound name "Glass"'` |
| 2 | **Ping** | Classic notification | `osascript -e 'display notification "test" with title "test" sound name "Ping"'` |
| 3 | **Pop** | Quick, light | `osascript -e 'display notification "test" with title "test" sound name "Pop"'` |
| 4 | **Hero** | Bold, triumphant | `osascript -e 'display notification "test" with title "test" sound name "Hero"'` |
| 5 | **Purr** | Soft, gentle | `osascript -e 'display notification "test" with title "test" sound name "Purr"'` |
| 6 | **Submarine** | Deep, distinct | `osascript -e 'display notification "test" with title "test" sound name "Submarine"'` |
| 7 | **Frog** | Fun, unmissable | `osascript -e 'display notification "test" with title "test" sound name "Frog"'` |
| 8 | **Sosumi** | The OG Mac sound | `osascript -e 'display notification "test" with title "test" sound name "Sosumi"'` |
| 9 | **Tink** | Minimal, delicate | `osascript -e 'display notification "test" with title "test" sound name "Tink"'` |

### Custom Sounds

Drop any `.aiff` file into `~/Library/Sounds/` and use its filename (without extension) as the sound name.

---

## Tested Terminals

| Terminal | Direct | + Zellij | + tmux |
|---|---|---|---|
| Ghostty | ✅ | ✅ | ✅ |
| Kitty | ✅ | ✅ | ✅ |
| iTerm2 | ✅ | ✅ | ✅ |
| Alacritty | ✅ | ✅ | ✅ |
| Warp | ✅ | ✅ | ✅ |
| macOS Terminal | ✅ | ✅ | ✅ |
| VS Code Terminal | ✅ | ✅ | ✅ |

**Works everywhere** — because it doesn't use the terminal for notifications.

---

## Troubleshooting

<details>
<summary><b>No sound or notification</b></summary>

1. **macOS:** Check System Settings → Notifications → Script Editor — make sure it's allowed
2. Make sure **Do Not Disturb / Focus** mode is off
3. Validate JSON: `python3 -m json.tool ~/.claude/settings.json`
4. Restart Claude Code after editing settings
5. Test manually:
   ```bash
   # macOS
   osascript -e 'display notification "Test" with title "Test" sound name "Glass"'

   # Linux
   notify-send "Test" "Test"
   ```

</details>

<details>
<summary><b>Hook not firing</b></summary>

1. Run `/hooks` inside Claude Code — verify `Stop` appears
2. Hooks must be inside `settings.json`, **not** a separate `hooks.json` file
3. Check for JSON syntax errors (trailing commas, missing brackets)

</details>

<details>
<summary><b>Want to change the sound</b></summary>

Re-run the installer or manually edit `~/.claude/settings.json` — replace the sound name in the `osascript` command.

</details>

---

## Contributing

Found a better approach? Support another OS? Improvements welcome.

1. Fork this repo
2. Make your changes
3. Open a PR

---

## License

[MIT](LICENSE) — use it however you want.

---

<div align="center">

**If this saved you from notification silence, give it a ⭐**

</div>
