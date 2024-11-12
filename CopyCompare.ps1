# 'Simple' copy and compare PowerShell script
# 
# Description: This script will ask for a source and destination, copy the source to the destination, and then compare the files between the two using SHA256 hashing.
# It should throw errors if entries are invalid, or if the data comparison fails for whatever reason. I have tried to add exclusions for common metatdata or system folders
# that don't actually contain any user data. I have done this because these system/metadata folders don't always copy, and can lead to misleading results. The focus is to copy
# the actual contents of the disk or folder into the destination without any changes or loss of data. Assuming the source media is in good shape, this should work without a fuss.

# Load the necessary assembly
Add-Type -AssemblyName System.Windows.Forms # This is for Explorer open/save/browse prompts
Add-Type -AssemblyName PresentationFramework # This is for GUI alert/dialog boxes

# Set metadata/system folder exception variable
$ExceptionList = ".Trashes",".Spotlight-V100",".fseventsd","System Volume Information"

# Function to select a folder
function Select-FolderDialog {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Please select a folder."
    $folderBrowser.ShowNewFolderButton = $true
    $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer
    $folderBrowser.ShowDialog() | Out-Null
    return $folderBrowser.SelectedPath
}

# Function to select a file save location
function Select-SaveFileDialog {
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Filter = "CSV files (*.csv)|*.csv"
    $saveFileDialog.Title = "Save Comparison Results"
    $saveFileDialog.InitialDirectory = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments)
    $saveFileDialog.ShowDialog() | Out-Null
    return $saveFileDialog.FileName
}

function Show-ProgressBar {
    param (
        [int]$Progress,
        [switch]$Done
    )

    begin {
        if (-not $script:form) {
            # Create a form
            $script:form = New-Object System.Windows.Forms.Form
            $script:form.Text = "Progress"
            $script:form.Width = 400
            $script:form.Height = 100
            $script:form.StartPosition = "CenterScreen"

            $script:progressBar = New-Object System.Windows.Forms.ProgressBar
            $script:progressBar.Minimum = 0
            $script:progressBar.Maximum = 100
            $script:progressBar.Width = 350
            $script:progressBar.Height = 30
            $script:progressBar.Value = 0
            $script:progressBar.Style = "Continuous"
            $script:progressBar.Location = New-Object System.Drawing.Point(20, 20)
            $script:form.Controls.Add($script:progressBar)
            
            # Show the form
            $script:form.Show()
        }
    }

    process {
        if ($Done) {
            # Close the form once switch is called
            $script:form.Close()
            Remove-Variable -Name form -Scope Script
            Remove-Variable -Name progressBar -Scope Script
        } else {
            # Update progress
            $script:progressBar.Value = $Progress
            [System.Windows.Forms.Application]::DoEvents() # Force the UI to process events
        }
    }
}


