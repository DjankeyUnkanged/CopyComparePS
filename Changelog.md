#CopyComparePS Update History

### Version 0.97 - Jan 30, 2025
Oops, I forgot to update this alongside the script x.x
Addition - 'SizeCheck' function that will take an input number (SizeInBytes) and convert it to the largest relevant data unit, up to Terabytes.
Change - Any instance where the script was doing manual rounding for size in Bytes is now using the SizeCheck function instead, now showing different units instead of JUST Megabytes.

### Version 0.95.1 - Jan 17, 2025
Change - Reference to picking a destination for the results file was removed from a dialog box. No functionality changes.

### Version 0.95 - Jan 17, 2025
Bug Fix - Fixed issue that would break the comparison routine if the source only contained a single file.
Change - User is no longer asked where they would like to save the comparison results
Change - Check if C:\temp folder exists and creates it if it does not exist. Result CSV is automatically saved under C:\temp with a datestamp, like YYYYMMDD_HHMMSS_CopyCompare_result.csv if the directory exists, and is writable.

### Version 0.9 - Jan 14, 2025
Initial versioning added for keeping track of offline usage. Functionally no different from the Jan 2, 2025 version.
