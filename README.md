# Claude Code Sound Notifications

**Claude Code notifications not working?** You're not alone.

Ghostty, Zellij, tmux, Alacritty, Warp — none of them reliably deliver Claude Code's built-in terminal notifications. This fix bypasses the terminal entirely and uses your OS notification system directly.

**One JSON snippet. Works on every terminal. Takes 30 seconds.**

---

## The Problem

Claude Code sends notifications via **terminal escape sequences** (OSC codes). This breaks in multiple scenarios:

| Scenario | What Happens |
|---|---|
| Ghostty with `desktop-notifications = true` | Escape sequences silently ignored |
| Any terminal + Zellij/tmux | Multiplexer strips the sequences |
| Alacritty, Warp, VS Code, Terminal.app | No OSC notification support at all |
| `skipDangerousModePermissionPrompt: true` | Built-in `Notification` event never fires |

**You finish making coffee, come back, and Claude finished 5 minutes ago. No sound. No banner. Nothing.**

---

## The Fix

Add a **`Stop` hook** to `~/.claude/settings.json`. It fires every time Claude finishes responding — reliably, on every terminal.

### macOS

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

### Linux

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

### Linux (with sound)

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

---

## Quick Start

**1.** Open your settings file:

```bash
nano ~/.claude/settings.json
```

**2.** Add the `hooks` block from above into your existing settings. If you already have other settings, just merge the `hooks` key:

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

**3.** Restart Claude Code. Done.

> You can also copy the ready-to-use [`settings.example.json`](settings.example.json) from this repo.

---

## Why `Stop` Instead of `Notification`?

Claude Code has a built-in `Notification` event, but it's unreliable:

| Event | When It Fires | Reliability |
|---|---|---|
| `Notification` | Permission prompts, idle state, auth events | Skipped when `skipDangerousModePermissionPrompt` is enabled |
| **`Stop`** | **Every time Claude finishes a response** | **Always fires** |

If you use dangerous mode (most power users do), `Notification` will **never fire**. `Stop` is the correct event.

---

## How It Works

```
Claude Code finishes responding
        |
        v
  "Stop" hook fires
        |
        v
  osascript / notify-send runs
        |
        v
  OS Notification Center
        |
        v
  Sound + Banner
```

No terminal escape sequences. No dependency on Ghostty, Kitty, or any terminal. Direct OS-level notification.

---

## Customize the Sound (macOS)

Replace `"Glass"` with any built-in macOS sound:

| Sound | Vibe |
|---|---|
| `Glass` | Clean, subtle |
| `Ping` | Classic notification |
| `Pop` | Quick, light |
| `Purr` | Soft, gentle |
| `Hero` | Bold, triumphant |
| `Submarine` | Deep, distinct |
| `Frog` | Fun, unmissable |
| `Sosumi` | The OG Mac sound |
| `Tink` | Minimal, delicate |

**Test a sound:**

```bash
osascript -e 'display notification "Test" with title "Claude Code" sound name "Hero"'
```

---

## Tested On

- [x] Ghostty
- [x] Ghostty + Zellij
- [x] Ghostty + tmux
- [x] Kitty
- [x] iTerm2
- [x] Alacritty
- [x] Warp
- [x] macOS Terminal.app
- [x] VS Code integrated terminal

**Works on all of them** — because it doesn't use the terminal for notifications.

---

## Troubleshooting

**No sound or notification:**
- Check **System Settings > Notifications** — make sure notifications are enabled for "Script Editor"
- Make sure **Do Not Disturb / Focus** mode is off
- Validate your JSON: `python3 -m json.tool ~/.claude/settings.json`
- Restart Claude Code after editing settings

**Hook not firing:**
- Run `/hooks` inside Claude Code to verify the hook is loaded
- Hooks go inside `settings.json`, **not** a separate `hooks.json` file

**Test the notification manually:**
```bash
# macOS
osascript -e 'display notification "Test" with title "Claude Code" sound name "Glass"'

# Linux
notify-send "Claude Code" "Test"
```

---

## License

MIT

---

**Found this useful?** Give it a star — it helps others find it too.
