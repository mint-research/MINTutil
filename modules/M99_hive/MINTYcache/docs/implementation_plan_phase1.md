# MINTY Cache System - Phase 1 Implementation Plan

This document outlines the detailed implementation plan for Phase 1 of the MINTY Cache System, focusing on establishing the core infrastructure and implementing the Project Structure Cache and Code Semantics Cache components.

## 1. Directory Structure

```
MINTY/
├── cache/
│   ├── config/                     # Configuration files
│   │   ├── cache_config.json       # Main configuration
│   │   └── logging_config.json     # Logging configuration
│   ├── src/                        # Source code
│   │   ├── Core/                   # Core components
│   │   │   ├── CacheManager.ps1    # Main cache manager
│   │   │   ├── ConfigManager.ps1   # Configuration manager
│   │   │   └── Utils.ps1           # Utility functions
│   │   ├── ProjectStructure/       # Project structure cache
│   │   │   ├── ProjectScanner.ps1  # File system scanner
│   │   │   ├── StructureCache.ps1  # Structure cache implementation
│   │   │   └── StructureQuery.ps1  # Query interface
│   │   ├── CodeSemantics/          # Code semantics cache
│   │   │   ├── CodeParser.ps1      # Language-agnostic parser
│   │   │   ├── SemanticsCache.ps1  # Semantics cache implementation
│   │   │   └── SemanticsQuery.ps1  # Query interface
│   │   └── Integration/            # Integration components
│   │       ├── LoggingIntegration.ps1  # Integration with Logging Agent
│   │       └── AgentInterface.ps1  # Interface for AI agents
│   ├── tests/                      # Test scripts
│   │   ├── ProjectStructure/       # Tests for project structure cache
│   │   ├── CodeSemantics/          # Tests for code semantics cache
│   │   └── Integration/            # Integration tests
│   └── data/                       # Cache data storage
│       ├── project_structure/      # Project structure cache data
│       ├── code_semantics/         # Code semantics cache data
│       └── metadata/               # Cache metadata
└── log/                            # Existing Logging Agent
```

## 2. Core Components Design

### 2.1 Cache Manager

The `CacheManager.ps1` will serve as the central entry point for the cache system:

```powershell
# CacheManager.ps1

class MINTYCacheManager {
    [hashtable] $Config
    [object] $ProjectStructureCache
    [object] $CodeSemanticsCache
    [object] $LoggingAgent

    MINTYCacheManager([string]$configPath) {
        $this.Config = Get-Content -Path $configPath -Raw | ConvertFrom-Json -AsHashtable
        $this.InitializeComponents()
    }

    [void] InitializeComponents() {
        # Initialize Project Structure Cache
        $this.ProjectStructureCache = [ProjectStructureCache]::new($this.Config.projectStructure)

        # Initialize Code Semantics Cache
        $this.CodeSemanticsCache = [CodeSemanticsCache]::new($this.Config.codeSemantics)

        # Initialize Logging Integration
        $this.LoggingAgent = [LoggingIntegration]::new($this.Config.logging)
    }

    [hashtable] GetProjectStructure([string]$path, [bool]$refresh = $false) {
        return $this.ProjectStructureCache.GetStructure($path, $refresh)
    }

    [hashtable] GetCodeSemantics([string]$path, [bool]$refresh = $false) {
        return $this.CodeSemanticsCache.GetSemantics($path, $refresh)
    }

    [void] RefreshCache([string]$path) {
        $this.ProjectStructureCache.Refresh($path)
        $this.CodeSemanticsCache.Refresh($path)
    }

    [hashtable] GetCacheStats() {
        return @{
            projectStructure = $this.ProjectStructureCache.GetStats()
            codeSemantics = $this.CodeSemanticsCache.GetStats()
        }
    }
}

# Export the class
Export-ModuleMember -Variable MINTYCacheManager
```

### 2.2 Configuration Manager

The `ConfigManager.ps1` will handle configuration loading and validation:

