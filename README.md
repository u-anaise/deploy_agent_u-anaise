# deploy_agent_u-anaise

## Video Walkthrough 
[Click here to watch the walkthrough video](https://drive.google.com/file/d/1v3wUW5gciWTCDousWZalprr4t0CfxElS/view?usp=sharing)

`setup_project.sh` is a shell script that sets up the Student Attendance Tracker workspace automatically. It creates the required directories, writes all source files, lets you configure thresholds, validates your Python installation, and handles interruptions.

## Requirements

- Bash (Linux, WSL, or macOS)
- python3 (to run the tracker after the setup)

## How to run

**Step 1 — Clone the repository**
 
```bash
git clone https://github.com/u-anaise/deploy_agent_u-anaise.git
cd deploy_agent_u-anaise
```
 
**Step 2 — Make the script executable**
 
```bash
chmod +x setup_project.sh
```
 
**Step 3 — Run it**
 
```bash
./setup_project.sh
```
 
**Step 4 — Follow the prompts**
 
The script will ask you:
- A project name suffix (e.g. `v1`), which creates the folder `attendance_tracker_v1/`
- Whether you want to update the default attendance thresholds (Warning: 75%, Failure: 50%)
If you enter a threshold, it must be a whole number between 0 and 100. The script will reject letters, symbols, empty input, or a failure value that is higher than the warning value, and will ask you to try again.
 
**Step 5 — Run the attendance checker**
 
Once setup finishes, run the Python app inside the generated project:
 
```bash
cd attendance_tracker_v1
python3 attendance_checker.py
```
 
The results are saved to `reports/reports.log`.

## What gets created
attendance_tracker_{tag}/

├── attendance_checker.py

├── Helpers/

│   ├── assets.csv

│   └── config.json

└── reports/

└── reports.log



You'll also get the option to update the warning and failure thresholds.
The script validates your input; letters or out-of-range numbers get rejected before anything touches the config file.

## Config File Reference (`config.json`)
 
```json
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
```

## Running the tracker

```bash
cd attendance_tracker_v1
python3 attendance_checker.py
```

Alerts are written to `reports/reports.log`.

## How to trigger the archive feature (The Trap function)

The script registers a signal trap at the very start, before any directories are created:
 
```bash
trap handle_interrupt SIGINT
```
 
If you press **Ctrl+C at any point during setup**, instead of the script dying immediately, it runs the `handle_interrupt` function which catches the SIGINT signal and:
 
1. Checks whether a project directory was already created (`-n "$PROJECT_DIR"` and `-d "$PROJECT_DIR"`)
2. If yes, compresses it into an archive named `attendance_tracker_{input}_archive.tar.gz`
3. Deletes the incomplete project directory. You get a snapshot of the state without leaving a half-built folder sitting in your workspace.
4. Exits safely with a status message

**To trigger it yourself:** Run `./setup_project.sh`, enter a project name, then press `Ctrl+C` when it asks about thresholds. You will see the archive created and the incomplete folder removed automatically.

## Edge Cases Handled (Error handling)

| Input / Situation | What happens |
|---|---|
| Empty project tag | Asks again (up to 3 times then exits)|
| Tag with spaces | Asks again |
| Tag already exists as a directory | Exits with a message |
| mkdir permission failure | Exits with a message |
| Non-numeric threshold (e.g. `abc`) | Asks again (up to 3 times then uses default)|
| Threshold outside 1–99 | Asks again |
| Failure % ≥ Warning % | Reverts both to defaults |
| python3 not found | Warns you, but the setup still completes |
| Ctrl+C at any point | Archives the existing state, deletes the directory |

## File Descriptions
 
| File | Purpose |
|---|---|
| `attendance_checker.py` | Python script that reads the CSV, calculates attendance %, and logs alerts |
| `Helpers/assets.csv` | Student records: name, email, attendance count, absence count |
| `Helpers/config.json` | Configuration: thresholds, run mode, total sessions |
| `reports/reports.log` | Output log written each time the Python script runs |
 
---
 
## Version Control Notes
 
- Only `setup_project.sh` and this `README.md` are committed to the repository
- The generated project folders are excluded (they are created locally by the script)
