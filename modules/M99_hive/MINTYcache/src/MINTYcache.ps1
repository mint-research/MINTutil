# MINTYcache
# Beschreibung: Hauptkomponente des Cache-Agents für Projektscannen, Codesemantik und Kontextfenster-Management

# Pfade
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$configPath = Join-Path $modulePath "config"
$dataPath = Join-Path $modulePath "data"

# Globale Variablen
$script:ConfigFile = Join-Path $configPath "cache_config.json"
$script:Config = $null
$script:ProjectScanner = $null
$script:CodeParser = $null
$script:ContextManager = $null
$script:MCPServer = $null

# Module importieren
. "$scriptPath\ProjectStructure\ProjectScanner.ps1"
. "$scriptPath\CodeSemantics\CodeParser.ps1"
. "$scriptPath\ContextWindow\ContextManager.ps1"

<#
.SYNOPSIS
    Initialisiert den Cache-Agent.
.DESCRIPTION
    Lädt die Konfiguration und initialisiert alle Komponenten des Cache-Agents.
#>
function Initialize-Cache {
    try {
        # Erstelle Verzeichnisse, falls sie nicht existieren
        if (-not (Test-Path $configPath)) {
            New-Item -Path $configPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path $dataPath)) {
            New-Item -Path $dataPath -ItemType Directory -Force | Out-Null
        }

        # Lade Konfiguration
        if (Test-Path $script:ConfigFile) {
            $script:Config = Get-Content -Path $script:ConfigFile -Raw | ConvertFrom-Json
        } else {
            # Erstelle Standardkonfiguration
            $script:Config = @{
                "ScanSettings"        = @{
                    "MaxDepth"          = 10
                    "ExcludeDirs"       = @("node_modules", ".git", "bin", "obj", "dist", "build")
                    "IncludeExtensions" = @(".ps1", ".psm1", ".psd1", ".js", ".ts", ".jsx", ".tsx", ".cs", ".py", ".java", ".json", ".xml", ".yaml", ".yml")
                    "ScanInterval"      = 3600
                    "EnableAutoScan"    = $true
                }
                "ParserSettings"      = @{
                    "MaxFileSize"              = 1048576
                    "EnableSemanticAnalysis"   = $true
                    "EnableDependencyTracking" = $true
                    "EnableFunctionExtraction" = $true
                    "EnableClassExtraction"    = $true
                    "EnableVariableTracking"   = $true
                }
                "ContextSettings"     = @{
                    "MaxContextSize"              = 8192
                    "PrioritizeRecentFiles"       = $true
                    "PrioritizeActiveFiles"       = $true
                    "PrioritizeDependencies"      = $true
                    "ContextOptimizationStrategy" = "TokenEfficiency"
                    "EnableContextCompression"    = $true
                }
                "MCPSettings"         = @{
                    "Port"                  = 8080
                    "Host"                  = "localhost"
                    "EnableMCP"             = $true
                    "MaxConcurrentRequests" = 10
                    "RequestTimeout"        = 30000
                }
                "StorageSettings"     = @{
                    "CachePath"           = "data"
                    "MaxCacheSize"        = 1073741824
                    "EnablePersistence"   = $true
                    "PersistenceInterval" = 300
                    "EnableCompression"   = $true
                }
                "IntegrationSettings" = @{
                    "EnableHiveIntegration"    = $true
                    "EnableLoggerIntegration"  = $true
                    "EnableManagerIntegration" = $true
                    "HiveUpdateInterval"       = 60
                }
            }

            # Speichere Standardkonfiguration
            $script:Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile
        }

        # Initialisiere Komponenten
        $script:ProjectScanner = Initialize-ProjectScanner -Config $script:Config.ScanSettings
        $script:CodeParser = Initialize-CodeParser -Config $script:Config.ParserSettings
        $script:ContextManager = Initialize-ContextManager -Config $script:Config.ContextSettings

        # Initialisiere MCP-Server, falls aktiviert
        if ($script:Config.MCPSettings.EnableMCP) {
            Start-Process -FilePath "node" -ArgumentList "$scriptPath\MCP\MCPServer.js" -NoNewWindow
        }

        Write-Host "Cache-Agent initialisiert"
        return $true
    } catch {
        Write-Error "Fehler bei der Initialisierung des Cache-Agents: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Scannt ein Projekt und speichert die Struktur im Cache.
.DESCRIPTION
    Scannt ein Projekt und speichert die Struktur im Cache.
.PARAMETER Path
    Der Pfad zum Projekt.
#>
function Scan-Project {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    return Scan-ProjectStructure -Path $Path
}

<#
.SYNOPSIS
    Analysiert eine Datei und extrahiert semantische Informationen.
.DESCRIPTION
    Analysiert eine Datei und extrahiert semantische Informationen.
.PARAMETER Path
    Der Pfad zur Datei.
#>
function Parse-File {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    return Parse-CodeFile -Path $Path
}

<#
.SYNOPSIS
    Optimiert ein Kontextfenster.
.DESCRIPTION
    Optimiert ein Kontextfenster basierend auf der Konfiguration.
.PARAMETER Context
    Der Kontext, der optimiert werden soll.
.PARAMETER MaxTokens
    Die maximale Anzahl von Tokens im optimierten Kontext.
#>
function Optimize-Context {
    param(
        [Parameter(Mandatory = $true)][string]$Context,
        [Parameter(Mandatory = $true)][int]$MaxTokens
    )

    return Optimize-ContextWindow -Context $Context -MaxTokens $MaxTokens
}

<#
.SYNOPSIS
    Speichert Daten im Cache.
.DESCRIPTION
    Speichert Daten im Cache.
.PARAMETER Key
    Der Schlüssel, unter dem die Daten gespeichert werden sollen.
.PARAMETER Value
    Die Daten, die gespeichert werden sollen.
#>
function Set-CacheItem {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)]$Value
    )

    $cachePath = Join-Path $dataPath "metadata"
    if (-not (Test-Path $cachePath)) {
        New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
    }

    $cacheFile = Join-Path $cachePath "$Key.json"
    $Value | ConvertTo-Json -Depth 10 | Set-Content -Path $cacheFile
}

<#
.SYNOPSIS
    Ruft Daten aus dem Cache ab.
.DESCRIPTION
    Ruft Daten aus dem Cache ab.
.PARAMETER Key
    Der Schlüssel, unter dem die Daten gespeichert sind.
#>
function Get-CacheItem {
    param(
        [Parameter(Mandatory = $true)][string]$Key
    )

    $cachePath = Join-Path $dataPath "metadata"
    $cacheFile = Join-Path $cachePath "$Key.json"

    if (Test-Path $cacheFile) {
        return Get-Content -Path $cacheFile -Raw | ConvertFrom-Json
    }

    return $null
}

# Exportiere Funktionen
Export-ModuleMember -Function Initialize-Cache, Scan-Project, Parse-File, Optimize-Context, Set-CacheItem, Get-CacheItem
