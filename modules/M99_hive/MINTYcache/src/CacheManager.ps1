# MINTYcache - Cache Manager
# Main module for the MINTYcache agent

<#
.SYNOPSIS
    Main cache manager for the MINTYcache agent.
.DESCRIPTION
    Provides centralized cache management functionality for the MINTYcache agent,
    including project structure caching, code semantics caching, and context window management.
.NOTES
    Version: 1.0.0
    Author: MINTYhive
#>

# Import required modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\ProjectStructure\ProjectScanner.ps1"
. "$scriptPath\CodeSemantics\CodeParser.ps1"
. "$scriptPath\ContextWindow\ContextManager.ps1"

class MINTYCacheManager {
    [hashtable] $Config
    [object] $ProjectStructureCache
    [object] $CodeSemanticsCache
    [object] $ContextWindowManager
    [string] $LoggingAgentPath
    [bool] $Initialized = $false

    MINTYCacheManager([string]$configPath, [string]$loggingAgentPath) {
        $this.LoadConfig($configPath)
        $this.LoggingAgentPath = $loggingAgentPath
        $this.Initialize()
    }

    [void] LoadConfig([string]$configPath) {
        if (-not (Test-Path $configPath)) {
            throw "Configuration file not found: $configPath"
        }

        try {
            $this.Config = Get-Content -Path $configPath -Raw | ConvertFrom-Json -AsHashtable
            Write-Verbose "Configuration loaded successfully from $configPath"
        } catch {
            throw "Error loading configuration: $_"
        }
    }

    [void] Initialize() {
        try {
            # Initialize Project Structure Cache
            $this.ProjectStructureCache = [ProjectStructureCache]::new($this.Config.projectStructure)
            Write-Verbose "Project Structure Cache initialized"

            # Initialize Code Semantics Cache
            $this.CodeSemanticsCache = [CodeSemanticsCache]::new($this.Config.codeSemantics)
            Write-Verbose "Code Semantics Cache initialized"

            # Initialize Context Window Manager
            $this.ContextWindowManager = [ContextWindowManager]::new($this.Config.contextWindow)
            Write-Verbose "Context Window Manager initialized"

            # Initialize Logging Integration
            if ($this.LoggingAgentPath -and (Test-Path $this.LoggingAgentPath)) {
                Import-Module $this.LoggingAgentPath -Force
                Write-Verbose "Logging Agent imported from $($this.LoggingAgentPath)"
            } else {
                Write-Warning "Logging Agent not found at $($this.LoggingAgentPath). Logging integration disabled."
            }

            $this.Initialized = $true
            Write-Verbose "MINTYCacheManager initialized successfully"
        } catch {
            Write-Error "Error initializing MINTYCacheManager: $_"
            throw $_
        }
    }

    # Project Structure Cache Methods

    [hashtable] GetProjectStructure([string]$path, [bool]$refresh = $false) {
        $this.EnsureInitialized()
        return $this.ProjectStructureCache.GetStructure($path, $refresh)
    }

    [array] FindFiles([string]$projectPath, [string]$pattern, [string]$extension = $null) {
        $this.EnsureInitialized()
        return $this.ProjectStructureCache.FindFiles($projectPath, $pattern, $extension)
    }

    [hashtable] GetProjectSummary([string]$projectPath) {
        $this.EnsureInitialized()
        return $this.ProjectStructureCache.GetSummary($projectPath)
    }

    # Code Semantics Cache Methods

    [hashtable] GetCodeSemantics([string]$path, [bool]$refresh = $false) {
        $this.EnsureInitialized()
        return $this.CodeSemanticsCache.GetSemantics($path, $refresh)
    }

    [array] FindSymbols([string]$projectPath, [string]$symbolName, [string]$symbolType = $null) {
        $this.EnsureInitialized()
        return $this.CodeSemanticsCache.FindSymbols($projectPath, $symbolName, $symbolType)
    }

    [hashtable] GetCodeSummary([string]$projectPath) {
        $this.EnsureInitialized()
        return $this.CodeSemanticsCache.GetSummary($projectPath)
    }

    # Context Window Management Methods

    [hashtable] GetContextWindowStatus() {
        $this.EnsureInitialized()
        return $this.ContextWindowManager.GetStatus()
    }

    [hashtable] OptimizeContext([hashtable]$currentContext, [int]$targetSize) {
        $this.EnsureInitialized()
        return $this.ContextWindowManager.OptimizeContext($currentContext, $targetSize)
    }

    [hashtable] RotateContext([hashtable]$currentContext, [string]$strategy = "balanced") {
        $this.EnsureInitialized()
        return $this.ContextWindowManager.RotateContext($currentContext, $strategy)
    }

    # General Cache Management Methods

    [void] RefreshCache([string]$path) {
        $this.EnsureInitialized()
        $this.ProjectStructureCache.Refresh($path)
        $this.CodeSemanticsCache.Refresh($path)
        Write-Verbose "Cache refreshed for path: $path"
    }

    [void] ClearCache() {
        $this.EnsureInitialized()
        $this.ProjectStructureCache.Clear()
        $this.CodeSemanticsCache.Clear()
        Write-Verbose "Cache cleared"
    }

    [hashtable] GetCacheStats() {
        $this.EnsureInitialized()
        return @{
            projectStructure = $this.ProjectStructureCache.GetStats()
            codeSemantics    = $this.CodeSemanticsCache.GetStats()
            contextWindow    = $this.ContextWindowManager.GetStats()
            timestamp        = Get-Date
        }
    }

    # Helper Methods

    [void] EnsureInitialized() {
        if (-not $this.Initialized) {
            throw "MINTYCacheManager is not initialized. Call Initialize() first."
        }
    }
}

# Export the class
Export-ModuleMember -Variable MINTYCacheManager
