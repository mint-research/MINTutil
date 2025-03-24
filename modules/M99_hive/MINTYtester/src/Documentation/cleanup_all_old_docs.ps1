# Cleanup All Old Documentation Script
# This script removes all old documentation files and folders that don't follow the new template structure
# It also removes all README.md files except the one in the root directory
# It enforces the rule that only the root directory should contain both files and subdirectories

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

    return $false
}

# Function to check if a directory is a valid module directory
function Test-ValidModuleDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath
    )

    # Get the directory name
    $dirName = Split-Path -Path $DirectoryPath -Leaf

    # Valid module directories
    $validModules = @("global", "M01_install", "M02_systeminfo", "M03_dummy", "project")

    if ($validModules -contains $dirName) {
        return $true
    }

    return $false
}

# Function to check if a directory contains both files and subdirectories
function Test-DirectoryContainsBoth {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath
    )

    # Get all items in the directory
    $items = Get-ChildItem -Path $DirectoryPath

    # Count files and directories
    $fileCount = ($items | Where-Object { -not $_.PSIsContainer }).Count
    $dirCount = ($items | Where-Object { $_.PSIsContainer }).Count

    # Check if the directory contains both files and subdirectories
    return $fileCount -gt 0 -and $dirCount -gt 0
}

# Function to enforce the rule that only the root directory should contain both files and subdirectories
function Enforce-DirectoryStructureRule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath,

        [Parameter(Mandatory = $false)]
        [bool]$IsRoot = $false,

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf = $false
    )

    # Skip if this is the root directory
    if ($IsRoot) {
        return 0
    }

    # Check if the directory contains both files and subdirectories
    if (Test-DirectoryContainsBoth -DirectoryPath $DirectoryPath) {
        Write-ColorOutput "Directory violates structure rule: $DirectoryPath" -ForegroundColor $warningColor
        Write-ColorOutput "Only the root directory should contain both files and subdirectories." -ForegroundColor $warningColor

        # Get all files in the directory
        $files = Get-ChildItem -Path $DirectoryPath -File

        # Create a subdirectory to move files to
        $subDirName = "files"
        $subDirPath = Join-Path -Path $DirectoryPath -ChildPath $subDirName

        # Check if the subdirectory already exists
        if (-not (Test-Path -Path $subDirPath)) {
            if (-not $WhatIf) {
                New-Item -Path $subDirPath -ItemType Directory -Force | Out-Null
                Write-ColorOutput "Created directory: $subDirPath" -ForegroundColor $infoColor
            } else {
                Write-ColorOutput "Would create directory: $subDirPath" -ForegroundColor $warningColor
            }
        }

        # Move all files to the subdirectory
        foreach ($file in $files) {
            $targetPath = Join-Path -Path $subDirPath -ChildPath $file.Name
            if ($WhatIf) {
                Write-ColorOutput "Would move file: $($file.FullName) -> $targetPath" -ForegroundColor $warningColor
            } else {
                Move-Item -Path $file.FullName -Destination $targetPath -Force
                Write-ColorOutput "Moved file: $($file.FullName) -> $targetPath" -ForegroundColor $successColor
            }
        }

        return $files.Count
    }

    return 0
}

# Function to remove old documentation files and directories
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
        # Skip files that follow the new template structure
        if (Test-NewTemplateFile -FilePath $file.FullName) {
            Write-ColorOutput "Keeping: $($file.FullName)" -ForegroundColor $infoColor
            continue
        }

        # Remove the file
        if ($WhatIf) {
            Write-ColorOutput "Would remove: $($file.FullName)" -ForegroundColor $warningColor
        } else {
            Remove-Item -Path $file.FullName -Force
            Write-ColorOutput "Removed: $($file.FullName)" -ForegroundColor $successColor
        }
        $removedFiles++
    }

    # Get all subdirectories
    $subdirectories = Get-ChildItem -Path $DirectoryPath -Directory

    $removedDirs = 0

    # Check each subdirectory
    foreach ($subdir in $subdirectories) {
        # If it's a valid module directory, process its files
        if (Test-ValidModuleDirectory -DirectoryPath $subdir.FullName) {
            # Enforce directory structure rule
            $movedFiles = Enforce-DirectoryStructureRule -DirectoryPath $subdir.FullName -IsRoot $false -WhatIf:$WhatIf

            # Process files in the subdirectory
            $subResult = Remove-OldDocumentationFiles -DirectoryPath $subdir.FullName -WhatIf:$WhatIf
            $removedFiles += $subResult
        } else {
            # Remove the entire directory
            if ($WhatIf) {
                Write-ColorOutput "Would remove directory: $($subdir.FullName)" -ForegroundColor $warningColor
            } else {
                Remove-Item -Path $subdir.FullName -Recurse -Force
                Write-ColorOutput "Removed directory: $($subdir.FullName)" -ForegroundColor $successColor
            }
            $removedDirs++
        }
    }

    return $removedFiles + $removedDirs
}

