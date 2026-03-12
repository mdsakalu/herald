# Herald — macOS Notification CLI

Herald sends macOS notifications from the command line using the modern `UNUserNotificationCenter` API. AI coding tools can use it to notify users or ask questions via system notifications.

## Installation

```bash
make install
# or: ./scripts/install.sh
```

## Quick Reference

### Send a notification (fire-and-forget)

```bash
herald --message "Build complete" --timeout 5 --sound default
```

### Ask a yes/no question (blocks until response)

```bash
herald --message "Deploy to staging?" --actions "Yes,No" --timeout 300 --json
```

### Ask for text input

```bash
herald --message "Describe the issue" --reply "Type here..." --timeout 300 --json
```

### Text input + action buttons (both together)

```bash
herald --message "Review this PR?" --reply "Comments..." --actions "Approve,Reject" --timeout 300 --json
```

## CLI Flags

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--message` | String | stdin | Notification body |
| `--title` | String | "Herald" | Title text |
| `--subtitle` | String | — | Subtitle text |
| `--reply` | String | — | Enable text input; value = placeholder |
| `--actions` | String | — | Comma-separated buttons (max 4) |
| `--timeout` | Int | 0 | Auto-dismiss seconds (0 = sticky) |
| `--sound` | String | — | "default", "none", or sound name |
| `--image` | String | — | Attachment path (image/GIF/video/audio) |
| `--group` | String | — | Grouping ID (for replacement) |
| `--thread` | String | — | Thread ID (visual grouping) |
| `--level` | Enum | active | passive/active/timeSensitive/critical |
| `--relevance` | Double | — | Stack priority (0.0–1.0) |
| `--badge` | Int | — | App badge number |
| `--id` | String | auto | Notification ID (for update/replace) |
| `--json` | Flag | false | JSON output |

## JSON Response Format

When using `--json`, herald outputs:

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

### activationType values

| Value | Meaning |
|-------|---------|
| `actionClicked` | User clicked a button |
| `replied` | User submitted text input |
| `dismissed` | User dismissed the notification |
| `timeout` | Auto-dismissed after timeout |
| `closed` | Process received SIGINT/SIGTERM |

## Notification Management

```bash
herald list --json              # List all notifications
herald remove --id <id>         # Remove by ID
herald remove --group <group>   # Remove by group
herald remove --all             # Remove all
```

## Common Patterns for AI Agents

### Decision gate
```bash
result=$(herald --message "Proceed with refactoring?" --actions "Yes,No" --timeout 300 --json)
# Parse activationValue to decide next step
```

### Collect feedback
```bash
result=$(herald --message "Any concerns?" --reply "Type feedback..." --actions "Looks good,Needs changes" --timeout 600 --json)
# Check activationValue for button, userText for typed feedback
```

### Background notification
```bash
herald --message "Tests passed (42/42)" --title "CI" --timeout 5 --sound default --level passive
```

### Pipeline notification
```bash
echo "Deploy complete: 3 services updated" | herald --title "Deploy" --timeout 10 --sound default
```
