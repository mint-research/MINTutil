# MINTY Logging Agent - Example Usage

# Import the module
Import-Module "$PSScriptRoot\MINTYLoggingAgent.psm1" -Force

# Create log directory for development logs
$devLogDir = Initialize-DevLogDirectory -BasePath "TEMP\logs\dev"
Write-Host "Development log directory: $devLogDir"

# Initialize the logging agent
$loggingAgent = Initialize-MINTYLoggingAgent -LogDirectory $devLogDir -VerboseOutput
Write-Host "Logging agent initialized"

# Example 1: Measure and log a simple operation
Write-Host "`nExample 1: Measuring a simple operation"
$content = "This is a sample content that we want to measure."
$metrics = & {
    param($Content, $UsedTokens, $TotalTokens, $Component, $Action)

    # Get token metrics using direct function calls
    $tokenMetrics = Get-TokenMetrics -Content $Content -PreviousContent ""

    # Estimate output quality
    $qualityMetrics = Estimate-OutputQuality -Output $Content

    # Get context window metrics
    $contextMetrics = Get-ContextWindowMetrics -UsedTokens $UsedTokens -TotalTokens $TotalTokens -OptimalUsageMin 0.5 -OptimalUsageMax 0.8

    # Return metrics
    return @{
        token   = $tokenMetrics
        quality = $qualityMetrics
        context = $contextMetrics
    }
} -Content $content -UsedTokens 1000 -TotalTokens 16000 -Component "Example" -Action "SimpleOperation"
Write-Host "Tokens: $($metrics.token.tokens)"
Write-Host "Quality: $([Math]::Round($metrics.quality.quality * 100, 2))%"
Write-Host "Context usage: $([Math]::Round($metrics.context.usage_ratio * 100, 2))%"

# Example 2: Measure token efficiency between versions
Write-Host "`nExample 2: Measuring token efficiency between versions"
$previousContent = "This is the previous version of the content."
$newContent = "This is the new version of the content with some additional information that makes it more detailed and comprehensive."
$tokenMetrics = Get-TokenMetrics -Content $newContent -PreviousContent $previousContent
Write-Host "Previous tokens: $($tokenMetrics.previous_tokens)"
Write-Host "New tokens: $($tokenMetrics.tokens)"
Write-Host "Token difference: $($tokenMetrics.token_diff)"
Write-Host "Token efficiency: $([Math]::Round($tokenMetrics.token_efficiency * 100, 2))%"

# Example 3: Estimate output quality
Write-Host "`nExample 3: Estimating output quality"
$output = @"
# Sample Output

This is a sample output that demonstrates the quality estimation capabilities of the MINTY Logging Agent.

## Features

- Quality estimation based on multiple criteria
- Completeness assessment
- Clarity measurement
- Conciseness evaluation

The agent analyzes various aspects of the output to provide a comprehensive quality score.
"@
$qualityMetrics = Estimate-OutputQuality -Output $output
Write-Host "Overall quality: $([Math]::Round($qualityMetrics.quality * 100, 2))%"
Write-Host "Completeness: $([Math]::Round($qualityMetrics.components.completeness * 100, 2))%"
Write-Host "Correctness: $([Math]::Round($qualityMetrics.components.correctness * 100, 2))%"
Write-Host "Clarity: $([Math]::Round($qualityMetrics.components.clarity * 100, 2))%"
Write-Host "Conciseness: $([Math]::Round($qualityMetrics.components.conciseness * 100, 2))%"

# Example 4: Monitor context window
Write-Host "`nExample 4: Monitoring context window"
$contextMetrics = Get-ContextWindowMetrics -UsedTokens 12000 -TotalTokens 16000
$contextStatus = Get-ContextWindowStatus -ContextMetrics $contextMetrics
Write-Host "Context usage: $([Math]::Round($contextMetrics.usage_ratio * 100, 2))%"
Write-Host "Status: $($contextStatus.status)"
Write-Host "Recommendation: $($contextStatus.recommendation)"
Write-Host "Action: $($contextStatus.action)"
Write-Host "Urgency: $($contextStatus.urgency)"

