# MINTYlogger
# Beschreibung: Hauptkomponente des Logging-Agents für zentrale Protokollierung, Metrikerfassung und Optimierung

# Pfade
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$configPath = Join-Path $modulePath "config"
$dataPath = Join-Path $modulePath "data"

# Globale Variablen
$script:ConfigFile = Join-Path $configPath "logger_config.json"
$script:LogPath = Join-Path $env:TEMP "logs"
$script:Config = $null
$script:Logger = $null
$script:MetricsCollector = $null
$script:ContextMonitor = $null
$script:Optimizer = $null

# Module importieren
. "$scriptPath\Logger.ps1"
. "$scriptPath\MetricsCollector.ps1"
. "$scriptPath\ContextMonitor.ps1"
. "$scriptPath\Optimizer.ps1"

<#
.SYNOPSIS
    Initialisiert den Logger.
.DESCRIPTION
    Lädt die Konfiguration und initialisiert den Logger und alle Komponenten.
#>
function Initialize-Logger {
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
                "LoggingSettings"        = @{
                    "LogLevel"            = "Info"
                    "LogPath"             = "TEMP/logs"
                    "EnableConsoleOutput" = $true
                    "EnableFileOutput"    = $true
                    "MaxLogFileSize"      = 10485760
                    "MaxLogFiles"         = 10
                    "LogRotationInterval" = "Daily"
                }
                "MetricsSettings"        = @{
                    "CollectPerformanceMetrics"      = $true
                    "CollectUsageMetrics"            = $true
                    "MetricsInterval"                = 300
                    "EnableTokenEfficiencyReporting" = $true
                }
                "OptimizationSettings"   = @{
                    "EnableAutomaticOptimization" = $true
                    "OptimizationInterval"        = 3600
                    "TargetResourceUsage"         = 80
                }
                "ContextMonitorSettings" = @{
                    "EnableContextMonitoring" = $true
                    "MonitoringInterval"      = 60
                    "AlertThreshold"          = 90
                }
                "IntegrationSettings"    = @{
                    "EnableMCPIntegration" = $true
                    "MCPServerPort"        = 8080
                    "MCPServerHost"        = "localhost"
                }
            }

            # Speichere Standardkonfiguration
            $script:Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile
        }

        # Setze LogPath basierend auf Konfiguration
        $script:LogPath = $script:Config.LoggingSettings.LogPath
        if (-not (Test-Path $script:LogPath)) {
            New-Item -Path $script:LogPath -ItemType Directory -Force | Out-Null
        }

        # Initialisiere Komponenten
        $script:Logger = New-Object -TypeName PSObject
        $script:MetricsCollector = New-Object -TypeName PSObject
        $script:ContextMonitor = New-Object -TypeName PSObject
        $script:Optimizer = New-Object -TypeName PSObject

        # Initialisiere Logger
        Initialize-LoggerComponent -Config $script:Config.LoggingSettings

        # Initialisiere MetricsCollector
        Initialize-MetricsCollector -Config $script:Config.MetricsSettings

        # Initialisiere ContextMonitor
        Initialize-ContextMonitor -Config $script:Config.ContextMonitorSettings

        # Initialisiere Optimizer
        Initialize-Optimizer -Config $script:Config.OptimizationSettings

        Write-Host "Logger initialisiert"
        return $true
    } catch {
        Write-Error "Fehler bei der Initialisierung des Loggers: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Schreibt eine Protokollmeldung.
.DESCRIPTION
    Schreibt eine Protokollmeldung mit dem angegebenen Level und der angegebenen Nachricht.
.PARAMETER Level
    Das Level der Protokollmeldung (Debug, Info, Warning, Error).
.PARAMETER Message
    Die Nachricht, die protokolliert werden soll.
.PARAMETER Source
    Die Quelle der Protokollmeldung.
#>
function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Level,
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $false)][string]$Source = "MINTYlogger"
    )

    Write-LogMessage -Level $Level -Message $Message -Source $Source
}

<#
.SYNOPSIS
    Erfasst Metriken.
.DESCRIPTION
    Erfasst Leistungs- und Nutzungsmetriken.
#>
function Collect-Metrics {
    Collect-SystemMetrics
}

<#
.SYNOPSIS
    Optimiert das System.
.DESCRIPTION
    Optimiert die Systemleistung basierend auf gesammelten Metriken.
#>
function Optimize-System {
    Optimize-SystemPerformance
}

<#
.SYNOPSIS
    Überwacht den Kontext.
.DESCRIPTION
    Überwacht den Kontext und optimiert die Ressourcennutzung.
#>
function Monitor-Context {
    Monitor-SystemContext
}

# Exportiere Funktionen
Export-ModuleMember -Function Initialize-Logger, Write-Log, Collect-Metrics, Optimize-System, Monitor-Context
