# MINTYcache - Project Structure Scanner
# Scans and caches project structure information

<#
.SYNOPSIS
    Scans and caches project structure information.
.DESCRIPTION
    Provides functionality to scan project directories, extract structure information,
    and cache it for efficient access.
.NOTES
    Version: 1.0.0
    Author: MINTYhive
#>

class ProjectScanner {
    [hashtable] $Config

    ProjectScanner([hashtable]$config) {
        $this.Config = $config
    }

    [hashtable] ScanProject([string]$rootPath) {
        if (-not (Test-Path $rootPath)) {
            throw "Project path does not exist: $rootPath"
        }

        $structure = @{
            root        = $rootPath
            timestamp   = Get-Date
            directories = @{}
            files       = @{}
            metadata    = @{
                totalFiles       = 0
                totalDirectories = 0
                totalSize        = 0
                languageStats    = @{}
            }
        }

        $this.ScanDirectory($rootPath, $structure, 0)

        return $structure
    }

    [void] ScanDirectory([string]$path, [hashtable]$structure, [int]$depth) {
        if ($depth -gt $this.Config.scanDepth) {
            return
        }

        $items = Get-ChildItem -Path $path -Force

        foreach ($item in $items) {
            $relativePath = $item.FullName.Substring($structure.root.Length).TrimStart('\', '/')

            # Skip excluded patterns
            $excluded = $false
            foreach ($pattern in $this.Config.excludePatterns) {
                if ($relativePath -match $pattern) {
                    $excluded = $true
                    break
                }
            }

            if ($excluded) {
                continue
            }

            if ($item.PSIsContainer) {
                # Directory
                $structure.directories[$relativePath] = @{
                    name         = $item.Name
                    path         = $relativePath
                    lastModified = $item.LastWriteTime
                }

                $structure.metadata.totalDirectories++

                $this.ScanDirectory($item.FullName, $structure, $depth + 1)
            } else {
                # File
                $extension = $item.Extension.TrimStart('.')

                $structure.files[$relativePath] = @{
                    name         = $item.Name
                    path         = $relativePath
                    extension    = $extension
                    size         = $item.Length
                    lastModified = $item.LastWriteTime
                }

                $structure.metadata.totalFiles++
                $structure.metadata.totalSize += $item.Length

                # Update language stats
                if (-not [string]::IsNullOrEmpty($extension)) {
                    if (-not $structure.metadata.languageStats.ContainsKey($extension)) {
                        $structure.metadata.languageStats[$extension] = 0
                    }
                    $structure.metadata.languageStats[$extension]++
                }
            }
        }
    }
}

class ProjectStructureCache {
    [hashtable] $Config
    [hashtable] $Cache = @{}
    [object] $Scanner

    ProjectStructureCache([hashtable]$config) {
        $this.Config = $config
        $this.Scanner = [ProjectScanner]::new($config)
    }

    [hashtable] GetStructure([string]$path, [bool]$refresh = $false) {
        $normalizedPath = $this.NormalizePath($path)

        if ($refresh -or -not $this.Cache.ContainsKey($normalizedPath) -or $this.IsCacheExpired($normalizedPath)) {
            $this.Refresh($normalizedPath)
        }

        return $this.Cache[$normalizedPath]
    }

    [void] Refresh([string]$path) {
        $normalizedPath = $this.NormalizePath($path)
        $structure = $this.Scanner.ScanProject($normalizedPath)
        $structure.cacheTimestamp = Get-Date
        $this.Cache[$normalizedPath] = $structure

        # Save to disk for persistence
        $this.SaveToFile($normalizedPath, $structure)
    }

    [bool] IsCacheExpired([string]$path) {
        if (-not $this.Cache.ContainsKey($path)) {
            return $true
        }

        $cacheAge = (Get-Date) - $this.Cache[$path].cacheTimestamp
        return $cacheAge.TotalSeconds -gt $this.Config.cacheExpiration
    }

    [string] NormalizePath([string]$path) {
        return $path.TrimEnd('\', '/').Replace('/', '\')
    }

    [void] SaveToFile([string]$path, [hashtable]$structure) {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $cacheDir = Join-Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) "data\project_structure"

        if (-not (Test-Path $cacheDir)) {
            New-Item -Path $cacheDir -ItemType Directory -Force | Out-Null
        }

        $pathHash = [System.BitConverter]::ToString(
            [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                [System.Text.Encoding]::UTF8.GetBytes($path)
            )
        ).Replace("-", "")

        $cacheFile = Join-Path $cacheDir "$pathHash.json"

        $structure | ConvertTo-Json -Depth 10 | Set-Content -Path $cacheFile
    }

    [hashtable] LoadFromFile([string]$path) {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $cacheDir = Join-Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) "data\project_structure"

        $pathHash = [System.BitConverter]::ToString(
            [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                [System.Text.Encoding]::UTF8.GetBytes($path)
            )
        ).Replace("-", "")

        $cacheFile = Join-Path $cacheDir "$pathHash.json"

        if (Test-Path $cacheFile) {
            return Get-Content -Path $cacheFile -Raw | ConvertFrom-Json -AsHashtable
        }

        return $null
    }

    [array] FindFiles([string]$projectPath, [string]$pattern, [string]$extension = $null) {
        $structure = $this.GetStructure($projectPath)
        $results = @()

        foreach ($filePath in $structure.files.Keys) {
            $file = $structure.files[$filePath]

            $match = $true

            if (-not [string]::IsNullOrEmpty($pattern)) {
                $match = $match -and ($file.name -match $pattern -or $filePath -match $pattern)
            }

            if (-not [string]::IsNullOrEmpty($extension)) {
                $match = $match -and ($file.extension -eq $extension)
            }

            if ($match) {
                $results += $file
            }
        }

        return $results
    }

    [hashtable] GetSummary([string]$projectPath) {
        $structure = $this.GetStructure($projectPath)

        return @{
            root             = $structure.root
            timestamp        = $structure.timestamp
            totalFiles       = $structure.metadata.totalFiles
            totalDirectories = $structure.metadata.totalDirectories
            totalSize        = $structure.metadata.totalSize
            languages        = $structure.metadata.languageStats
        }
    }

    [void] Clear() {
        $this.Cache.Clear()
    }

    [hashtable] GetStats() {
        return @{
            cacheCount       = $this.Cache.Count
            totalFiles       = ($this.Cache.Values | ForEach-Object { $_.metadata.totalFiles } | Measure-Object -Sum).Sum
            totalDirectories = ($this.Cache.Values | ForEach-Object { $_.metadata.totalDirectories } | Measure-Object -Sum).Sum
            totalSize        = ($this.Cache.Values | ForEach-Object { $_.metadata.totalSize } | Measure-Object -Sum).Sum
        }
    }
}

# Export the classes
Export-ModuleMember -Variable ProjectScanner, ProjectStructureCache
