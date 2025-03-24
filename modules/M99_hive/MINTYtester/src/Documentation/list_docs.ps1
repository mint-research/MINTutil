# List Documentation Files Script
# This script lists all documentation files in the docs directory

# Define the base path for the project
$basePath = $PSScriptRoot | Split-Path -Parent
$docsPath = Join-Path -Path $basePath -ChildPath "docs"

# Function to list files in a directory
function List-Files {
    param(
        [string]$DirectoryPath,
        [string]$Indent = ""
    )

    # Get all items in the directory
    $items = Get-ChildItem -Path $DirectoryPath

    # List directories first
    foreach ($item in ($items | Where-Object { $_.PSIsContainer })) {
        Write-Host "$Indent[Directory] $($item.Name)"
        List-Files -DirectoryPath $item.FullName -Indent "$Indent  "
    }

    # Then list files
    foreach ($item in ($items | Where-Object { -not $_.PSIsContainer })) {
        Write-Host "$Indent[File] $($item.Name)"
    }
}

# Main script execution
Write-Host "Listing documentation files in $docsPath"
Write-Host "----------------------------------------"
List-Files -DirectoryPath $docsPath
