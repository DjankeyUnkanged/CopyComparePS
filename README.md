# Simple Copy and Compare PowerShell Script
## Overview
This PowerShell script is designed to copy files from a source directory to a destination directory and then compare the files using SHA256 hashing to ensure data integrity. It includes a graphical user interface (GUI) for selecting folders and displaying progress.

## Features
* Copy Files: Copies files from the source to the destination directory.
* File Comparison: Compares files between the source and destination using SHA256 hashing.
* Progress Bar: Displays a progress bar during the copy and comparison processes.
* Error Handling: Alerts the user if there are any issues with the source or destination directories or if any file mismatches are detected.
* Exclusions: Excludes common system and metadata folders from the copy and comparison processes.

## Prerequisites
* Windows PowerShell
* .NET Framework (for GUI components)

## How to Use
1. Run the Script: Execute the script in PowerShell.
2. Readiness Check: A prompt will ask if the source, destination, and (if needed) a separate disk for results are connected to the computer. Click ‘Yes’ to proceed.
3. Select Source: Choose the source directory containing the files to be copied.
4. Select Destination: Choose the destination directory where the files will be copied.
5. Copy Process: The script will copy the files and display a progress bar.
6. Comparison Process: After copying, the script will compare the files in the source and destination directories using SHA256 hashing and display a progress bar.
7. Save Results: Once the comparison is complete, choose a location to save the comparison results as a CSV file.
8. Completion: A message will confirm that the comparison results have been saved.

## Error Handling
* If the source or destination directories are invalid, the script will alert the user and exit.
* If any file mismatches are detected during the comparison, the script will alert the user to check the media and try again.

## Exclusions
The script excludes the following common system and metadata folders:
* .Trashes
* .Spotlight-V100
* .fseventsd
* System Volume Information

## Troubleshooting
### Common Issues and Solutions
1. Invalid Source or Destination
* Issue: The script alerts that the source or destination directory is invalid.
* Solution: Ensure that the directories are correctly connected and accessible. Verify the paths and try again.
2. File Mismatches Detected
* Issue: The script detects mismatches between the source and destination files.
* Solution: Check the integrity of the source media. Delete the destination copy and run the script again. Ensure no files are being modified during the copy process.
3. Progress Bar Not Displaying
* Issue: The progress bar does not appear during the copy or comparison processes.
* Solution: Ensure that the .NET Framework is installed and up to date. Restart PowerShell and try running the script again.
4. Script Exits Unexpectedly
* Issue: The script exits without completing the copy or comparison.
* Solution: Check for any error messages displayed by the script. Ensure all prerequisites are met and that there are no interruptions during the script execution.
5. CSV File Not Saving
* Issue: The script fails to save the comparison results as a CSV file.
* Solution: Verify the save location is accessible and has write permissions. Ensure the file path is valid and try saving again.

## Notes
* Ensure that the source and destination directories are correctly connected and accessible before running the script.
* The script is designed to handle common errors and provide user-friendly prompts and alerts.
