"""TimeClock Integration - Session Initialization.

Checks if integration is enabled for this project and injects context.
"""
import os
import sys
import urllib.request
import urllib.error

project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "")
env_file = os.environ.get("CLAUDE_ENV_FILE", "")

config_path = os.path.join(project_dir, ".claude", "timeclock-integration.local.md")

# If no config file, integration is disabled for this project
if not os.path.isfile(config_path):
    sys.exit(0)

with open(config_path, "r", encoding="utf-8") as f:
    content = f.read()

# Check if enabled
if "enabled: true" not in content:
    sys.exit(0)

# Extract configuration values
project_name = ""
api_url = ""
for line in content.splitlines():
    if line.strip().startswith("project_name:"):
        project_name = line.split(":", 1)[1].strip().strip("\"'")
    elif line.strip().startswith("api_url:"):
        api_url = line.split(":", 1)[1].strip().strip("\"'")

if not project_name:
    project_name = os.path.basename(project_dir)
if not api_url:
    api_url = "http://localhost:7843"

# Persist env vars for other hooks
if env_file:
    with open(env_file, "a", encoding="utf-8") as f:
        f.write(f"export TIMECLOCK_API_URL={api_url}\n")
        f.write(f"export TIMECLOCK_PROJECT_NAME={project_name}\n")
        f.write(f"export TIMECLOCK_ENABLED=true\n")

# Check if TimeClock is reachable
try:
    req = urllib.request.Request(f"{api_url}/api/status", method="GET")
    urllib.request.urlopen(req, timeout=2)
except Exception:
    print(f"[TimeClock Integration] WARNING: TimeClock API at {api_url} is not reachable. Start the TimeClock desktop app to enable automatic time tracking.")
    sys.exit(0)

# Output session context for Claude
print(f"""[TimeClock Integration Active]
Project: {project_name}
API: {api_url}

AUTOMATIC TIME TRACKING is enabled for this session. You MUST:

1. IMMEDIATELY check TimeClock status (GET {api_url}/api/status) and task list (GET {api_url}/api/tasks).
2. If not clocked in, find or create a task matching the current work under the "{project_name}" project and clock in.
3. If clocked in to the wrong task, switch to the correct one.
4. Throughout this session, keep TimeClock in sync with your work:
   - When you create or approve a plan, create corresponding TimeClock tasks from its steps.
   - When you complete a task and move to the next, switch TimeClock to match.
   - When the work topic clearly changes, switch TimeClock to the matching task.
5. Do NOT clock out when the session ends -- the user may continue working.
6. Do NOT create duplicate tasks -- always check existing tasks first.
7. Use the TimeClock REST API via curl for all operations.""")
