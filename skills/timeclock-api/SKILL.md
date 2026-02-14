---
name: "timeclock-api"
description: "Automatic time tracking through the TimeClock desktop REST API. Manages clock-in/out, task creation from plans, and task switching to keep TimeClock synchronized with development work."
---
# TimeClock Integration -- Automatic Time Tracking for Development Sessions

## Description

This skill enables automatic time tracking through the TimeClock desktop application's REST API on `http://localhost:7843`. It manages clock-in/out, task creation, and task switching to keep TimeClock synchronized with the developer's current work.

Use this skill when:
- A session starts in a project with TimeClock integration enabled
- The user mentions clocking in, clocking out, or tracking time
- The user asks about their current work status or what task they are on
- A plan is created or approved and tasks need to be created in TimeClock
- The work context changes and the active TimeClock task should be updated
- The user wants to create a new project or task in TimeClock
- The user says they are starting, stopping, or changing what they are working on

## Prerequisites

The TimeClock desktop application must be running. If API calls fail with connection errors, inform the user that TimeClock does not appear to be running.

## API Reference

**Base URL:** `http://localhost:7843` -- All endpoints prefixed with `/api/`. POST requests use `Content-Type: application/json`.

### GET /api/status

Returns clock-in state, active task, and elapsed time.

```bash
curl -s http://localhost:7843/api/status
```

Response when clocked in includes `clocked_in: true`, `active_task` (with `id`, `name`, `breadcrumb`), and `elapsed_seconds`.

### GET /api/tasks

Returns the full project/task tree. Projects contain children. Tasks are leaf nodes (only tasks can be clocked into).

```bash
curl -s http://localhost:7843/api/tasks
```

### POST /api/tasks

Creates a new project or task.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Display name |
| node_type | string | No | `"project"` or `"task"` (default: `"task"`) |
| parent_id | integer | Conditional | Required for tasks |
| color | string | No | Hex color e.g. `"#ff8c00"` |

```bash
curl -s -X POST http://localhost:7843/api/tasks -H "Content-Type: application/json" -d "{\"name\": \"Fix login bug\", \"node_type\": \"task\", \"parent_id\": 1}"
```

### POST /api/clock-in

Clock in to a task. Requires `task_id`. Fails if already clocked in.

```bash
curl -s -X POST http://localhost:7843/api/clock-in -H "Content-Type: application/json" -d "{\"task_id\": 3}"
```

### POST /api/clock-out

Clock out. No body needed.

```bash
curl -s -X POST http://localhost:7843/api/clock-out
```

### POST /api/switch-task

Switch to a different task while staying clocked in. Requires `task_id`.

```bash
curl -s -X POST http://localhost:7843/api/switch-task -H "Content-Type: application/json" -d "{\"task_id\": 5}"
```

### GET /api/today

Returns today's hours worked, remaining, and target.

```bash
curl -s http://localhost:7843/api/today
```

## Automatic Behavior Rules

When TimeClock integration is active for a session (indicated by the SessionStart hook), follow these rules automatically:

### Session Start
1. Check `/api/status` to see if already clocked in
2. Check `/api/tasks` to find a task matching the current work
3. If a matching task exists and you are not clocked in, clock in to it
4. If a matching task exists but you are clocked into a different task, switch to it
5. If no matching task exists, create it under the appropriate project, then clock in

### Plan Approval
When a plan is approved (ExitPlanMode) or a plan file is written:
1. Read the plan content
2. Check `/api/tasks` for an existing project matching the plan's scope
3. If no matching project exists, create one with `POST /api/tasks` (node_type: project)
4. For each major step or task in the plan, create a task under the project
5. Clock in to the first task if not already working on it
6. Do NOT create duplicate tasks -- check existing tasks first

### Task Completion
When a development task is completed (TODO marked done, commit made, test passing):
1. Check if there is a next task in the plan
2. If yes, switch TimeClock to the next task using `/api/switch-task`
3. If all tasks are done, remain clocked in to the last task (user will clock out when ready)

### Context Changes
When the work topic clearly changes mid-session:
1. Check `/api/status` to see the current TimeClock task
2. If the new work does not match the current task, find or create the right task
3. Switch to it using `/api/switch-task`
4. Only switch for clear, sustained topic changes -- not brief tangents

### Task Naming Conventions
- Projects: Use the plan name or feature name (e.g., "DFACS Wiki Fixes", "TimeClock v1")
- Tasks: Use concise action descriptions (e.g., "Fix overlay expand bug", "Add phone call tracking")
- Match the granularity of plan steps -- one TimeClock task per plan step

## Behavior Guidelines

- Always check `/api/status` before clock-in or switch to avoid errors
- Use `/api/switch-task` instead of clock-out + clock-in when changing tasks
- When creating tasks, always provide a `parent_id` (tasks need a parent project)
- If the API is unreachable, inform the user and continue without blocking work
- Present time in readable format: "2 hours, 14 minutes" not raw seconds
- Do not clock out automatically when a session ends -- the user may continue working
- Do not create tasks for brief side conversations or unrelated questions
- When in doubt about whether to switch tasks, do not switch -- only act on clear context changes
