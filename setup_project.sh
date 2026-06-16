#!/bin/bash

#This is a script that creates directory structure, writes source files, configures thresholds, validates the environment, and handles SIGINT.

USER_INPUT=""
PROJECT_DIR=""
MAX_ATTEMPTS=3
ATTEMPT=0

#Process Management (Signal Trap)
handle_interrupt() {
        echo "Interrupt signal caught (SIGINT). Starting cleanup..."
	if [ -n "$PROJECT_DIR" ] && [ -d "$PROJECT_DIR" ]; then
		ARCHIVE_NAME="attendance_tracker_${USER_INPUT}_archive"
		echo "[*] Archiving project state to: ${ARCHIVE_NAME}.tar.gz"
		tar -czf "${ARCHIVE_NAME}.tar.gz" "$PROJECT_DIR" 2>/dev/null
		if [ $? -eq 0 ]; then
			echo "Archive saved: ${ARCHIVE_NAME}.tar.gz"
		else
			echo "Archived failed, directory may have been empty."
		fi
		rm -rf "$PROJECT_DIR"
		echo "Incomplete directory removed. Workspace is clean."
	else
		echo "No directory to clean up."
	fi
	echo "Setup aborted."
	exit 1
}
trap handle_interrupt SIGINT

#Get project name from the user
echo "--------DIRECTORY ARCHITECTURE--------"
while true; do
	if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
		echo "Too many invalid attempts. Exiting."
		exit 1
	fi
	read -p "Enter a project tag (e.g. v1): " USER_INPUT
	ATTEMPT=$((ATTEMPT + 1))
	if [ -z "$USER_INPUT" ]; then
		echo "Tag cannot be empty. Please try again."
		continue
	fi
	if [[ "$USER_INPUT" =~ [[:space:]] ]]; then
        	echo "Tag cannot contain spaces. Use underscores or dashes instead."
		continue
	fi
	break
done
PROJECT_DIR="attendance_tracker_${USER_INPUT}"
if [ -d "$PROJECT_DIR" ]; then
    echo "Sorry, directory '$PROJECT_DIR' already exists."
    echo "Choose a different tag or remove the existing directory first."
    exit 1
fi

#Create the project directory architecture
echo "Creating the project directory architecture"
mkdir -p "${PROJECT_DIR}/Helpers"
if [ $? -ne 0 ]; then
	echo "Failed to create '${PROJECT_DIR}/Helpers'. Check folder permissions."
	exit 1
fi
mkdir -p "${PROJECT_DIR}/reports"
if [ $? -ne 0 ]; then
	echo "Failed to create '${PROJECT_DIR}/reports'. Check folder permissions."
	exit 1
fi
echo "Created ${PROJECT_DIR}/ successfully"
echo "Created ${PROJECT_DIR}/Helpers successfully"
echo "Created ${PROJECT_DIR}/reports/ successfully"

#Write all required project files
echo "--------WRITING PROJECT FILES--------"
#----attendance_checker.py----
cat > "${PROJECT_DIR}/attendance_checker.py" << 'PYEOF'
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)

    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']

        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")

        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])

            attendance_pct = (attended / total_sessions) * 100

            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."

            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
PYEOF
echo "Finished writing to attendance_checker.py"
#----Helpers/assets.csv----
cat > "${PROJECT_DIR}/Helpers/assets.csv" << 'CSVEOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
CSVEOF
echo "Finished writing to Helpers/assets.csv"
#----Helpers/config.json----
cat > "${PROJECT_DIR}/Helpers/config.json" << 'JSONEOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
JSONEOF
echo "Finished writing to Helpers/config.json"

# ----reports/reports.log----
cat > "${PROJECT_DIR}/reports/reports.log" << 'LOGEOF'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
LOGEOF

echo "Finished writing to reports/reports.log"

#Dynamic Configuration (Stream Editing)
echo "--------DYNAMIC CONFIGURATION--------"
echo "Default thresholds in config.json:"
echo "   Warning : 75%"
echo "   Failure : 50%"
echo ""
read -p "Do you want to update the thresholds? (yes/no) [default: no]: " UPDATE_CHOICE
if [[ "$UPDATE_CHOICE" == "yes" || "$UPDATE_CHOICE" == "y" ]]; then
	read_threshold() {
		local label="$1"
		local default="$2"
		local val
		while true; do
			read -p "  $label threshold % (default: $default): " val
			if [ -z "$val" ]; then
				echo "No input — using default: $default" >&2
				echo "$default"
				return
			fi
			if ! [[ "$val" =~ ^[0-9]+$ ]]; then
				echo "Warning: '$val' is not valid. Enter digits only, e.g. 75" >&2
				continue
			fi
			if [ "$val" -lt 1 ] || [ "$val" -gt 99 ]; then
				echo "Warning: Value must be between 1 and 99." >&2
				continue
			fi
			echo "$val"
			return
		done
	}
	WARNING_VAL=$(read_threshold "Warning" "75")
	FAILURE_VAL=$(read_threshold "Failure" "50")
	if [ "$FAILURE_VAL" -ge "$WARNING_VAL" ]; then
		echo "Warning: Conflict: Failure ($FAILURE_VAL%) must be lower than Warning ($WARNING_VAL%)."
        	echo "Warning: Reverting to defaults (warning=75, failure=50)."
        	WARNING_VAL=75
        	FAILURE_VAL=50
    	fi
	sed -i "s/\"warning\": [0-9]*/\"warning\": ${WARNING_VAL}/" "${PROJECT_DIR}/Helpers/config.json"
	sed -i "s/\"failure\": [0-9]*/\"failure\": ${FAILURE_VAL}/" "${PROJECT_DIR}/Helpers/config.json"
	echo "config.json updated -> warning: ${WARNING_VAL}%, failure: ${FAILURE_VAL}%"
else
	echo "Keeping defaults -> warning: 75%, failure: 50%."
fi
#Environment Validation
echo "Checking for python3..."
if command -v python3 &>/dev/null; then
	PY_VER=$(python3 --version 2>&1)
	echo "Found: $PY_VER"
	echo "Environment check passed. Application is ready to run."
else
	echo "WARNING: python3 is not installed on this system."
	echo "WARNING: attendance_checker.py will not run without it."
	echo "Install with: sudo apt install python3"
fi
