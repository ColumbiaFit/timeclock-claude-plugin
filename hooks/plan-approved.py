"""TimeClock Integration - Plan Approved Hook.

Fires after ExitPlanMode to remind Claude to create TimeClock tasks.
"""
import os
import sys
import urllib.request
import urllib.error

if os.environ.get("TIMECLOCK_ENABLED") != "true":
    sys.exit(0)

api_url = os.environ.get("TIMECLOCK_API_URL", "http://localhost:7843")

# Check if TimeClock is reachable
try:
    urllib.request.urlopen(f"{api_url}/api/status", timeout=2)
except Exception:
    sys.exit(0)

print(f"""[TimeClock] A plan was just approved. You MUST now:
1. Read the plan content to identify major tasks/steps.
2. Check existing TimeClock tasks (GET {api_url}/api/tasks) to avoid duplicates.
3. Create TimeClock tasks for each plan step under the appropriate project (POST {api_url}/api/tasks).
4. Clock in to the first task if not already working on it (POST {api_url}/api/clock-in or /api/switch-task).""")
