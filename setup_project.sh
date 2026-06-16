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
