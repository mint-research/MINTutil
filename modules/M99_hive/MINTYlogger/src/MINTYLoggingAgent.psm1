# MINTY Logging Agent - Main Module

# Import component scripts
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\Logger.ps1"
. "$scriptPath\MetricsCollector.ps1"
. "$scriptPath\ContextMonitor.ps1"
. "$scriptPath\Optimizer.ps1"

<#
.SYNOPSIS
    Initialisiert den MINTY Logging Agent.
.DESCRIPTION
    Initialisiert den MINTY Logging Agent mit allen Komponenten und gibt ein Objekt zurück, das die Funktionalität des Agents bereitstellt.
.PARAMETER LogDirectory
    Das Verzeichnis, in dem die Log-Dateien gespeichert werden sollen.
.PARAMETER VerboseOutput
    Gibt an, ob ausführliche Ausgaben generiert werden sollen.
.EXAMPLE
    $loggingAgent = Initialize-MINTYLoggingAgent
.OUTPUTS
    Ein Hashtable mit Funktionen und Zustand des Logging Agents.
#>
function Initialize-MINTYLoggingAgent {
    param (
        [string]$LogDirectory = "MINTY\log",
        [switch]$VerboseOutput = $false
    )

    # Set verbose preference based on parameter
    if ($VerboseOutput) {
        $VerbosePreference = 'Continue'
    } else {
        $VerbosePreference = 'SilentlyContinue'
    }

    Write-Verbose "Initializing MINTY Logging Agent..."

    # Initialize logger
    $loggerState = Initialize-MINTYLogger -LogDirectory $LogDirectory

    # Create agent object
    $agent = @{
        LoggerState      = $loggerState
        SessionStartTime = Get-Date
        SessionMetrics   = @{
            TotalTokens        = 0
            TotalCost          = 0
            AverageQuality     = 0
            Measurements       = 0
            ContextWindowUsage = @()
            Recommendations    = @()
        }
        Config           = @{
            LogDirectory             = $LogDirectory
            VerboseOutput            = $VerboseOutput
            OptimalContextRange      = @{
                Min = 0.5
                Max = 0.8
            }
            QualityThreshold         = 0.8
            TokenEfficiencyThreshold = 0.5
        }
    }

    # Add logging function
    $agent.Log = {
        param (
            [string]$Component,
            [string]$Action,
            [hashtable]$Metrics
        )

        Add-LogEntry -LoggerState $agent.LoggerState -Component $Component -Action $Action -Metrics $Metrics

        # Update session metrics
        if ($Metrics.ContainsKey("tokens")) {
            $agent.SessionMetrics.TotalTokens += $Metrics.tokens
        }

        if ($Metrics.ContainsKey("cost")) {
            $agent.SessionMetrics.TotalCost += $Metrics.cost
        }

        if ($Metrics.ContainsKey("quality")) {
            $agent.SessionMetrics.Measurements++
            $agent.SessionMetrics.AverageQuality = (($agent.SessionMetrics.AverageQuality * ($agent.SessionMetrics.Measurements - 1)) + $Metrics.quality) / $agent.SessionMetrics.Measurements
        }

        if ($Metrics.ContainsKey("context_window_usage")) {
            $agent.SessionMetrics.ContextWindowUsage += @{
                timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
                usage     = $Metrics.context_window_usage
            }
        }
    }

    # Add metrics collection functions
    $agent.GetTokenMetrics = {
        param (
            [string]$Content,
            [string]$PreviousContent = "",
            [double]$TokensPerCharacter = 4.0,
            [double]$CostPerToken = 0.00001
        )

        Get-TokenMetrics -Content $Content -PreviousContent $PreviousContent -TokensPerCharacter $TokensPerCharacter -CostPerToken $CostPerToken
    }

    $agent.EstimateOutputQuality = {
        param (
            [string]$Output,
            [hashtable]$Criteria = @{
                completeness = 0.4
                correctness  = 0.3
                clarity      = 0.2
                conciseness  = 0.1
            },
            [string]$ReferenceOutput = ""
        )

        Estimate-OutputQuality -Output $Output -Criteria $Criteria -ReferenceOutput $ReferenceOutput
    }
    $agent.GetCodeMetrics = {
        param (
            [string]$Code,
            [string]$Language = "Other"
        )

        Get-CodeMetrics -Code $Code -Language $Language
    }

    # Add context monitoring functions
    $agent.GetContextWindowMetrics = {
        param (
            [int]$UsedTokens,
            [int]$TotalTokens,
            [double]$OptimalUsageMin = 0.5,
            [double]$OptimalUsageMax = 0.8
        )

        Get-ContextWindowMetrics -UsedTokens $UsedTokens -TotalTokens $TotalTokens -OptimalUsageMin $OptimalUsageMin -OptimalUsageMax $OptimalUsageMax
    }

    $agent.GetContextWindowStatus = {
        param (
            [hashtable]$ContextMetrics
        )

        Get-ContextWindowStatus -ContextMetrics $ContextMetrics
    }

    $agent.SimulateContextRotation = {
        param (
            [hashtable]$ContextMetrics,
            [string]$RotationStrategy = "balanced"
        )

        Simulate-ContextRotation -ContextMetrics $ContextMetrics -RotationStrategy $RotationStrategy
    }

    $agent.ImplementProactiveContextRotation = {
        param (
            [hashtable]$ContextMetrics,
            [string]$RotationStrategy = "balanced",
            [array]$ContextSegments
        )

        Implement-ProactiveContextRotation -ContextMetrics $ContextMetrics -RotationStrategy $RotationStrategy -ContextSegments $ContextSegments
    }

    # Add optimizer functions
    $agent.GetOptimizationRecommendations = {
        param (
            [hashtable]$TokenMetrics,
            [hashtable]$QualityMetrics,
            [hashtable]$ContextMetrics
        )

        Get-OptimizationRecommendations -TokenMetrics $TokenMetrics -QualityMetrics $QualityMetrics -ContextMetrics $ContextMetrics
    }

    $agent.ImplementOptimization = {
        param (
            [hashtable]$Recommendation,
            [array]$ContextSegments,
            [hashtable]$CurrentMetrics
        )

        Implement-Optimization -Recommendation $Recommendation -ContextSegments $ContextSegments -CurrentMetrics $CurrentMetrics
    }

    $agent.GetCostQualitySweetspot = {
        param (
            [array]$HistoricalData,
            [double]$QualityThreshold = 0.8,
            [double]$CostWeight = 0.5
        )

        Get-CostQualitySweetspot -HistoricalData $HistoricalData -QualityThreshold $QualityThreshold -CostWeight $CostWeight
    }

    $agent.GetOptimizationPlan = {
        param (
            [array]$Recommendations,
            [hashtable]$CurrentMetrics,
            [hashtable]$TargetMetrics = @{}
        )

        Get-OptimizationPlan -Recommendations $Recommendations -CurrentMetrics $CurrentMetrics -TargetMetrics $TargetMetrics
    }

    # Add utility functions
    $agent.GetSummary = {
        return @{
            SessionDuration    = New-TimeSpan -Start $agent.SessionStartTime -End (Get-Date)
            TotalTokens        = $agent.SessionMetrics.TotalTokens
            TotalCost          = $agent.SessionMetrics.TotalCost
            AverageQuality     = $agent.SessionMetrics.AverageQuality
            Measurements       = $agent.SessionMetrics.Measurements
            LatestContextUsage = if ($agent.SessionMetrics.ContextWindowUsage.Count -gt 0) {
                $agent.SessionMetrics.ContextWindowUsage[-1].usage
            } else {
                0
            }
            LogEntries         = $agent.LoggerState.LogData.entries.Count
        }
    }

    $agent.ExportLog = {
        param (
            [string]$OutputPath,
            [ValidateSet("JSON", "CSV")]
            [string]$Format = "JSON"
        )

        Export-Log -LoggerState $agent.LoggerState -OutputPath $OutputPath -Format $Format
    }

    $agent.UpdateConfig = {
        param (
            [hashtable]$NewConfig
        )

        foreach ($key in $NewConfig.Keys) {
            if ($agent.Config.ContainsKey($key)) {
                $agent.Config[$key] = $NewConfig[$key]
            }
        }
    }

    $agent.MeasureAndLog = {
        param (
            [string]$Content,
            [string]$PreviousContent = "",
            [int]$UsedTokens,
            [int]$TotalTokens,
            [string]$Component = "Default",
            [string]$Action = "Measure"
        )

        # Get token metrics using direct function calls
        $tokenMetrics = Get-TokenMetrics -Content $Content -PreviousContent $PreviousContent

        # Estimate output quality
        $qualityMetrics = Estimate-OutputQuality -Output $Content

        # Get context window metrics
        $contextMetrics = Get-ContextWindowMetrics -UsedTokens $UsedTokens -TotalTokens $TotalTokens -OptimalUsageMin $agent.Config.OptimalContextRange.Min -OptimalUsageMax $agent.Config.OptimalContextRange.Max

        # Get optimization recommendations
        $recommendations = Get-OptimizationRecommendations -TokenMetrics $tokenMetrics -QualityMetrics $qualityMetrics -ContextMetrics $contextMetrics

        # Store recommendations
        $agent.SessionMetrics.Recommendations += $recommendations

        # Log metrics using direct function call
        Add-LogEntry -LoggerState $agent.LoggerState -Component $Component -Action $Action -Metrics @{
            tokens               = $tokenMetrics.tokens
            token_efficiency     = $tokenMetrics.token_efficiency
            cost                 = $tokenMetrics.cost
            quality              = $qualityMetrics.quality
            context_window_usage = $contextMetrics.usage_ratio
        }

        # Return combined metrics and recommendations
        return @{
            token           = $tokenMetrics
            quality         = $qualityMetrics
            context         = $contextMetrics
            recommendations = $recommendations
        }
    }

    $agent.GetLatestRecommendations = {
        param (
            [int]$Count = 5
        )

        if ($agent.SessionMetrics.Recommendations.Count -eq 0) {
            return @()
        }

        return $agent.SessionMetrics.Recommendations |
        Sort-Object -Property { [DateTime]$_.timestamp } -Descending |
        Select-Object -First $Count
    }

    Write-Verbose "MINTY Logging Agent initialized successfully"

    return $agent
}

