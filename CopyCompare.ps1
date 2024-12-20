# 'Simple' copy and compare PowerShell script
# 
# Description: This script will ask for a source and destination, copy the source to the destination, and then compare the files between the two using SHA256 hashing.
# It should throw errors if entries are invalid, or if the data comparison fails for whatever reason. I have tried to add exclusions for common metatdata or system folders
# that don't actually contain any user data. I have done this because these system/metadata folders don't always copy, and can lead to misleading results. The focus is to copy
# the actual contents of the disk or folder into the destination without any changes or loss of data. Assuming the source media is in good shape, this should work without a fuss.

# Load the necessary assembly
Add-Type -AssemblyName System.Windows.Forms # This is for Explorer open/save/browse prompts
Add-Type -AssemblyName PresentationFramework # This is for GUI alert/dialog boxes
[System.Windows.Forms.Application]::EnableVisualStyles()

# Define MessageBox function so all MessageBox objects appear on top
function Show-MessageBox {
    param (
        [string]$Message,
        [string]$Title,
        [string]$Buttons,
        [string]$Icon
    )

    # Preset parameters for the MessageBox
    $MsgWindow = New-Object System.Windows.Window
    $MsgWindow.Topmost = $true
    $MsgWindow.WindowStyle = 'None'
    $MsgWindow.ShowInTaskbar = $false
    $MsgWindow.ShowActivated = $false
    $MsgWindow.Width = 0
    $MsgWindow.Height = 0
    $MsgWindow.Show()

    # Show the MessageBox with $MsgWindow as the parent object
    $result = [System.Windows.MessageBox]::Show($MsgWindow, $Message, $Title, $Buttons, $Icon)

    # Close the parent window
    $MsgWindow.Close()

    return $result
}

# Define Xaml for progress bar window
$xamlTemplate = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="{0}" Height="150" Width="400" WindowStartupLocation="CenterScreen" Topmost="True">
    <Grid>
        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
            <ProgressBar Name="progressBar" Width="350" Height="30" Minimum="0" Maximum="100" Value="{1}" HorizontalAlignment="Center"/>
            <Grid Width="350" Margin="0,10,0,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="*" />
                </Grid.ColumnDefinitions>
                <TextBlock Name="fileSizeText" Text="{2} MB" HorizontalAlignment="Left" Grid.Column="0"/>
                <TextBlock Name="progressText" Text="{1}%" HorizontalAlignment="Right" Grid.Column="1"/>
            </Grid>
        </StackPanel>
    </Grid>
</Window>
"@

function Show-ProgressBar {
    param (
        [int]$Progress,
        [string]$Title,
        [int]$FileSizeBytes,
        [switch]$Done
    )

    begin {
        if (-not $script:window) {
            # Convert file size to MB
            $fileSizeMB = [math]::Round($FileSizeBytes / 1MB, 2)

            # Replace placeholders in the XAML template
            $xaml = [string]::Format($xamltemplate, $Title, $Progress, "$fileSizeMB")

            # Load the XAML
            $reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader $xaml))
            $script:window = [Windows.Markup.XamlReader]::Load($reader)

            # Find the elements
            $script:progressBar = $script:window.FindName("progressBar")
            $script:fileSizeText = $script:window.FindName("fileSizeText")
            $script:progressText = $script:window.FindName("progressText")

            # Show the window
            $script:window.Show()
        }
    }

    process {
        if ($Done) {
            # Close the window once switch is called
            $script:window.Close()
            Remove-Variable -Name window -Scope Script
            Remove-Variable -Name progressBar -Scope Script
            Remove-Variable -Name fileSizeText -Scope Script
            Remove-Variable -Name progressText -Scope Script
        } else {
            # Convert file size to MB
            $fileSizeMB = [math]::Round($FileSizeBytes / 1MB, 2)
            # Update progress
            $script:progressBar.Value = $Progress
            $script:progressText.Text = "$Progress%"
            $script:fileSizeText.Text = "$fileSizeMB MB"
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action] { }, [System.Windows.Threading.DispatcherPriority]::Background)
        }
    }
}