```powershell
# ConfigManager.ps1

class ConfigManager {
    [hashtable] $DefaultConfig = @{
        projectStructure = @{
            scanDepth = 10
            excludePatterns = @("node_modules", "bin", "obj", ".git")
            cacheExpiration = 3600  # seconds
            metadataEnabled = $true
        }
        codeSemantics = @{
            languages = @("ps1", "cs", "js", "py", "java")
            parseDepth = 5
            cacheExpiration = 7200  # seconds
            symbolLimit = 10000
        }
        logging = @{
            enabled = $true
            logLevel = "Info"
            metricsCollection = $true
        }
    }

    [hashtable] LoadConfig([string]$path) {
        if (-not (Test-Path $path)) {
            Write-Warning "Configuration file not found. Using default configuration."
            return $this.DefaultConfig
        }

        try {
            $config = Get-Content -Path $path -Raw | ConvertFrom-Json -AsHashtable
            return $this.MergeWithDefaults($config)
        }
        catch {
            Write-Error "Error loading configuration: $_"
            return $this.DefaultConfig
        }
    }

    [hashtable] MergeWithDefaults([hashtable]$config) {
        $merged = $this.DefaultConfig.Clone()

        foreach ($key in $config.Keys) {
            if ($merged.ContainsKey($key)) {
                if ($config[$key] -is [hashtable] -and $merged[$key] -is [hashtable]) {
                    $merged[$key] = $this.MergeHashtables($merged[$key], $config[$key])
                }
                else {
                    $merged[$key] = $config[$key]
                }
            }
            else {
                $merged[$key] = $config[$key]
            }
        }

        return $merged
    }

    [hashtable] MergeHashtables([hashtable]$h1, [hashtable]$h2) {
        $result = $h1.Clone()

        foreach ($key in $h2.Keys) {
            if ($result.ContainsKey($key)) {
                if ($h2[$key] -is [hashtable] -and $result[$key] -is [hashtable]) {
                    $result[$key] = $this.MergeHashtables($result[$key], $h2[$key])
                }
                else {
                    $result[$key] = $h2[$key]
                }
            }
            else {
                $result[$key] = $h2[$key]
            }
        }

        return $result
    }
}

# Export the class
Export-ModuleMember -Variable ConfigManager
```

## 3. Project Structure Cache Implementation

### 3.1 Project Scanner

The `ProjectScanner.ps1` will handle scanning the file system:

```powershell
# ProjectScanner.ps1

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
            root = $rootPath
            timestamp = Get-Date
            directories = @{}
            files = @{}
            metadata = @{
                totalFiles = 0
                totalDirectories = 0
                totalSize = 0
                languageStats = @{}
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
                    name = $item.Name
                    path = $relativePath
                    lastModified = $item.LastWriteTime
                }

                $structure.metadata.totalDirectories++

                $this.ScanDirectory($item.FullName, $structure, $depth + 1)
            }
            else {
                # File
                $extension = $item.Extension.TrimStart('.')

                $structure.files[$relativePath] = @{
                    name = $item.Name
                    path = $relativePath
                    extension = $extension
                    size = $item.Length
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

# Export the class
Export-ModuleMember -Variable ProjectScanner
```

### 3.2 Structure Cache

The `StructureCache.ps1` will handle caching project structure information:

```powershell
# StructureCache.ps1

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
        $cacheDir = Join-Path $PSScriptRoot "..\..\data\project_structure"

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
        $cacheDir = Join-Path $PSScriptRoot "..\..\data\project_structure"

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

    [hashtable] GetStats() {
        return @{
            cacheCount = $this.Cache.Count
            totalFiles = ($this.Cache.Values | ForEach-Object { $_.metadata.totalFiles } | Measure-Object -Sum).Sum
            totalDirectories = ($this.Cache.Values | ForEach-Object { $_.metadata.totalDirectories } | Measure-Object -Sum).Sum
            totalSize = ($this.Cache.Values | ForEach-Object { $_.metadata.totalSize } | Measure-Object -Sum).Sum
        }
    }
}

# Export the class
Export-ModuleMember -Variable ProjectStructureCache
```

## 4. Implementation Steps

### Week 1: Core Infrastructure Setup

1. Create the directory structure as outlined above
2. Implement the `ConfigManager.ps1` class
3. Create basic configuration files
4. Set up integration with the Logging Agent
5. Implement basic utility functions

### Week 2: Project Structure Cache

1. Implement the `ProjectScanner.ps1` class
2. Implement the `StructureCache.ps1` class
3. Implement the `StructureQuery.ps1` class
4. Create basic tests for the Project Structure Cache
5. Test with real-world projects

### Week 3: Code Semantics Cache

1. Implement the `CodeParser.ps1` class with basic language support
2. Implement the `SemanticsCache.ps1` class
3. Implement the `SemanticsQuery.ps1` class
4. Create basic tests for the Code Semantics Cache
5. Test with real-world projects

## 5. Integration with Logging Agent

1. Create the `LoggingIntegration.ps1` class to interface with the MINTY Logging Agent
2. Implement metrics collection for cache operations
3. Set up event hooks for automatic metric collection
4. Create a simple dashboard for monitoring cache performance

## 6. Agent Interface

1. Create the `AgentInterface.ps1` class to provide a simple API for AI agents
2. Implement basic query patterns for common tasks
3. Create examples of how to use the cache effectively
4. Document the API for future reference

## 7. Testing and Validation

1. Create comprehensive test cases for all components
2. Test with various project sizes and structures
3. Measure performance and accuracy metrics
4. Document the results and identify areas for improvement

## 8. Next Steps After Phase 1

1. Begin implementation of Context Window Manager (Phase 2)
2. Develop differential caching system (Phase 2)
3. Create proactive context rotation mechanisms (Phase 2)
4. Plan for LLM/API Cache Manager implementation (Phase 3)