# Function to remove all README.md files except the one in the root directory
function Remove-AllReadmeFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath,

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf = $false
    )

    $removedFiles = 0

    # Get all README.md files
    $readmeFiles = Get-ChildItem -Path $DirectoryPath -Filter "README.md" -File -Recurse

    # Check each README.md file
    foreach ($file in $readmeFiles) {
        # Skip the README.md in the root directory
        if ($file.DirectoryName -eq $basePath) {
            Write-ColorOutput "Keeping root README: $($file.FullName)" -ForegroundColor $infoColor
            continue
        }

        # Remove the file
        if ($WhatIf) {
            Write-ColorOutput "Would remove README: $($file.FullName)" -ForegroundColor $warningColor
        } else {
            Remove-Item -Path $file.FullName -Force
            Write-ColorOutput "Removed README: $($file.FullName)" -ForegroundColor $successColor
        }
        $removedFiles++
    }

    return $removedFiles
}

# Main script execution
try {
    Write-ColorOutput "Starting cleanup of all old documentation files and directories..." -ForegroundColor $infoColor

    # Explain the directory structure rule
    Write-ColorOutput "`nDirectory Structure Rule:" -ForegroundColor $infoColor
    Write-ColorOutput "Only the root directory should contain both files and subdirectories." -ForegroundColor $infoColor
    Write-ColorOutput "All other directories should contain either files or subdirectories, but not both." -ForegroundColor $infoColor
    Write-ColorOutput "This script will move files to a 'files' subdirectory if a directory violates this rule." -ForegroundColor $infoColor

    # First run in WhatIf mode to show what would be removed
    Write-ColorOutput "`n=== Files and directories that would be removed or moved (dry run) ===" -ForegroundColor $infoColor

    # Enforce directory structure rule on docs directory
    Enforce-DirectoryStructureRule -DirectoryPath $docsPath -IsRoot $true -WhatIf

    $whatIfCountDocs = Remove-OldDocumentationFiles -DirectoryPath $docsPath -WhatIf
    $whatIfCountReadme = Remove-AllReadmeFiles -DirectoryPath $basePath -WhatIf
    $whatIfTotal = $whatIfCountDocs + $whatIfCountReadme

    # Ask for confirmation
    Write-ColorOutput "`n$whatIfTotal items would be removed or moved." -ForegroundColor $warningColor
    $confirmation = Read-Host "Do you want to proceed? (y/n)"

    if ($confirmation -eq "y" -or $confirmation -eq "Y") {
        # Run the actual removal
        Write-ColorOutput "`n=== Enforcing directory structure rule ===" -ForegroundColor $infoColor
        Enforce-DirectoryStructureRule -DirectoryPath $docsPath -IsRoot $true

        Write-ColorOutput "`n=== Removing old documentation files and directories ===" -ForegroundColor $infoColor
        $removedCountDocs = Remove-OldDocumentationFiles -DirectoryPath $docsPath

        Write-ColorOutput "`n=== Removing README.md files (except root) ===" -ForegroundColor $infoColor
        $removedCountReadme = Remove-AllReadmeFiles -DirectoryPath $basePath

        $totalRemoved = $removedCountDocs + $removedCountReadme

        Write-ColorOutput "`nRemoved or moved $totalRemoved items." -ForegroundColor $successColor
    } else {
        Write-ColorOutput "`nOperation cancelled. No files or directories were removed or moved." -ForegroundColor $infoColor
    }

    Write-ColorOutput "`nCleanup completed." -ForegroundColor $infoColor
} catch {
    Write-ColorOutput "Error during cleanup: $_" -ForegroundColor $errorColor
    Write-ColorOutput "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor $errorColor
    exit 1
}