# Set metadata/system folder exception variable
$ExceptionList = ".Trashes",".Spotlight-V100",".fseventsd","System Volume Information"

# Function to select a folder
function Select-FolderDialog {
    $form = New-Object System.Windows.Forms.Form
    $form.TopMost = $true
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Please select a folder."
    $folderBrowser.ShowNewFolderButton = $true
    $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer
    $folderBrowser.ShowDialog($form) | Out-Null
    return $folderBrowser.SelectedPath
}

# Function to select a file save location
function Select-SaveFileDialog {
    $form = New-Object System.Windows.Forms.Form
    $form.TopMost = $true
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Filter = "CSV files (*.csv)|*.csv"
    $saveFileDialog.Title = "Save Comparison Results"
    $saveFileDialog.InitialDirectory = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments)
    $saveFileDialog.ShowDialog($form) | Out-Null
    return $saveFileDialog.FileName
}

# Function for Progress + Copy
function Copy-Files {
    param (
        [string]$source,
        [string]$destination,
        [array]$exceptions
    )

    # Get all items in the source directory
    $items = Get-ChildItem -LiteralPath $source -Recurse -Exclude $exceptions
    $totalItems = (Get-ChildItem -LiteralPath $source -File -Recurse -Exclude $exceptions).Count
    $processedItems = 0

    # Initialize the progress bar
    Show-ProgressBar -Title "File Copy Progress"

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
                if (-not (Test-Path -LiteralPath $destPath)) {
                    New-Item -ItemType Directory -Path $destPath
                }
            } else {
                # Copy the file
                Copy-Item -LiteralPath $item.FullName -Destination $destPath -Force

                # Update progress
                $processedItems++
                $progressPercentage = [math]::Round(($processedItems / $totalItems) * 100)
                Show-ProgressBar -Progress $progressPercentage $FileSizeBytes $item.Length
            }
        }
    }

    # Close the progress bar
    Show-ProgressBar -Done
}
    
# Check if user is ready and remind to have source and destination attached
$QuickCheck = Show-MessageBox -Message 'Are Source, Destination and, if needed, a separate disk for the results connected to this computer?' -Title 'Readiness check' -Buttons 'YesNo' -Icon 'Question'

