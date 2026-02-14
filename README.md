# TimeClock Integration Plugin

Automatic time tracking for Claude Code development sessions via the TimeClock desktop application.

## What It Does

When enabled for a project, this plugin automatically:

- **Clocks in** when a Claude Code session starts
- **Creates tasks** from approved plans (plan mode or superpowers planning)
- **Switches tasks** when your work context changes
- **Advances tasks** when TODO items are completed

## How It Works

1. **SessionStart hook** checks if integration is enabled for the current project
2. If enabled, it injects instructions into Claude's context telling it to manage TimeClock
3. Claude uses the TimeClock REST API (`localhost:7843`) to create projects, tasks, and manage clock entries
4. **PostToolUse hooks** on `ExitPlanMode` and `TaskUpdate` provide additional reminders at key moments

## Installation

Add the plugin to your Claude Code settings:

```bash
claude /plugins:add "C:\Time clock project\timeclock-integration"
```

Or manually add to `~/.claude/settings.json`:

```json
{
  "plugins": [
    "C:\\Time clock project\\timeclock-integration"
  ]
}
```

## Per-Project Configuration

The plugin is **disabled by default** for all projects. Enable it per-project:

```
/timeclock-integration:configure enable
```

This creates `.claude/timeclock-integration.local.md` in the project with:

```yaml
---
enabled: true
project_name: "DFACS"
api_url: "http://localhost:7843"
---
```

### Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `enabled` | `false` | Whether integration is active |
| `project_name` | Directory name | TimeClock project name for task creation |
| `api_url` | `http://localhost:7843` | TimeClock REST API URL |

### Disable for a project

```
/timeclock-integration:configure disable
```

### Check status

```
/timeclock-integration:configure status
```

## Prerequisites

- TimeClock desktop application must be running
- The REST API server runs on `localhost:7843` by default

## Project Priority

Only projects with `enabled: true` in their config will manage TimeClock. This means:

- Your DFACS project can have integration enabled
- Personal projects or other work won't interfere
- Multiple Claude sessions can run simultaneously -- only the enabled project's session manages the clock

## Restart Required

Hook changes take effect on session restart. After enabling or disabling integration, restart Claude Code for the changes to apply.
