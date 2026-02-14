---
allowed-tools: ["Read", "Write", "Bash", "AskUserQuestion"]
description: "Enable, disable, or configure TimeClock integration for the current project"
argument-hint: "[enable|disable|status]"
---

# TimeClock Integration Configuration

You are configuring TimeClock automatic time tracking for the current project.

## Configuration File

The settings live in `.claude/timeclock-integration.local.md` in the project root. This file controls whether TimeClock integration is active for this project.

## Actions

Based on the user's argument:

### `enable` (or no argument)
1. Ask the user for the project name to use in TimeClock (suggest the current directory name as default).
2. Ask for the TimeClock API URL (default: `http://localhost:7843`).
3. Create or update `.claude/timeclock-integration.local.md` with:

```markdown
---
enabled: true
project_name: "<user's answer>"
api_url: "<user's answer>"
---
# TimeClock Integration

This project has automatic TimeClock time tracking enabled.
When Claude Code sessions start in this project, TimeClock will automatically:
- Clock in to the matching task
- Create tasks from approved plans
- Switch tasks as work context changes
```

4. Confirm to the user that integration is enabled. Remind them to restart Claude Code for the hooks to take effect.

### `disable`
1. If the config file exists, update `enabled: true` to `enabled: false`.
2. If no config file exists, tell the user integration is already disabled.
3. Confirm to the user and remind them to restart Claude Code.

### `status`
1. Read the config file if it exists.
2. Report whether integration is enabled or disabled.
3. Show the configured project name and API URL.
4. Try to reach the TimeClock API and report if it's running.
