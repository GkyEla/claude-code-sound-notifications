---
name: Bug Report
about: Notifications not working? Let's fix it.
title: ''
labels: bug
assignees: ''
---

**Environment**
- OS: [e.g. macOS 15.2, Ubuntu 24.04]
- Terminal: [e.g. Ghostty, iTerm2, Alacritty]
- Multiplexer: [e.g. Zellij, tmux, none]
- Claude Code version: [run `claude --version`]

**What happened?**
A clear description of the issue.

**Does this work?**
```bash
# macOS
osascript -e 'display notification "Test" with title "Test" sound name "Glass"'

# Linux
notify-send "Test" "Test"
```

**Your settings.json**
```json
(paste relevant hooks section)
```
