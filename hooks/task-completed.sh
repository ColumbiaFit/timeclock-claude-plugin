#!/bin/bash
# TimeClock Integration - Task Completed Hook
# Fires after TaskUpdate to check if a todo was completed and TimeClock should advance.
set -euo pipefail

# Check if integration is enabled
if [ "${TIMECLOCK_ENABLED:-}" != "true" ]; then
  exit 0
fi

API_URL="${TIMECLOCK_API_URL:-http://localhost:7843}"

# Read the tool input from stdin to check if this was a completion
INPUT=$(cat)
PYTHON_CMD=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "")
if [ -n "$PYTHON_CMD" ]; then
  STATUS=$(echo "$INPUT" | "$PYTHON_CMD" -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('status',''))" 2>/dev/null || echo "")
else
  # Fallback: grep for status field
  STATUS=$(echo "$INPUT" | grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"' || echo "")
fi

# Only fire on task completion
if [ "$STATUS" != "completed" ]; then
  exit 0
fi

# Check if TimeClock is reachable
if ! curl -s --connect-timeout 2 "$API_URL/api/status" > /dev/null 2>&1; then
  exit 0
fi

cat << EOF
[TimeClock] A development task was just completed. Check if TimeClock should advance:
1. Check current TimeClock status (GET $API_URL/api/status).
2. If there is a next task in the current plan, switch TimeClock to it (POST $API_URL/api/switch-task).
3. If this was the last task, stay clocked in -- the user will clock out when ready.
EOF
