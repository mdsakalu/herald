<div align="center">

<img src="resources/AppIcon-1024.png" width="128" />

# herald

Modern macOS notification CLI built on UNUserNotificationCenter

[<img src="https://img.shields.io/github/actions/workflow/status/mdsakalu/herald/ci.yml?label=build&logo=github" />](https://github.com/mdsakalu/herald/actions)
[<img src="https://img.shields.io/github/v/release/mdsakalu/herald?label=release&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNiAxNiIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJ3aGl0ZSIgc3Ryb2tlLXdpZHRoPSIxLjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCI%2BCiAgPHBhdGggZD0iTTIgNyBMNyAyIEgxNCBWOSBMOSAxNCBaIi8%2BCiAgPGNpcmNsZSBjeD0iMTEiIGN5PSI1IiByPSIxIi8%2BCjwvc3ZnPg%3D%3D" />](https://github.com/mdsakalu/herald/releases/latest)
[<img src="https://img.shields.io/github/downloads/mdsakalu/herald/total?label=downloads&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNiAxNiIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJ3aGl0ZSIgc3Ryb2tlLXdpZHRoPSIxLjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCI%2BCiAgPHBhdGggZD0iTTggMiBWMTAiLz4KICA8cGF0aCBkPSJNNSA3IEw4IDEwIEwxMSA3Ii8%2BCiAgPHBhdGggZD0iTTMgMTMgSDEzIi8%2BCjwvc3ZnPg%3D%3D" />](https://github.com/mdsakalu/herald/releases)
[<img src="https://img.shields.io/badge/Swift-6.0+-F05138?logo=swift&logoColor=white" />](https://www.swift.org)
[<img src="https://img.shields.io/badge/Homebrew-mdsakalu/tap/herald-orange?logo=homebrew" />](https://github.com/mdsakalu/homebrew-tap)
[<img src="https://img.shields.io/badge/macOS-13.0+-lightgrey?logo=apple" />](https://www.apple.com/macos)
[<img src="https://img.shields.io/github/license/mdsakalu/herald?logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNCAxNiI%2BPHBhdGggZmlsbD0id2hpdGUiIGZpbGwtcnVsZT0iZXZlbm9kZCIgZD0iTTcgNGMtLjgzIDAtMS41LS42Ny0xLjUtMS41UzYuMTcgMSA3IDFzMS41LjY3IDEuNSAxLjVTNy44MyA0IDcgNHptNyA2YzAgMS4xMS0uODkgMi0yIDJoLTFjLTEuMTEgMC0yLS44OS0yLTJsMi00aC0xYy0uNTUgMC0xLS40NS0xLTFIOHY4Yy40MiAwIDEgLjQ1IDEgMWgxYy40MiAwIDEgLjQ1IDEgMUgzYzAtLjU1LjU4LTEgMS0xaDFjMC0uNTUuNTgtMSAxLTFoLjAzTDYgNUg1YzAgLjU1LS40NSAxLTEgMUgzbDIgNGMwIDEuMTEtLjg5IDItMiAySDJjLTEuMTEgMC0yLS44OS0yLTJsMi00SDFWNWgzYzAtLjU1LjQ1LTEgMS0xaDRjLjU1IDAgMSAuNDUgMSAxaDN2MWgtMWwyIDR6TTIuNSA3TDEgMTBoM0wyLjUgN3pNMTMgMTBsLTEuNS0zLTEuNSAzaDN6Ii8%2BPC9zdmc%2B" />](LICENSE)

</div>

## About

Herald builds upon [alerter](https://github.com/vjeantet/alerter) and [terminal-notifier](https://github.com/julienXX/terminal-notifier) with a single Swift CLI built on Apple's modern `UNUserNotificationCenter` API — no deprecated `NSUserNotification`, no private API hacks. Send notifications, capture user responses with action buttons and text input, attach still images, and manage the notification lifecycle from the terminal.

### What's new vs alerter/terminal-notifier

| Feature | alerter | terminal-notifier | **herald** |
|---------|---------|-------------------|------------|
| API | NSUserNotification (deprecated) | NSUserNotification (deprecated) | **UNUserNotificationCenter** |
| Action buttons | Private API hack | No | **First-class UNNotificationAction** |
| Text input | Private API hack | No | **UNTextInputNotificationAction** |
| Text input + buttons | Mutually exclusive | N/A | **Both together** |
| Interruption levels | `--ignoreDnd` hack | `--ignoreDnD` hack | **4 tiers (passive/active/timeSensitive/critical)** |
| Threading | `--group` only | `--group` only | **threadIdentifier + group** |
| Stacking priority | No | No | **relevanceScore (0.0-1.0)** |
| Notification update | Replace by group | Replace by group | **Replace by ID (in-place)** |
| Attachments | contentImage only | contentImage only | **Still images only** |
| Custom sounds | System only | System only | **Custom sound files** |

## Install

### Homebrew

```bash
brew install mdsakalu/tap/herald
```

### From source

```bash
make install
```

To install to a custom prefix:

```bash
./scripts/install.sh --prefix ~/.local
```

To uninstall:

```bash
# Homebrew
brew uninstall herald

# Manual install
./scripts/install.sh --uninstall
```

### Requirements

- macOS 13.0+ (Ventura)
- Swift 6.0+ (for building from source; Homebrew handles this)

### Why a .app bundle?

`UNUserNotificationCenter` requires a registered app bundle to receive delegate callbacks (button clicks, text input). Herald packages as `Herald.app` with `LSUIElement: true` (no dock icon) — it behaves exactly like a CLI tool but gets full notification API access.

## Good Fits

- Build, test, and deploy completion alerts from scripts or CI
- Human approval gates during automated workflows
- Collecting short text feedback without leaving the terminal flow
- Updating or replacing progress notifications for long-running tasks
- Grouping related notifications with `--thread` and prioritizing them with `--relevance`

## Usage

```bash
# Simple notification
herald --message "Hello world" --timeout 5

# Yes/No question (blocks until response)
herald --message "Continue?" --actions "Yes,No" --timeout 300 --json

# Text input
herald --message "Feedback?" --reply "Type here..." --timeout 300 --json

# Text input + buttons (alerter can't do this)
herald --message "Review?" --reply "Comments..." --actions "Approve,Reject" --timeout 60 --json

# Image attachment
herald --message "Build artifact" --image ./screenshot.png --timeout 10

# Supported attachment formats
# png, jpg, jpeg, heic, heif, tif, tiff, bmp

# Pipe content via stdin
echo "Build complete" | herald --title "CI" --timeout 5 --sound default

# Interruption levels
herald --message "FYI" --level passive --timeout 5
herald --message "Urgent" --level timeSensitive --timeout 30

# Threading and stacking
herald --message "Step 1 done" --thread "pipeline" --relevance 0.5
herald --message "Step 2 done" --thread "pipeline" --relevance 0.8

# Notification management
herald list --json
herald remove --id <notification-id>
herald remove --all
```

### CLI Reference

**`herald [send]`** (default subcommand)

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--message` | String | stdin | Notification body |
| `--title` | String | `"Herald"` | Title text |
| `--subtitle` | String | — | Subtitle text |
| `--reply` | String | — | Enable text input; value is placeholder text |
| `--actions` | String | — | Comma-separated button labels (max 10) |
| `--timeout` | Int | `0` | Auto-dismiss seconds (0 = sticky until interaction) |
| `--sound` | String | — | `"default"`, `"none"`, `"critical"`, `"critical:VOL"`, or sound name |
| `--image` | String | — | Attachment path (`png`, `jpg`, `jpeg`, `heic`, `heif`, `tif`, `tiff`, `bmp` only) |
| `--thread` | String | — | Thread ID (visual grouping in NC) |
| `--level` | Enum | `active` | `passive` / `active` / `timeSensitive` / `critical` |
| `--relevance` | Double | — | Stack priority (0.0-1.0) |
| `--badge` | Int | — | App badge number |
| `--id` | String | auto UUID | Notification ID (for update/replace) |
| `--json` | Flag | `false` | Structured JSON output |

**`herald list [--json]`** — list delivered and pending notifications

**`herald remove --id ID | --all`** — remove notifications

### Output Format

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

| activationType | Meaning |
|---------------|---------|
| `actionClicked` | User clicked a button |
| `replied` | User submitted text input |
| `dismissed` | User dismissed the notification |
| `timeout` | Auto-dismissed after timeout |
| `closed` | Process received SIGINT/SIGTERM |

## AI Agent Integration

Herald's JSON output and synchronous response capture make it easy to integrate with AI coding agents. It ships with:

- **[AGENTS.md](AGENTS.md)** — universal CLI reference read by Codex, Gemini, Claude Code, Cursor, Zed, and GitHub Copilot
- **Claude Code plugin** — `/herald:notify` (fire-and-forget) and `/herald:ask` (wait for response) slash commands

### Common agent patterns

```bash
# Decision gate — agent waits for user choice
result=$(herald --message "Proceed with refactoring?" --actions "Yes,No" --timeout 300 --json)

# Collect feedback — text input with action buttons
result=$(herald --message "Any concerns?" --reply "Type feedback..." \
  --actions "Looks good,Needs changes" --timeout 600 --json)

# Background notification — fire and forget
herald --message "Tests passed (42/42)" --title "CI" --timeout 5 --sound default --level passive

# Pipeline notification — piped content
echo "Deploy complete: 3 services updated" | herald --title "Deploy" --timeout 10 --sound default
```

## Troubleshooting

### "Notification permission denied" on first run

On first launch, macOS shows a permission dialog — click **Allow**. If you missed it or clicked Don't Allow:

1. Open **System Settings > Notifications**
2. Find **Herald** in the app list
3. Toggle **Allow Notifications** on

### Notifications appear but no banner

Check that Herald's notification style is set to **Alerts** (not Banners) in System Settings > Notifications > Herald. Alert style is required for action buttons and text input to be visible.

### "Authorization error" immediately

The app bundle must be ad-hoc signed. If you built manually without `scripts/build-app.sh`, run:

```bash
codesign --force --deep --sign - .build/Herald.app
```

### Non-interactive sends still block

If `herald --message "test"` hangs instead of exiting immediately, make sure you're running v0.1.0+ — earlier builds blocked on all sends. Non-interactive notifications (no `--actions` or `--reply`) are fire-and-forget and exit immediately after delivery.

## License

MIT