# Function for Progress + Copy
function CopyShowProgress {
    param (
        [string]$source,
        [string]$destination,
        [array]$exceptions
    )

    # Get all items in the source directory
    $items = Get-ChildItem -Path $source -Recurse -Exclude $exceptions
    $totalItems = (Get-ChildItem -Path $source -File -Recurse -Exclude $exceptions).Count
    $processedItems = 0

    # Initialize the progress bar
    Show-ProgressBar -Progress 0

    foreach ($item in $items) {
        # Get the relative path of the item
        $relativePath = $item.FullName.Substring($source.Length).TrimStart('\')

        # Get the root folder of the item
        $rootFolder = $relativePath.Split('\')[0]

        # Check if the root folder is in the exception list
        if ($exceptions -notcontains $rootFolder) {
            # Determine the destination path
            $destPath = Join-Path -Path $destination -ChildPath $relativePath

            if ($item.PSIsContainer) {
                # Create the directory if it doesn't exist
                if (-not (Test-Path -Path $destPath)) {
                    New-Item -ItemType Directory -Path $destPath
                }
            } else {
                # Copy the file
                Copy-Item -Path $item.FullName -Destination $destPath -Force

                # Update progress
                $processedItems++
                $progressPercentage = [math]::Round(($processedItems / $totalItems) * 100)
                Show-ProgressBar -Progress $progressPercentage
            }
        }
    }

    # Close the progress bar
    Show-ProgressBar -Done
}
    
# Check if user is ready and remind to have source and destination attached
$QuickCheck = [System.Windows.MessageBox]::Show('Are Source, Destination and, if needed, a separate disk for the results connected to this computer?','Readiness check','YesNo','Question')

# Check the response of the above prompt and act accordingly (Proceed on Yes, cancel on No)
if ($QuickCheck -ieq 'Yes') {
    # Pick disk or directory to copy from
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.MessageBox]::Show("In the following window, please choose the source of data to be copied.",'Choose data source','OK','Information')
    $CopySrc = Select-FolderDialog
    
    # Throw an error and exit if the source is invalid
    if ($CopySrc -eq "") {
        [System.Windows.MessageBox]::Show('The source does not appear to be valid. Exiting...','Invalid source','OK','Exclamation')
        return
    }

    # Pick disk or directory to copy source data to
    [System.Windows.MessageBox]::Show("In the following window, please choose the destination where data is to be copied.",'Choose data destination','OK','Information')
    $CopyDst = Select-FolderDialog

    # Throw an error and exit if the destination is invalid
    if ($CopyDst -eq "") {
        [System.Windows.MessageBox]::Show('The destination does not appear to be valid. Exiting...','Invalid destination','OK','Exclamation')
        return
    }

    # Copy from source to destination. Source has backslash and asterisk added to properly handle the source whether it's a root directory in a drive, or a folder. Exclusions for system/metadata folders added.
    # Copy-Item -Path "$CopySrc\*" -Destination $CopyDst -Recurse -Force -Exclude $ExceptionList

    CopyShowProgress -source $CopySrc -destination $CopyDst -exceptions $ExceptionList

    # Run a loop - For each file in the source, gather data and get the SHA256 of each file. Mark each entry as 'Source' in the array.
    $SrcFiles = Get-ChildItem $CopySrc -Recurse -File -Exclude $ExceptionList | ForEach-Object {
        [PSCustomObject]@{
            Path = $_.FullName
            Hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
            Size = $_.Length
            Name = $_.Name
            Source = 'Source'
        }
    }

    # Run a loop - For each file in the destination, gather data and get the SHA256 of each file. Mark each entry as 'Destination' in the array.
    $DestFiles = Get-ChildItem $CopyDst -Recurse -File -Exclude $ExceptionList | ForEach-Object {
        [PSCustomObject]@{
            Path = $_.FullName
            Hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
            Size = $_.Length
            Name = $_.Name
            Source = 'Destination'
        }
    }

    # Initialize comparison array
    $Comparison = @()
    
    # Create array by adding the source file and destination file arrays together into one, organizing by SHA256 hash and file name. If all goes well in the copy, there should be two of every file (1 in source, 1 in destination), no more, no less.
    # Grouping by object name alone doesn't work because sources can have multiple files with the same name, but different hashes - this throws the array off, breaking the script. Using two parameters avoids this issue.
    $FileGroups = ($SrcFiles + $DestFiles) | Group-Object Hash,Name
    
    # Initialize variable (think canary in a coal mine)
    $FailCanary = 'True'

    # For each grouping, compare the hash between source and destination. If there is a single mismatch, our FailCanary variable switches to false to set up an error message.
    foreach ($group in $FileGroups) {
        $srcFile = $group.Group | Where-Object { $_.Source -eq 'Source' }
        $destFile = $group.Group | Where-Object { $_.Source -eq 'Destination' }

        $Comparison += [PSCustomObject]@{
            Name = $srcFile.Name
            SrcPath = $srcFile.Path
            DstPath = $destFile.Path
            SrcHash = $srcFile.Hash
            DstHash = $destFile.Hash
            SrcSizeInBytes = $srcFile.Size
            DstSizeInBytes = $destFile.Size
            Match = ($srcFile.Hash -eq $destFile.Hash)
        }
        if ($srcFile.Hash -ne $destFile.Hash) {$FailCanary = 'False'}
    }

    # Here's where that FailCanary variable comes in. If the variable has been set to false, there was a mismatch or unhandled error somewhere along the way
    if ($FailCanary -ieq 'False') {
        [System.Windows.MessageBox]::Show('At least one file has failed to verify between source and destination. Please check your media, delete the destination copy, and try again.','Mismatch detected','OK','Exclamation')
    }
    
    # If the script made it to this point, the copy and compare has worked up to this point, even if there was a file mismatch or two. Now to choose the destination for the CSV containing the comparison results.
    [System.Windows.MessageBox]::Show("Copy and compare complete! In the following window, please choose where you would like to save the comparison results.",'Copy and compare done!','OK','Information')
    $CsvPath = Select-SaveFileDialog
    if ($CsvPath -eq "") {
        [System.Windows.MessageBox]::Show('The destination does not appear to be valid. Exiting...','Invalid destination','OK','Exclamation')
        return
    }
    $Comparison | Export-Csv -Path $CsvPath -NoTypeInformation

    [System.Windows.MessageBox]::Show("Comparison results have been saved to $CsvPath.",'Done!','OK','Information')

    # Display the comparison table in console
    $Comparison | Format-Table -Property Name, SrcPath, DstPath, SrcHash, DstHash, SrcSizeInBytes, DstSizeInBytes, Match
} else {
    # You shouldn't run the script if you're not ready!!!!
    [System.Windows.MessageBox]::Show('Please make sure Source and Destination are ready, and re-open this script.','Readiness check fail','OK','Exclamation')
}
