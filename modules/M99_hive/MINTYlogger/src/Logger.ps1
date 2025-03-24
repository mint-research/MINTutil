# MINTY Logging Agent - Logger Component

<#
.SYNOPSIS
    Initialisiert den MINTY Logger.
.DESCRIPTION
    Erstellt die Verzeichnisstruktur und die initiale Log-Datei für den MINTY Logger.
.PARAMETER LogDirectory
    Das Verzeichnis, in dem die Log-Dateien gespeichert werden sollen.
.PARAMETER LogFileName
    Der Name der Log-Datei.
.EXAMPLE
    $loggerState = Initialize-MINTYLogger
.OUTPUTS
    Ein Hashtable mit dem Pfad zur Log-Datei und den initialen Log-Daten.
#>
function Initialize-MINTYLogger {
    param (
        [string]$LogDirectory = "MINTY\log",
        [string]$LogFileName = "development_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    )

    # Ensure log directory exists
    if (-not (Test-Path -Path $LogDirectory)) {
        New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
        Write-Host "Created log directory: $LogDirectory"
    }

    $logFilePath = Join-Path -Path $LogDirectory -ChildPath $LogFileName

    # Create initial log structure
    $logData = @{
        created = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        entries = @()
        summary = @{
            total_tokens         = 0
            total_cost           = 0
            average_quality      = 0
            context_window_usage = @()
        }
    }

    # Save initial log file
    $logData | ConvertTo-Json -Depth 10 | Set-Content -Path $logFilePath
    Write-Host "Initialized log file: $logFilePath"

    return @{
        LogFilePath = $logFilePath
        LogData     = $logData
    }
}

<#
.SYNOPSIS
    Fügt einen Eintrag zum Log hinzu.
.DESCRIPTION
    Fügt einen Eintrag zum Log hinzu und aktualisiert die Zusammenfassung.
.PARAMETER LoggerState
    Der Zustand des Loggers, wie von Initialize-MINTYLogger zurückgegeben.
.PARAMETER Component
    Die Komponente, die den Log-Eintrag erzeugt hat.
.PARAMETER Action
    Die Aktion, die protokolliert wird.
.PARAMETER Metrics
    Die Metriken, die protokolliert werden sollen.
.EXAMPLE
    Add-LogEntry -LoggerState $loggerState -Component "Cache" -Action "Update" -Metrics @{ tokens = 100; quality = 0.9 }
.OUTPUTS
    Der hinzugefügte Log-Eintrag.
#>
function Add-LogEntry {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$LoggerState,

        [Parameter(Mandatory = $true)]
        [string]$Component,

        [Parameter(Mandatory = $true)]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [hashtable]$Metrics
    )

    $logEntry = @{
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        component = $Component
        action    = $Action
        metrics   = $Metrics
    }

    # Update log data
    $LoggerState.LogData.entries += $logEntry

    # Update summary
    if ($Metrics.ContainsKey("tokens")) {
        $LoggerState.LogData.summary.total_tokens += $Metrics.tokens
    }

    if ($Metrics.ContainsKey("cost")) {
        $LoggerState.LogData.summary.total_cost += $Metrics.cost
    }

    if ($Metrics.ContainsKey("quality")) {
        $qualityValues = $LoggerState.LogData.entries |
        Where-Object { $_.metrics.ContainsKey("quality") } |
        ForEach-Object { $_.metrics.quality }

        if ($qualityValues.Count -gt 0) {
            $LoggerState.LogData.summary.average_quality = ($qualityValues | Measure-Object -Average).Average
        }
    }

    if ($Metrics.ContainsKey("context_window_usage")) {
        $LoggerState.LogData.summary.context_window_usage += @{
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
            usage     = $Metrics.context_window_usage
        }
    }

    # Save updated log file
    $LoggerState.LogData | ConvertTo-Json -Depth 10 | Set-Content -Path $LoggerState.LogFilePath

    Write-Host "Added log entry: [$Component] $Action"

    return $logEntry
}

<#
.SYNOPSIS
    Ruft die Zusammenfassung des Logs ab.
.DESCRIPTION
    Ruft die Zusammenfassung des Logs ab, einschließlich Gesamttoken, Kosten und durchschnittlicher Qualität.
.PARAMETER LoggerState
    Der Zustand des Loggers, wie von Initialize-MINTYLogger zurückgegeben.
.EXAMPLE
    $summary = Get-LogSummary -LoggerState $loggerState
.OUTPUTS
    Die Zusammenfassung des Logs.
#>
function Get-LogSummary {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$LoggerState
    )

    return $LoggerState.LogData.summary
}

<#
.SYNOPSIS
    Exportiert das Log in eine Datei.
.DESCRIPTION
    Exportiert das Log in eine Datei im angegebenen Format.
.PARAMETER LoggerState
    Der Zustand des Loggers, wie von Initialize-MINTYLogger zurückgegeben.
.PARAMETER OutputPath
    Der Pfad, in den das Log exportiert werden soll.
.PARAMETER Format
    Das Format, in dem das Log exportiert werden soll (JSON oder CSV).
.EXAMPLE
    Export-Log -LoggerState $loggerState -OutputPath "log_export.json" -Format "JSON"
.OUTPUTS
    Der Pfad zur exportierten Datei.
#>
function Export-Log {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$LoggerState,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "CSV")]
        [string]$Format = "JSON"
    )

    if ($Format -eq "JSON") {
        $LoggerState.LogData | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    } else {
        # For CSV, we need to flatten the entries
        $flatEntries = $LoggerState.LogData.entries | ForEach-Object {
            $entry = $_
            $metrics = $entry.metrics

            $flatEntry = @{
                timestamp = $entry.timestamp
                component = $entry.component
                action    = $entry.action
            }

            # Add metrics as separate columns
            foreach ($key in $metrics.Keys) {
                $flatEntry[$key] = $metrics[$key]
            }

            [PSCustomObject]$flatEntry
        }

        $flatEntries | Export-Csv -Path $OutputPath -NoTypeInformation
    }

    Write-Host "Exported log to: $OutputPath"

    return $OutputPath
}
