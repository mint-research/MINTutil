# Create directories script for MINTYhive components

# Function to create a directory if it doesn't exist
function Create-IfNotExists {
    param (
        [string]$DirName
    )

    $dirPath = Join-Path "modules\M99_hive" $DirName

    Write-Host "Checking $dirPath..."
    if (-not (Test-Path $dirPath)) {
        Write-Host "Creating $DirName..."
        New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
        Write-Host "Done."
    } else {
        Write-Host "$DirName directory already exists."
    }
}

# Create MINTYtester
Create-IfNotExists -DirName "MINTYtester"

# Create MINTYgit
Create-IfNotExists -DirName "MINTYgit"

# Create MINTYcoder
Create-IfNotExists -DirName "MINTYcoder"

# Create MINTYarchivar
Create-IfNotExists -DirName "MINTYarchivar"

Write-Host "All directories created."
