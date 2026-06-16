#!/bin/bash

#This is a script that creates directory structure, writes source files, configures thresholds, validates the environment, and handles SIGINT.

USER_INPUT=""
PROJECT_DIR=""

#Get project name from the user
echo "--------DIRECTORY ARCHITECTURE--------"
while true; do
	read -p "Enter a project tag (e.g. v1): " USER_INPUT
	if [-z "$USER_INPUT"]; then
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
echo "Finished writing to Helpers/assests.csv"
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
