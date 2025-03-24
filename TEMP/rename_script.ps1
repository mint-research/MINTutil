# Rename script for MINTYhive components

# Function to rename a directory if it exists
function Rename-IfExists {
    param (
        [string]$OldName,
        [string]$NewName
    )

    $oldPath = Join-Path "modules\M99_hive" $OldName
    $newPath = Join-Path "modules\M99_hive" $NewName

    Write-Host "Checking $oldPath..."
    if (Test-Path $oldPath) {
        Write-Host "Renaming $OldName to $NewName..."
        Rename-Item -Path $oldPath -NewName $NewName
        Write-Host "Done."
    } else {
        Write-Host "$OldName directory not found."
    }
}

# Rename MINTYtest to MINTYtester
Rename-IfExists -OldName "MINTYtest" -NewName "MINTYtester"

# Rename MINTYversioning to MINTYgit
Rename-IfExists -OldName "MINTYversioning" -NewName "MINTYgit"

# Rename MINTYcode to MINTYcoder
Rename-IfExists -OldName "MINTYcode" -NewName "MINTYcoder"

# Rename MINTYarchive to MINTYarchivar
Rename-IfExists -OldName "MINTYarchive" -NewName "MINTYarchivar"

Write-Host "All renames completed."
