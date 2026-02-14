#!/bin/bash
# TimeClock Integration - Session Initialization
# Checks if integration is enabled for this project and injects context.
set -euo pipefail

CONFIG="$CLAUDE_PROJECT_DIR/.claude/timeclock-integration.local.md"

# If no config file, integration is disabled for this project
if [ ! -f "$CONFIG" ]; then
  exit 0
fi

# Check if enabled
if ! grep -q "enabled: true" "$CONFIG"; then
  exit 0
fi

# Extract configuration values
PROJECT_NAME=$(grep "project_name:" "$CONFIG" | sed 's/.*project_name: *//' | tr -d '"' | tr -d "'" | xargs)
API_URL=$(grep "api_url:" "$CONFIG" | sed 's/.*api_url: *//' | tr -d '"' | tr -d "'" | xargs)

# Use defaults if not specified
PROJECT_NAME="${PROJECT_NAME:-$(basename "$CLAUDE_PROJECT_DIR")}"
API_URL="${API_URL:-http://localhost:7843}"

# Persist API URL for other hooks to use
echo "export TIMECLOCK_API_URL=$API_URL" >> "$CLAUDE_ENV_FILE"
echo "export TIMECLOCK_PROJECT_NAME=$PROJECT_NAME" >> "$CLAUDE_ENV_FILE"
echo "export TIMECLOCK_ENABLED=true" >> "$CLAUDE_ENV_FILE"

# Check if TimeClock is reachable
if ! curl -s --connect-timeout 2 "$API_URL/api/status" > /dev/null 2>&1; then
  echo "[TimeClock Integration] WARNING: TimeClock API at $API_URL is not reachable. Start the TimeClock desktop app to enable automatic time tracking."
  exit 0
fi

# Output session context for Claude
cat << EOF
[TimeClock Integration Active]
Project: $PROJECT_NAME
API: $API_URL

AUTOMATIC TIME TRACKING is enabled for this session. You MUST:

1. IMMEDIATELY check TimeClock status (GET $API_URL/api/status) and task list (GET $API_URL/api/tasks).
2. If not clocked in, find or create a task matching the current work under the "$PROJECT_NAME" project and clock in.
3. If clocked in to the wrong task, switch to the correct one.
4. Throughout this session, keep TimeClock in sync with your work:
   - When you create or approve a plan, create corresponding TimeClock tasks from its steps.
   - When you complete a task and move to the next, switch TimeClock to match.
   - When the work topic clearly changes, switch TimeClock to the matching task.
5. Do NOT clock out when the session ends -- the user may continue working.
6. Do NOT create duplicate tasks -- always check existing tasks first.
7. Use the TimeClock REST API via curl for all operations.
EOF
