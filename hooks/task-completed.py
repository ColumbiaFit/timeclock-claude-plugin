"""TimeClock Integration - Task Completed Hook.

Fires after TaskUpdate to check if a todo was completed and TimeClock should advance.
"""
import json
import os
import sys
import urllib.request
import urllib.error

if os.environ.get("TIMECLOCK_ENABLED") != "true":
    sys.exit(0)

api_url = os.environ.get("TIMECLOCK_API_URL", "http://localhost:7843")

# Read tool input from stdin
try:
    data = json.load(sys.stdin)
    status = data.get("tool_input", {}).get("status", "")
except Exception:
    sys.exit(0)

# Only fire on task completion
if status != "completed":
    sys.exit(0)

# Check if TimeClock is reachable
try:
    urllib.request.urlopen(f"{api_url}/api/status", timeout=2)
except Exception:
    sys.exit(0)

print(f"""[TimeClock] A development task was just completed. Check if TimeClock should advance:
1. Check current TimeClock status (GET {api_url}/api/status).
2. If there is a next task in the current plan, switch TimeClock to it (POST {api_url}/api/switch-task).
3. If this was the last task, stay clocked in -- the user will clock out when ready.""")
