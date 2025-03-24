# Rename script for MINTYhive components using copy and delete

# Function to rename a directory by copying and deleting
function Rename-ByCopy {
    param (
        [string]$OldName,
        [string]$NewName
    )

    $oldPath = Join-Path "modules\M99_hive" $OldName
    $newPath = Join-Path "modules\M99_hive" $NewName

    Write-Host "Checking $oldPath..."
    if (Test-Path $oldPath) {
        Write-Host "Copying $OldName to $NewName..."
        Copy-Item -Path $oldPath -Destination $newPath -Recurse
        Write-Host "Removing $OldName..."
        Remove-Item -Path $oldPath -Recurse -Force
        Write-Host "Done."
    } else {
        Write-Host "$OldName directory not found."
    }
}

# Rename MINTYtest to MINTYtester
Rename-ByCopy -OldName "MINTYtest" -NewName "MINTYtester"

# Rename MINTYversioning to MINTYgit
Rename-ByCopy -OldName "MINTYversioning" -NewName "MINTYgit"

# Rename MINTYcode to MINTYcoder
Rename-ByCopy -OldName "MINTYcode" -NewName "MINTYcoder"

# Rename MINTYarchive to MINTYarchivar
Rename-ByCopy -OldName "MINTYarchive" -NewName "MINTYarchivar"

Write-Host "All renames completed."