# Check the response of the above prompt and act accordingly (Proceed on Yes, cancel on No)
if ($QuickCheck -ieq 'Yes') {
    # Pick disk or directory to copy from
    Show-MessageBox -Message "In the following window, please choose the source of data to be copied." -Title 'Choose data source' -Buttons 'OK' -Icon 'Information'
    $CopySrc = Select-FolderDialog
    
    # Throw an error and exit if the source is invalid
    if ($CopySrc -eq "") {
        Show-MessageBox -Message 'The source does not appear to be valid. Exiting...' -Title 'Invalid source' -Buttons 'OK' -Icon 'Exclamation'
        return
    }

    # Run a loop - For each file in the source, gather data and get the SHA256 of each file. Mark each entry as 'Source' in the array.
    $SrcCount = 0
    $SrcTotal = 0
    $SrcFileTotal = (Get-ChildItem -LiteralPath $CopySrc -Recurse -File -Exclude $ExceptionList).Count
    $SrcFiles = Get-ChildItem -LiteralPath $CopySrc -Recurse -File -Exclude $ExceptionList | ForEach-Object {
        [PSCustomObject]@{
            Path = $_.FullName
            Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
            Size = $_.Length
            Name = $_.Name
            Source = 'Source'
        }
        $SrcTotal += $_.Length
        $SrcCount++
        $SrcFilePercentage = [math]::Round(($SrcCount / $SrcFileTotal) * 100)
        Show-ProgressBar -Title "Source Hash Progress" -Progress $SrcFilePercentage -FileSizeBytes $_.Length
    }
    Show-ProgressBar -Done

    $SrcTotalMB = [math]::Round($SrcTotal / 1MB, 2)
    Show-MessageBox -Message "Total size of data from the source data is $SrcTotalMB." -Title 'Source Data Size' -Buttons 'OK' -Icon 'Information'

    # Pick disk or directory to copy source data to
    Show-MessageBox -Message "In the following window, please choose the destination where data is to be copied." -Title 'Choose data destination' -Buttons 'OK' -Icon 'Information'
    $CopyDst = Select-FolderDialog

    # Throw an error and exit if the destination is same as source or invalid
    if (($CopyDst -eq "") -or ($CopyDst -ieq $CopySrc)) {
        Show-MessageBox -Message 'The destination matches the source or is otherwise invalid. Exiting...' -Title 'Invalid destination' -Buttons 'OK' -Icon 'Exclamation'
        return
    }

    Copy-Files -source $CopySrc -destination $CopyDst -exceptions $ExceptionList

    # Run a loop - For each file in the destination, gather data and get the SHA256 of each file. Mark each entry as 'Destination' in the array.
    $DestCount = 0
    $DestFileTotal = (Get-ChildItem $CopyDst -Recurse -File -Exclude $ExceptionList).Count
    $DestFiles = Get-ChildItem $CopyDst -Recurse -File -Exclude $ExceptionList | ForEach-Object {
        [PSCustomObject]@{
            Path = $_.FullName
            Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
            Size = $_.Length
            Name = $_.Name
            Source = 'Destination'
        }
        $DestCount++
        $DestFilePercentage = [math]::Round(($DestCount / $DestFileTotal) * 100)
        Show-ProgressBar -Title "Destination Hash Progress" -Progress $DestFilePercentage -FileSizeBytes $_.Length
    }
    Show-ProgressBar -Done

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
            SrcSizeInMB = ([math]::Round($srcFile.Size / 1MB, 2))
            SrcSizeInBytes = $srcFile.Size
            DstSizeInMB = ([math]::Round($destFile.Size / 1MB, 2))
            DstSizeInBytes = $destFile.Size
            Match = ($srcFile.Hash -eq $destFile.Hash)
        }
        if ($srcFile.Hash -ne $destFile.Hash) {$FailCanary = 'False'}
    }

    # Here's where that FailCanary variable comes in. If the variable has been set to false, there was a mismatch or unhandled error somewhere along the way
    if ($FailCanary -ieq 'False') {
        Show-MessageBox -Message 'At least one file has failed to verify between source and destination. Please check your media, delete the destination copy, and try again.' -Title 'Mismatch detected' -Buttons 'OK' -Icon 'Exclamation'
    }
    
    # If the script made it to this point, the copy and compare has worked up to this point, even if there was a file mismatch or two. Now to choose the destination for the CSV containing the comparison results.
    Show-MessageBox -Message "Copy and compare complete! In the following window, please choose where you would like to save the comparison results." -Title 'Copy and compare done!' -Buttons 'OK' -Icon 'Information'
    $CsvPath = Select-SaveFileDialog
    if ($CsvPath -eq "") {
        Show-MessageBox -Message 'The destination does not appear to be valid. Exiting...' -Title 'Invalid destination' -Buttons 'OK' -Icon 'Exclamation'
        return
    }
    $Comparison | Export-Csv -Path $CsvPath -NoTypeInformation

    Show-MessageBox -Message "Comparison results have been saved to $CsvPath." -Title 'Done!' -Buttons 'OK' -Icon 'Information'

    # (Optional) Display the comparison table in console
    # $Comparison | Format-Table -Property Name, SrcPath, DstPath, SrcHash, DstHash, SrcSizeInBytes, DstSizeInBytes, Match
} else {
    # You shouldn't run the script if you're not ready!!!!
    Show-MessageBox -Message 'Please make sure Source and Destination are ready, and re-open this script.' -Title 'Readiness check fail' -Buttons 'OK' -Icon 'Exclamation'
}
