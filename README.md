# Herald

Modern macOS notification CLI built on `UNUserNotificationCenter`.

Herald replaces [alerter](https://github.com/vjeantet/alerter) and [terminal-notifier](https://github.com/julienXX/terminal-notifier) with a single Swift CLI that uses Apple's modern notification API — no deprecated `NSUserNotification`, no private API hacks.

## Features

- **Modern API**: Built on `UNUserNotificationCenter` (not the deprecated `NSUserNotification`)
- **Action buttons**: First-class `UNNotificationAction` (up to 4 buttons)
- **Text input**: `UNTextInputNotificationAction` with placeholder text
- **Both together**: Action buttons AND text input (alerter makes these mutually exclusive)
- **Interruption levels**: passive, active, timeSensitive, critical (replaces `--ignoreDnD` hacks)
- **Threading**: `threadIdentifier` for conversation grouping
- **Relevance score**: Stack priority (0.0–1.0)
- **Rich attachments**: Images, GIFs, video, audio
- **Custom sounds**: Any system sound or custom sound file
- **In-place update**: Replace notifications by ID
- **Notification management**: List and remove delivered/pending notifications
- **AI-native**: AGENTS.md + Claude Code plugin for integration with coding tools

## Requirements

- macOS 13.0+ (Ventura)
- Swift 6.0+

## Install

```bash
make install
```

This builds the `.app` bundle (required for `UNUserNotificationCenter` delegate callbacks), copies it to `/usr/local/lib/herald/`, and symlinks the binary to `/usr/local/bin/herald`.

## Usage

```bash
# Simple notification
herald --message "Hello world" --timeout 5

# Yes/No question (blocks until response)
herald --message "Continue?" --actions "Yes,No" --timeout 300 --json

# Text input
herald --message "Feedback?" --reply "Type here..." --timeout 300 --json

# Text input + buttons
herald --message "Review?" --reply "Comments..." --actions "Approve,Reject" --timeout 60 --json

# Pipe content
echo "Build complete" | herald --title "CI" --timeout 5 --sound default

# Interruption levels
herald --message "FYI" --level passive --timeout 5
herald --message "Urgent" --level timeSensitive --timeout 30

# Manage notifications
herald list --json
herald remove --all
```

## Output

Plain text (default):
```
@ACTIONCLICKED
Yes
```

JSON (`--json`):
```json
{
  "activationType": "actionClicked",
  "activationValue": "Yes",
  "activationValueIndex": 0,
  "deliveredAt": "2026-03-11T16:30:00Z",
  "activationAt": "2026-03-11T16:30:05Z",
  "userText": null
}
```

## Why a .app bundle?

`UNUserNotificationCenter` requires a registered app bundle to receive delegate callbacks (button clicks, text input). Herald packages as `Herald.app` with `LSUIElement: true` (no dock icon) — it behaves exactly like a CLI tool but gets full notification API access.

## AI Agent Integration

Herald ships with:
- **AGENTS.md** — universal instructions read by Codex, Gemini, Claude Code, Cursor, Zed, and Copilot
- **Claude Code plugin** — `/herald:notify` (fire-and-forget) and `/herald:ask` (wait for response) commands

See [AGENTS.md](AGENTS.md) for the full CLI reference and common patterns.

## License

MIT
