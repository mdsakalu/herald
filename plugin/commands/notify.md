---
allowed-tools:
  - "Bash(herald:*)"
description: "Send a fire-and-forget macOS notification"
---

# /herald:notify — Fire-and-forget notification

Send a macOS notification to the user. The notification auto-dismisses after the timeout.
Optionally attach a body-click action with `--on-click "open:<url-or-path>"`.

## Usage

The user may provide a message, or you should compose one based on context (e.g., "Build complete", "Tests passed", "Task finished").

## Instructions

1. Determine the notification message from the user's input or current context
2. Run the herald command:

```bash
herald --message "<message>" --title "<title>" --timeout 5 --sound default
```

Defaults:
- `--title`: Use the current task context (e.g., "Build", "Tests", "Herald")
- `--timeout 5`: Auto-dismiss after 5 seconds
- `--sound default`: Play the default notification sound

If the notification should open a page or file when clicked, append:

```bash
--on-click "open:<url-or-path>"
```

Do NOT use `--json` for fire-and-forget notifications.
Do NOT wait for or parse the output — this is fire-and-forget.
