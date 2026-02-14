#!/bin/bash
# TimeClock Integration - Plan Approved Hook
# Fires after ExitPlanMode to remind Claude to create TimeClock tasks from the plan.
set -euo pipefail

# Check if integration is enabled (set by session-init.sh)
if [ "${TIMECLOCK_ENABLED:-}" != "true" ]; then
  exit 0
fi

API_URL="${TIMECLOCK_API_URL:-http://localhost:7843}"
PROJECT_NAME="${TIMECLOCK_PROJECT_NAME:-$(basename "$CLAUDE_PROJECT_DIR")}"

# Check if TimeClock is reachable
if ! curl -s --connect-timeout 2 "$API_URL/api/status" > /dev/null 2>&1; then
  exit 0
fi

cat << EOF
[TimeClock] A plan was just approved. You MUST now:
1. Read the plan file that was just written.
2. Check existing TimeClock tasks (GET $API_URL/api/tasks) to avoid duplicates.
3. If no project exists for "$PROJECT_NAME", create one (POST $API_URL/api/tasks with node_type: project).
4. Create a TimeClock task for each major step in the plan under that project.
5. If not already clocked in to the first task, clock in or switch to it.
6. Use concise task names matching the plan steps.
EOF
