# ~~Simple~~ Copy and Compare PowerShell Script
## Overview
This PowerShell script is designed to copy files from a source disk/directory to a destination disk/directory and then compare the files using SHA256 hashing to ensure data integrity. This script uses GUI elements, so no CLI familiarity is required for usage.

## Features
* **Copy Files:** Copies files from specified source to a specified destination.
* **File Comparison:** Compares files between the source and destination using SHA256 hashing.
* **Progress Bar:** Displays a progress bar during the copy and comparison processes. If the source and destination are fast enough, you may miss it!
* **Error Handling:** A dialog box should show an error message if something unexpected happens.
* **Exclusions:** Excludes common system and metadata folders from the copy and comparison processes.

## Prerequisites
* PowerShell
* .NET Framework (for GUI components)

If you're on Windows 10 22H2 or Windows 11, you shouldn't have to install anything.

## How to Use
1. **Run the Script:** Execute the script in PowerShell.
2. **Readiness Check:** A prompt will ask if the source, destination, and (if needed) a separate disk for results are connected to the computer. Click ‘Yes’ to proceed once you have verified.
3. **Select Source:** Choose the source directory or disk containing the files to be copied. 
4. **Select Destination:** Choose the destination directory or disk where the files will be copied.
5. **Copy Process:** The script will copy the files and may display a progress bar.
6. **Comparison Process:** After copying, the script will compare the source and destination directories using SHA256 hashing and may display a progress bar.
7. **Save Results:** Once the comparison is complete, choose a location to save the comparison results as a CSV file. This CSV is used to verify that every single file matches between source and destination. 
8. **Completion:** A message will confirm that the comparison results have been saved. You are done!

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
1. **Invalid Source or Destination**
* **Issue:** The script alerts that the source or destination directory is invalid.
* **Solution:** Ensure that the directories are correctly connected and accessible. Verify the paths and try again. Ensure that your destination is not write-protected.
2. **File Mismatches Detected**
* **Issue:** The script detects mismatches between the source and destination files.
* **Solution:** Check the integrity of the source media - inspect for scratches (if optical media) or damage. Delete the destination copy, or try again in a different destination, and run the script again. Ensure no files on either Source or Destination are open while the script is running.
3. **Progress Bar Not Displaying**
* **Issue:** The progress bar does not appear during the copy or comparison processes.
* **Solution:** As long as you didn't get an error, it's possible the file copy and hashing jobs went by so quickly that the progress bar didn't have time to appear. 
4. **Script Exits Unexpectedly**
* **Issue:** The script exits without completing the copy or comparison.
* **Solution:** Check for any error messages displayed by the script. Ensure all prerequisites are met and that there are no interruptions during the script execution.
5. **CSV File Not Saving**
* **Issue:** The script fails to save the comparison results as a CSV file.
* **Solution:** Verify the save location is accessible and is not write-protected. Ensure the file path is valid and try saving again.
