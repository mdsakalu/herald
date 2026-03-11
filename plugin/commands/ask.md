---
allowed-tools:
  - "Bash(herald:*)"
description: "Send a notification and wait for user response"
---

# /herald:ask — Synchronous notification with response

Send a macOS notification that waits for the user to interact with it, then parse and act on the response.

## Usage

The user may specify a question and options, or you should determine them from context.

## Instructions

1. **Determine the question** from user input or current context
2. **Choose the interaction type:**
   - **Buttons only** (`--actions`): For multiple-choice decisions (e.g., "Yes,No", "Approve,Reject,Skip")
   - **Text input only** (`--reply`): For free-form feedback (e.g., "Describe the issue...")
   - **Both** (`--reply` + `--actions`): For text with action buttons (e.g., reply placeholder + "Submit,Skip")
3. **Run the command** with `--json` for structured output:

```bash
# Buttons only
herald --message "Should I refactor this function?" --actions "Yes,No" --timeout 300 --json

# Text input only
herald --message "Any feedback on this approach?" --reply "Type here..." --timeout 300 --json

# Both together
herald --message "Review this change?" --reply "Comments..." --actions "Approve,Reject" --timeout 300 --json
```

4. **Parse the JSON response:**

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

- `activationType`: "actionClicked" | "replied" | "dismissed" | "timeout" | "closed"
- `activationValue`: The button label clicked (or "__reply__" for text input)
- `userText`: Text the user typed (only for text input responses)

5. **Act on the response:**
   - If `timeout` or `dismissed` or `closed`: Inform the user and stop waiting
   - If `actionClicked`: Proceed based on the button value
   - If `replied`: Use the `userText` content

## Defaults

- `--title "Herald"`: Override with context-appropriate title
- `--timeout 300`: 5-minute timeout (reasonable for async human response)
- Always use `--json` for structured parsing
