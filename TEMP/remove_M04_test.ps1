# Script to remove M04_test module from the system
# This module was likely created by the system but doesn't officially exist in the registry

# Base directory
$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Directories to remove
$directories = @(
    "config\M04_test",
    "data\M04_test",
    "docs\M04_test",
    "meta\M04_test",
    "modules\M04_test"
)

Write-Host "Starting removal of M04_test module..." -ForegroundColor Cyan

foreach ($dir in $directories) {
    $path = Join-Path -Path $baseDir -ChildPath $dir

    if (Test-Path -Path $path) {
        try {
            Remove-Item -Path $path -Recurse -Force
            Write-Host "Successfully removed: $dir" -ForegroundColor Green
        } catch {
            $errorMsg = $_.Exception.Message
            Write-Host "Failed to remove $dir - Error: $errorMsg" -ForegroundColor Red
        }
    } else {
        Write-Host "Directory not found: $dir" -ForegroundColor Yellow
    }
}

Write-Host "M04_test module removal completed." -ForegroundColor Cyan
