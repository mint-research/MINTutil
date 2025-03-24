# Verify Documentation Script
# This script checks if all required documentation files exist

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

# Function to check if a file exists
function Test-DocumentationFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (Test-Path -Path $FilePath) {
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

# Function to verify that directories follow the rule:
# Only the root directory should contain both subdirectories and files
function Test-DirectoryStructure {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath,

        [Parameter(Mandatory = $false)]
        [bool]$IsRoot = $false
    )

    # Get all items in the directory
    $items = Get-ChildItem -Path $DirectoryPath

    # Count files and directories
    $fileCount = ($items | Where-Object { -not $_.PSIsContainer }).Count
    $dirCount = ($items | Where-Object { $_.PSIsContainer }).Count

    # Check if the directory contains both files and subdirectories
    $containsBoth = $fileCount -gt 0 -and $dirCount -gt 0

    # If it's not the root directory and contains both, it violates the rule
    if (-not $IsRoot -and $containsBoth) {
        Write-ColorOutput "Warning: Directory $DirectoryPath contains both files and subdirectories." -ForegroundColor $warningColor
        Write-ColorOutput "Only the root directory should contain both. Other directories should contain either files or subdirectories, but not both." -ForegroundColor $warningColor
        return $false
    }

    # Check all subdirectories recursively
    $result = $true
    foreach ($subdir in ($items | Where-Object { $_.PSIsContainer })) {
        $subdirResult = Test-DirectoryStructure -DirectoryPath $subdir.FullName -IsRoot $false
        if (-not $subdirResult) {
            $result = $false
        }
    }

    return $result
}

# Function to verify documentation for a module
function Test-ModuleDocumentation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    Write-ColorOutput "`nVerifying documentation for module: $ModuleName" -ForegroundColor $infoColor

    # Define the module documentation path
    $moduleDocsPath = Join-Path -Path $docsPath -ChildPath $ModuleName

    # Define required documentation files
    $requiredFiles = @(
        "1_Einführung.md",
        "2_Anwendungsfälle.md",
        "3_Benutzererfahrung.md",
        "4_Funktionalitäten.md",
        "5_Dokumentation.md"
    )

    $missingFiles = 0
    $totalFiles = $requiredFiles.Count

    # Check each required file
    foreach ($fileName in $requiredFiles) {
        $filePath = Join-Path -Path $moduleDocsPath -ChildPath $fileName

        if (Test-DocumentationFile -FilePath $filePath) {
            Write-ColorOutput "✓ Found: $filePath" -ForegroundColor $successColor
        } else {
            Write-ColorOutput "✗ Missing: $filePath" -ForegroundColor $warningColor
            $missingFiles++
        }
    }

    # Return summary
    return @{
        ModuleName   = $ModuleName
        MissingFiles = $missingFiles
        TotalFiles   = $totalFiles
    }
}

# Function to verify project documentation
function Test-ProjectDocumentation {
    Write-ColorOutput "`nVerifying project documentation files" -ForegroundColor $infoColor

    # Define the project documentation path
    $projectDocsPath = Join-Path -Path $docsPath -ChildPath "project"

    # Check if the project directory exists
    if (-not (Test-Path -Path $projectDocsPath)) {
        Write-ColorOutput "✗ Missing project documentation directory: $projectDocsPath" -ForegroundColor $warningColor
        return @{
            ModuleName   = "Project"
            MissingFiles = 5
            TotalFiles   = 5
        }
    }

    # Define required project documentation files
    $requiredFiles = @(
        "1_Einführung.md",
        "2_Anwendungsfälle.md",
        "3_Benutzererfahrung.md",
        "4_Funktionalitäten.md",
        "5_Dokumentation.md"
    )

    $missingFiles = 0
    $totalFiles = $requiredFiles.Count

    # Check each required file
    foreach ($fileName in $requiredFiles) {
        $filePath = Join-Path -Path $projectDocsPath -ChildPath $fileName

        if (Test-DocumentationFile -FilePath $filePath) {
            Write-ColorOutput "✓ Found: $filePath" -ForegroundColor $successColor
        } else {
            Write-ColorOutput "✗ Missing: $filePath" -ForegroundColor $warningColor
            $missingFiles++
        }
    }

    # Return summary
    return @{
        ModuleName   = "Project"
        MissingFiles = $missingFiles
        TotalFiles   = $totalFiles
    }
}

# Main script execution
try {
    Write-ColorOutput "Starting documentation verification..." -ForegroundColor $infoColor

    # Verify directory structure
    Write-ColorOutput "`nVerifying directory structure..." -ForegroundColor $infoColor
    $structureResult = Test-DirectoryStructure -DirectoryPath $docsPath -IsRoot $true

    if ($structureResult) {
        Write-ColorOutput "✓ Directory structure follows the rule: Only the root directory contains both files and subdirectories." -ForegroundColor $successColor
    } else {
        Write-ColorOutput "✗ Directory structure violates the rule. Please fix the issues mentioned above." -ForegroundColor $warningColor
    }

    # Verify project documentation
    $projectResult = Test-ProjectDocumentation

    # Define modules to verify
    $modules = @(
        "global",
        "M01_install",
        "M02_systeminfo",
        "M03_dummy"
    )

    # Verify each module's documentation
    $moduleResults = @()
    foreach ($module in $modules) {
        $result = Test-ModuleDocumentation -ModuleName $module
        $moduleResults += $result
    }

    # Display summary
    Write-ColorOutput "`n=== Documentation Verification Summary ===" -ForegroundColor $infoColor

    $projectMissing = $projectResult.MissingFiles
    $projectTotal = $projectResult.TotalFiles
    $projectColor = if ($projectMissing -eq 0) { $successColor } else { $warningColor }
    Write-ColorOutput "Project documentation: $projectMissing files missing (of $projectTotal required)" -ForegroundColor $projectColor

    foreach ($result in $moduleResults) {
        $moduleName = $result.ModuleName
        $moduleMissing = $result.MissingFiles
        $moduleTotal = $result.TotalFiles
        $moduleColor = if ($moduleMissing -eq 0) { $successColor } else { $warningColor }
        Write-ColorOutput "$moduleName documentation: $moduleMissing files missing (of $moduleTotal required)" -ForegroundColor $moduleColor
    }

    # Check if all documentation is complete
    $totalMissing = $projectResult.MissingFiles + ($moduleResults | Measure-Object -Property MissingFiles -Sum).Sum

    if ($totalMissing -eq 0) {
        Write-ColorOutput "`nAll documentation is complete! ✓" -ForegroundColor $successColor
    } else {
        Write-ColorOutput "`nWarning: $totalMissing documentation files are missing." -ForegroundColor $warningColor
    }

    # Remind about the directory structure rule
    Write-ColorOutput "`nReminder: Only the root directory should contain both files and subdirectories." -ForegroundColor $infoColor
    Write-ColorOutput "All other directories should contain either files or subdirectories, but not both." -ForegroundColor $infoColor

    Write-ColorOutput "`nDocumentation verification completed." -ForegroundColor $infoColor
} catch {
    Write-ColorOutput "Error during documentation verification: $_" -ForegroundColor $errorColor
    Write-ColorOutput "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor $errorColor
    exit 1
}
