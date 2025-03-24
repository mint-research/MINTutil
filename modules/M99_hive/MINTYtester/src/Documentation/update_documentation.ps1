# Update Documentation Script
# This script runs the comprehensive cleanup and verification scripts in sequence

# Set error action preference to stop on errors
$ErrorActionPreference = "Stop"

# Define colors for console output
$successColor = "Green"
$warningColor = "Yellow"
$errorColor = "Red"
$infoColor = "Cyan"

# Define the base path for the project
$basePath = $PSScriptRoot | Split-Path -Parent
$scriptsPath = Join-Path -Path $basePath -ChildPath "tests"

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

# Main script execution
try {
    Write-ColorOutput "Starting documentation update process..." -ForegroundColor $infoColor

    # Step 1: Run the comprehensive cleanup script
    Write-ColorOutput "`n=== Step 1: Comprehensive cleanup of all old documentation files ===" -ForegroundColor $infoColor
    $cleanupAllScript = Join-Path -Path $scriptsPath -ChildPath "cleanup_all_old_docs.ps1"

    if (Test-Path -Path $cleanupAllScript) {
        & $cleanupAllScript

        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "Comprehensive cleanup script failed with exit code $LASTEXITCODE" -ForegroundColor $errorColor
            exit $LASTEXITCODE
        }
    } else {
        Write-ColorOutput "Comprehensive cleanup script not found: $cleanupAllScript" -ForegroundColor $errorColor
        exit 1
    }

    # Step 2: Run the verification script
    Write-ColorOutput "`n=== Step 2: Verifying and updating documentation ===" -ForegroundColor $infoColor
    $verifyScript = Join-Path -Path $scriptsPath -ChildPath "verify_documentation.ps1"

    if (Test-Path -Path $verifyScript) {
        & $verifyScript

        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "Verification script failed with exit code $LASTEXITCODE" -ForegroundColor $errorColor
            exit $LASTEXITCODE
        }
    } else {
        Write-ColorOutput "Verification script not found: $verifyScript" -ForegroundColor $errorColor
        exit 1
    }

    Write-ColorOutput "`nDocumentation update process completed successfully." -ForegroundColor $successColor
    Write-ColorOutput "Your documentation is now up to date with the latest template structure." -ForegroundColor $successColor
    Write-ColorOutput "All unnecessary documentation files and folders have been removed." -ForegroundColor $successColor
} catch {
    Write-ColorOutput "Error during documentation update: $_" -ForegroundColor $errorColor
    Write-ColorOutput "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor $errorColor
    exit 1
}