# Example 5: Simulate context rotation
Write-Host "`nExample 5: Simulating context rotation"
$rotationSimulation = Simulate-ContextRotation -ContextMetrics $contextMetrics -RotationStrategy "balanced"
Write-Host "Tokens to rotate: $($rotationSimulation.tokens_rotated)"
Write-Host "Expected new usage: $($rotationSimulation.expected_new_usage) tokens ($([Math]::Round($rotationSimulation.expected_new_ratio * 100, 2))%)"
Write-Host "Available capacity after rotation: $($rotationSimulation.available_capacity) tokens"
Write-Host "Estimated quality impact: $([Math]::Round($rotationSimulation.estimated_quality_impact * 100, 2))%"

# Example 6: Get optimization recommendations
Write-Host "`nExample 6: Getting optimization recommendations"
$recommendations = Get-OptimizationRecommendations -TokenMetrics $tokenMetrics -QualityMetrics $qualityMetrics -ContextMetrics $contextMetrics
Write-Host "Number of recommendations: $($recommendations.Count)"
foreach ($rec in $recommendations) {
    Write-Host "[$($rec.priority)] $($rec.category): $($rec.recommendation)"
}

# Example 7: Create an optimization plan
Write-Host "`nExample 7: Creating an optimization plan"
$currentMetrics = @{
    token   = $tokenMetrics
    quality = $qualityMetrics
    context = $contextMetrics
}
$plan = Get-OptimizationPlan -Recommendations $recommendations -CurrentMetrics $currentMetrics
Write-Host "Number of actions: $($plan.actions.Count)"
Write-Host "Expected token reduction: $([Math]::Round($plan.expected_outcomes.token_reduction, 2)) tokens"
Write-Host "Expected quality improvement: $([Math]::Round($plan.expected_outcomes.quality_improvement * 100, 2))%"
Write-Host "Expected context optimization: $([Math]::Round($plan.expected_outcomes.context_optimization * 100, 2))%"

# Example 8: Generate a token efficiency report
Write-Host "`nExample 8: Generating a token efficiency report"
$reportPath = Join-Path -Path $devLogDir -ChildPath "token_efficiency_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$report = Get-TokenEfficiencyReport -LoggingAgent $loggingAgent -OutputPath $reportPath
Write-Host "Report saved to: $report"

# Example 9: Implement proactive context rotation
Write-Host "`nExample 9: Implementing proactive context rotation"
$contextSegments = @(
    @{
        type     = "task_definition"
        tokens   = 1000
        priority = "high"
    },
    @{
        type     = "code_context"
        tokens   = 3000
        priority = "medium"
    },
    @{
        type      = "chat_history"
        tokens    = 8000
        priority  = "low"
        timestamp = (Get-Date).AddHours(-2).ToString("o")
    }
)
$rotationResult = Implement-ProactiveContextRotation -ContextMetrics $contextMetrics -RotationStrategy "balanced" -ContextSegments $contextSegments
Write-Host "Rotation success: $($rotationResult.success)"
Write-Host "Tokens rotated: $($rotationResult.tokens_rotated)"
Write-Host "Segments affected: $($rotationResult.segments_affected)"
Write-Host "New context size: $($rotationResult.new_context_size) tokens ($([Math]::Round($rotationResult.new_usage_ratio * 100, 2))%)"
Write-Host "Quality impact: $([Math]::Round($rotationResult.quality_impact * 100, 2))%"

# Example 10: Get session summary
Write-Host "`nExample 10: Getting session summary"
$summary = @{
    SessionDuration    = New-TimeSpan -Start (Get-Date).AddMinutes(-30) -End (Get-Date)
    TotalTokens        = 5000
    TotalCost          = 0.05
    AverageQuality     = 0.85
    Measurements       = 10
    LatestContextUsage = 0.65
    LogEntries         = 25
}
Write-Host "Session duration: $($summary.SessionDuration)"
Write-Host "Total tokens: $($summary.TotalTokens)"
Write-Host "Total cost: $($summary.TotalCost.ToString('C4'))"
Write-Host "Average quality: $([Math]::Round($summary.AverageQuality * 100, 2))%"
Write-Host "Measurements: $($summary.Measurements)"
Write-Host "Latest context usage: $([Math]::Round($summary.LatestContextUsage * 100, 2))%"
Write-Host "Log entries: $($summary.LogEntries)"

# Export log to JSON
$jsonLogPath = Join-Path -Path $devLogDir -ChildPath "log_export_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
# Create an empty file to simulate the export
New-Item -Path $jsonLogPath -ItemType File -Force | Out-Null
Write-Host "`nLog exported to: $jsonLogPath"

Write-Host "`nExample usage completed. Check the log files and reports in: $devLogDir"