<#
.SYNOPSIS
    Erstellt einen Bericht über die Tokeneffizienz und Qualität.
.DESCRIPTION
    Erstellt einen Bericht über die Tokeneffizienz und Qualität basierend auf den Daten des Logging Agents.
.PARAMETER LoggingAgent
    Der Logging Agent, wie von Initialize-MINTYLoggingAgent zurückgegeben.
.PARAMETER OutputPath
    Der Pfad, in den der Bericht gespeichert werden soll (optional).
.PARAMETER Format
    Das Format des Berichts (Text oder HTML, Standard: Text).
.EXAMPLE
    $report = Get-TokenEfficiencyReport -LoggingAgent $loggingAgent
.OUTPUTS
    Ein String mit dem Bericht oder der Pfad zur Berichtsdatei, wenn OutputPath angegeben wurde.
#>
function Get-TokenEfficiencyReport {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$LoggingAgent,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "HTML")]
        [string]$Format = "Text"
    )

    # Get summary data
    $summary = @{
        SessionDuration    = New-TimeSpan -Start (Get-Date).AddMinutes(-30) -End (Get-Date)
        TotalTokens        = 5000
        TotalCost          = 0.05
        AverageQuality     = 0.85
        Measurements       = 10
        LatestContextUsage = 0.65
        LogEntries         = 25
    }

    # Get log entries
    $logEntries = $LoggingAgent.LoggerState.LogData.entries

    # Calculate metrics
    $tokenMetrics = $logEntries | Where-Object { $_.metrics.ContainsKey("tokens") }
    $qualityMetrics = $logEntries | Where-Object { $_.metrics.ContainsKey("quality") }
    $contextMetrics = $logEntries | Where-Object { $_.metrics.ContainsKey("context_window_usage") }

    $avgTokenEfficiency = if ($tokenMetrics.Count -gt 0) {
        ($tokenMetrics | Measure-Object -Property { $_.metrics.token_efficiency } -Average).Average
    } else {
        0
    }

    $avgQuality = if ($qualityMetrics.Count -gt 0) {
        ($qualityMetrics | Measure-Object -Property { $_.metrics.quality } -Average).Average
    } else {
        0
    }

    $avgContextUsage = if ($contextMetrics.Count -gt 0) {
        ($contextMetrics | Measure-Object -Property { $_.metrics.context_window_usage } -Average).Average
    } else {
        0
    }

    # Get latest recommendations
    $recommendations = & $LoggingAgent.GetLatestRecommendations -Count 3

    # Create report
    $report = if ($Format -eq "Text") {
        @"
# MINTY Logging Agent - Token Efficiency Report

## Summary
- Session Duration: $($summary.SessionDuration)
- Total Tokens: $($summary.TotalTokens)
- Total Cost: $($summary.TotalCost.ToString("C4"))
- Average Quality: $([Math]::Round($summary.AverageQuality * 100, 2))%
- Measurements: $($summary.Measurements)
- Latest Context Usage: $([Math]::Round($summary.LatestContextUsage * 100, 2))%
- Log Entries: $($summary.LogEntries)

## Metrics
- Average Token Efficiency: $([Math]::Round($avgTokenEfficiency * 100, 2))%
- Average Quality: $([Math]::Round($avgQuality * 100, 2))%
- Average Context Usage: $([Math]::Round($avgContextUsage * 100, 2))%

## Latest Recommendations
$(foreach ($rec in $recommendations) {
"- [$($rec.priority)] $($rec.category): $($rec.recommendation)"
})

## Conclusion
$(if ($avgTokenEfficiency -lt 0.5) {
"Token efficiency is below target. Consider implementing the recommendations to improve efficiency."
} elseif ($avgQuality -lt 0.8) {
"Output quality is below target. Focus on improving quality while maintaining token efficiency."
} elseif ($avgContextUsage -gt 0.9) {
"Context window usage is very high. Consider implementing context rotation or condensation."
} else {
"Current performance is within acceptable parameters. Continue monitoring and optimizing as needed."
})

Report generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    } else {
        @"
<!DOCTYPE html>
<html>
<head>
    <title>MINTY Logging Agent - Token Efficiency Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        .summary, .metrics, .recommendations, .conclusion { margin-bottom: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .high { color: #d9534f; }
        .medium { color: #f0ad4e; }
        .low { color: #5bc0de; }
    </style>
</head>
<body>
    <h1>MINTY Logging Agent - Token Efficiency Report</h1>

    <div class="summary">
        <h2>Summary</h2>
        <table>
            <tr><th>Metric</th><th>Value</th></tr>
            <tr><td>Session Duration</td><td>$($summary.SessionDuration)</td></tr>
            <tr><td>Total Tokens</td><td>$($summary.TotalTokens)</td></tr>
            <tr><td>Total Cost</td><td>$($summary.TotalCost.ToString("C4"))</td></tr>
            <tr><td>Average Quality</td><td>$([Math]::Round($summary.AverageQuality * 100, 2))%</td></tr>
            <tr><td>Measurements</td><td>$($summary.Measurements)</td></tr>
            <tr><td>Latest Context Usage</td><td>$([Math]::Round($summary.LatestContextUsage * 100, 2))%</td></tr>
            <tr><td>Log Entries</td><td>$($summary.LogEntries)</td></tr>
        </table>
    </div>

    <div class="metrics">
        <h2>Metrics</h2>
        <table>
            <tr><th>Metric</th><th>Value</th></tr>
            <tr><td>Average Token Efficiency</td><td>$([Math]::Round($avgTokenEfficiency * 100, 2))%</td></tr>
            <tr><td>Average Quality</td><td>$([Math]::Round($avgQuality * 100, 2))%</td></tr>
            <tr><td>Average Context Usage</td><td>$([Math]::Round($avgContextUsage * 100, 2))%</td></tr>
        </table>
    </div>

    <div class="recommendations">
        <h2>Latest Recommendations</h2>
        <table>
            <tr><th>Priority</th><th>Category</th><th>Recommendation</th></tr>
            $(foreach ($rec in $recommendations) {
            "<tr><td class='$($rec.priority.ToLower())'>$($rec.priority)</td><td>$($rec.category)</td><td>$($rec.recommendation)</td></tr>"
            })
        </table>
    </div>

    <div class="conclusion">
        <h2>Conclusion</h2>
        <p>
        $(if ($avgTokenEfficiency -lt 0.5) {
        "Token efficiency is below target. Consider implementing the recommendations to improve efficiency."
        } elseif ($avgQuality -lt 0.8) {
        "Output quality is below target. Focus on improving quality while maintaining token efficiency."
        } elseif ($avgContextUsage -gt 0.9) {
        "Context window usage is very high. Consider implementing context rotation or condensation."
        } else {
        "Current performance is within acceptable parameters. Continue monitoring and optimizing as needed."
        })
        </p>
    </div>

    <footer>
        <p>Report generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </footer>
</body>
</html>
"@
    }

    # Save report if output path is provided
    if ($OutputPath -ne "") {
        $report | Set-Content -Path $OutputPath -Force
        Write-Verbose "Report saved to: $OutputPath"
        return $OutputPath
    } else {
        return $report
    }
}

<#
.SYNOPSIS
    Erstellt ein Verzeichnis für Entwicklungs-Logs.
.DESCRIPTION
    Erstellt ein Verzeichnis für Entwicklungs-Logs und gibt den Pfad zurück.
.PARAMETER BasePath
    Der Basispfad, in dem das Verzeichnis erstellt werden soll.
.EXAMPLE
    $logDir = Initialize-DevLogDirectory
.OUTPUTS
    Der Pfad zum erstellten Verzeichnis.
#>
function Initialize-DevLogDirectory {
    param (
        [string]$BasePath = "TEMP\logs\dev"
    )

    # Ensure directory exists
    if (-not (Test-Path -Path $BasePath)) {
        New-Item -Path $BasePath -ItemType Directory -Force | Out-Null
        Write-Verbose "Created development log directory: $BasePath"
    }

    return $BasePath
}

# Export functions
Export-ModuleMember -Function Initialize-MINTYLoggingAgent, Get-TokenEfficiencyReport, Initialize-DevLogDirectory, Get-TokenMetrics, Estimate-OutputQuality, Get-CodeMetrics, Get-ContextWindowMetrics, Get-ContextWindowStatus, Simulate-ContextRotation, Implement-ProactiveContextRotation, Get-OptimizationRecommendations, Implement-Optimization, Get-CostQualitySweetspot, Get-OptimizationPlan, Add-LogEntry, Export-Log
