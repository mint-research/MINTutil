# Cleanup Old Documentation Script
# This script removes old documentation files that don't follow the new template structure

# Set error action preference to stop on errors
$ErrorActionPreference = "Stop"

# Define colors for console output
$successColor = "Green"
$warningColor = "Yellow"
$errorColor = "Red"
$infoColor = "Cyan"

# Define the base path for the project
$basePath = $PSScriptRoot | Split-Path -Parent
$docsPath = Join-Path -Path $basePath -ChildPath "docs"

# Function to write colored output
function Write-ColorOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$ForegroundColor = "White"
    )

    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Function to check if a file follows the new template structure
function Test-NewTemplateFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Get the file name
    $fileName = Split-Path -Path $FilePath -Leaf

    # Check if the file name matches the new template pattern (e.g., 1_Einführung.md)
    if ($fileName -match "^\d+_.+\.md$") {
        return $true
    }

    # Special case for README.md in the root directory
    if ($fileName -eq "README.md" -and (Split-Path -Path (Split-Path -Path $FilePath -Parent) -Leaf) -eq "docs") {
        return $false
    }

    return $false
}

# Function to remove old documentation files
function Remove-OldDocumentationFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath,

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf = $false
    )

    # Get all markdown files in the directory
    $files = Get-ChildItem -Path $DirectoryPath -Filter "*.md" -File

    $removedFiles = 0

    # Check each file
    foreach ($file in $files) {
        if (-not (Test-NewTemplateFile -FilePath $file.FullName)) {
            if ($WhatIf) {
                Write-ColorOutput "Would remove: $($file.FullName)" -ForegroundColor $warningColor
            } else {
                Remove-Item -Path $file.FullName -Force
                Write-ColorOutput "Removed: $($file.FullName)" -ForegroundColor $successColor
            }
            $removedFiles++
        } else {
            Write-ColorOutput "Keeping: $($file.FullName)" -ForegroundColor $infoColor
        }
    }

    # Process subdirectories
    $subdirectories = Get-ChildItem -Path $DirectoryPath -Directory

    foreach ($subdir in $subdirectories) {
        # Skip the TEMP directory
        if ($subdir.Name -eq "TEMP") {
            continue
        }

        $subResult = Remove-OldDocumentationFiles -DirectoryPath $subdir.FullName -WhatIf:$WhatIf
        $removedFiles += $subResult
    }

    return $removedFiles
}

# Main script execution
try {
    Write-ColorOutput "Starting cleanup of old documentation files..." -ForegroundColor $infoColor

    # First run in WhatIf mode to show what would be removed
    Write-ColorOutput "`n=== Files that would be removed (dry run) ===" -ForegroundColor $infoColor
    $whatIfCount = Remove-OldDocumentationFiles -DirectoryPath $docsPath -WhatIf

    # Ask for confirmation
    Write-ColorOutput "`n$whatIfCount files would be removed." -ForegroundColor $warningColor
    $confirmation = Read-Host "Do you want to proceed with removal? (y/n)"

    if ($confirmation -eq "y" -or $confirmation -eq "Y") {
        # Run the actual removal
        Write-ColorOutput "`n=== Removing old documentation files ===" -ForegroundColor $infoColor
        $removedCount = Remove-OldDocumentationFiles -DirectoryPath $docsPath

        Write-ColorOutput "`nRemoved $removedCount old documentation files." -ForegroundColor $successColor
    } else {
        Write-ColorOutput "`nOperation cancelled. No files were removed." -ForegroundColor $infoColor
    }

    Write-ColorOutput "`nCleanup completed." -ForegroundColor $infoColor
} catch {
    Write-ColorOutput "Error during cleanup: $_" -ForegroundColor $errorColor
    Write-ColorOutput "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor $errorColor
    exit 1
}
