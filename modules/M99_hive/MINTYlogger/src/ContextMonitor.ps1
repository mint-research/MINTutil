# MINTY Logging Agent - Context Monitor Component

<#
.SYNOPSIS
    Berechnet Metriken für das Kontext-Window.
.DESCRIPTION
    Berechnet Metriken für das Kontext-Window, einschließlich Nutzungsverhältnis und verbleibende Kapazität.
.PARAMETER UsedTokens
    Die Anzahl der verwendeten Tokens im Kontext-Window.
.PARAMETER TotalTokens
    Die Gesamtanzahl der verfügbaren Tokens im Kontext-Window.
.PARAMETER OptimalUsageMin
    Der minimale optimale Nutzungsgrad (Standard: 0.5).
.PARAMETER OptimalUsageMax
    Der maximale optimale Nutzungsgrad (Standard: 0.8).
.EXAMPLE
    $contextMetrics = Get-ContextWindowMetrics -UsedTokens 10000 -TotalTokens 16000
.OUTPUTS
    Ein Hashtable mit Kontext-Window-Metriken.
#>
function Get-ContextWindowMetrics {
    param (
        [Parameter(Mandatory = $true)]
        [int]$UsedTokens,

        [Parameter(Mandatory = $true)]
        [int]$TotalTokens,

        [Parameter(Mandatory = $false)]
        [double]$OptimalUsageMin = 0.5,

        [Parameter(Mandatory = $false)]
        [double]$OptimalUsageMax = 0.8
    )

    $usageRatio = if ($TotalTokens -gt 0) {
        $UsedTokens / $TotalTokens
    } else {
        0
    }

    $isInOptimalRange = ($usageRatio -ge $OptimalUsageMin) -and ($usageRatio -le $OptimalUsageMax)

    $remainingTokens = $TotalTokens - $UsedTokens
    $remainingCapacityRatio = if ($TotalTokens -gt 0) {
        $remainingTokens / $TotalTokens
    } else {
        0
    }

    $result = @{
        used_tokens              = $UsedTokens
        total_tokens             = $TotalTokens
        usage_ratio              = $usageRatio
        is_in_optimal_range      = $isInOptimalRange
        remaining_tokens         = $remainingTokens
        remaining_capacity_ratio = $remainingCapacityRatio
        optimal_range            = @{
            min = $OptimalUsageMin
            max = $OptimalUsageMax
        }
    }

    Write-Verbose "Context window metrics: $UsedTokens/$TotalTokens tokens used ($([Math]::Round($usageRatio * 100, 2))%)"

    return $result
}

<#
.SYNOPSIS
    Ermittelt den Status des Kontext-Windows.
.DESCRIPTION
    Ermittelt den Status des Kontext-Windows basierend auf den Kontext-Metriken und gibt Empfehlungen.
.PARAMETER ContextMetrics
    Die Kontext-Metriken, wie von Get-ContextWindowMetrics zurückgegeben.
.EXAMPLE
    $status = Get-ContextWindowStatus -ContextMetrics $contextMetrics
.OUTPUTS
    Ein Hashtable mit Status und Empfehlungen.
#>
function Get-ContextWindowStatus {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ContextMetrics
    )

    $status = if ($ContextMetrics.usage_ratio -lt 0.3) {
        "Underutilized"
    } elseif ($ContextMetrics.usage_ratio -gt 0.9) {
        "Near Capacity"
    } elseif ($ContextMetrics.usage_ratio -gt 0.8) {
        "High Usage"
    } elseif ($ContextMetrics.usage_ratio -ge 0.5) {
        "Optimal"
    } else {
        "Low Usage"
    }

    $recommendation = switch ($status) {
        "Underutilized" { "Add more context to improve quality and efficiency" }
        "Near Capacity" { "Urgent: Perform context pruning or condensation to avoid token limit issues" }
        "High Usage" { "Monitor closely, prepare for context management or condensation" }
        "Optimal" { "Maintain current context management strategy" }
        "Low Usage" { "Consider adding more relevant context information" }
    }

    $action = switch ($status) {
        "Underutilized" { "expand_context" }
        "Near Capacity" { "condense_context" }
        "High Usage" { "prepare_condensation" }
        "Optimal" { "maintain" }
        "Low Usage" { "add_context" }
    }

    $urgency = switch ($status) {
        "Underutilized" { "low" }
        "Near Capacity" { "high" }
        "High Usage" { "medium" }
        "Optimal" { "none" }
        "Low Usage" { "low" }
    }

    $result = @{
        status         = $status
        recommendation = $recommendation
        action         = $action
        urgency        = $urgency
        metrics        = $ContextMetrics
    }

    Write-Verbose "Context window status: $status ($recommendation)"

    return $result
}

<#
.SYNOPSIS
    Simuliert eine Kontext-Rotation.
.DESCRIPTION
    Simuliert eine Kontext-Rotation basierend auf den aktuellen Kontext-Metriken und gibt die erwarteten Ergebnisse zurück.
.PARAMETER ContextMetrics
    Die Kontext-Metriken, wie von Get-ContextWindowMetrics zurückgegeben.
.PARAMETER RotationStrategy
    Die Strategie für die Kontext-Rotation.
.EXAMPLE
    $rotationSimulation = Simulate-ContextRotation -ContextMetrics $contextMetrics -RotationStrategy "balanced"
.OUTPUTS
    Ein Hashtable mit den simulierten Ergebnissen der Kontext-Rotation.
#>
function Simulate-ContextRotation {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ContextMetrics,

        [Parameter(Mandatory = $false)]
        [ValidateSet("aggressive", "balanced", "conservative")]
        [string]$RotationStrategy = "balanced"
    )

    # Define rotation parameters based on strategy
    $rotationParams = switch ($RotationStrategy) {
        "aggressive" {
            @{
                retention_ratio = 0.3  # Keep 30% of existing context
                priority_weight = 0.7  # High weight for priority items
                recency_weight  = 0.8   # High weight for recent items
            }
        }
        "balanced" {
            @{
                retention_ratio = 0.5  # Keep 50% of existing context
                priority_weight = 0.5  # Balanced weight for priority items
                recency_weight  = 0.5   # Balanced weight for recent items
            }
        }
        "conservative" {
            @{
                retention_ratio = 0.7  # Keep 70% of existing context
                priority_weight = 0.3  # Low weight for priority items
                recency_weight  = 0.3   # Low weight for recent items
            }
        }
    }

    # Calculate tokens to be rotated out
    $tokensToRotate = [Math]::Ceiling($ContextMetrics.used_tokens * (1 - $rotationParams.retention_ratio))

    # Calculate expected new usage after rotation
    $expectedNewUsage = $ContextMetrics.used_tokens - $tokensToRotate
    $expectedNewRatio = if ($ContextMetrics.total_tokens -gt 0) {
        $expectedNewUsage / $ContextMetrics.total_tokens
    } else {
        0
    }

    # Calculate available capacity after rotation
    $availableCapacity = $ContextMetrics.total_tokens - $expectedNewUsage

    $result = @{
        original_metrics         = $ContextMetrics
        rotation_strategy        = $RotationStrategy
        rotation_params          = $rotationParams
        tokens_rotated           = $tokensToRotate
        expected_new_usage       = $expectedNewUsage
        expected_new_ratio       = $expectedNewRatio
        available_capacity       = $availableCapacity
        estimated_quality_impact = EstimateQualityImpact -RotationAmount $tokensToRotate -TotalTokens $ContextMetrics.used_tokens -Strategy $RotationStrategy
    }

    Write-Verbose "Context rotation simulation ($RotationStrategy): $tokensToRotate tokens to rotate, new usage: $expectedNewUsage/$($ContextMetrics.total_tokens)"

    return $result
}

<#
.SYNOPSIS
    Schätzt die Auswirkungen einer Kontext-Rotation auf die Qualität.
.DESCRIPTION
    Schätzt die Auswirkungen einer Kontext-Rotation auf die Qualität basierend auf der Rotationsmenge und -strategie.
.PARAMETER RotationAmount
    Die Anzahl der zu rotierenden Tokens.
.PARAMETER TotalTokens
    Die Gesamtanzahl der Tokens im Kontext.
.PARAMETER Strategy
    Die Rotationsstrategie.
.EXAMPLE
    $qualityImpact = EstimateQualityImpact -RotationAmount 5000 -TotalTokens 10000 -Strategy "balanced"
.OUTPUTS
    Ein Wert zwischen -1 und 0, der die geschätzte Qualitätsauswirkung angibt.
#>
function EstimateQualityImpact {
    param (
        [Parameter(Mandatory = $true)]
        [int]$RotationAmount,

        [Parameter(Mandatory = $true)]
        [int]$TotalTokens,

        [Parameter(Mandatory = $false)]
        [ValidateSet("aggressive", "balanced", "conservative")]
        [string]$Strategy = "balanced"
    )

    # If no tokens to rotate or no tokens in total, no impact
    if ($RotationAmount -eq 0 -or $TotalTokens -eq 0) {
        return 0
    }

    # Calculate rotation ratio
    $rotationRatio = $RotationAmount / $TotalTokens

    # Base impact is proportional to rotation ratio
    $baseImpact = - $rotationRatio

    # Adjust based on strategy
    $strategyFactor = switch ($Strategy) {
        "aggressive" { 0.7 }    # Aggressive rotation has higher impact
        "balanced" { 0.5 }      # Balanced rotation has moderate impact
        "conservative" { 0.3 }  # Conservative rotation has lower impact
    }

    # Calculate final impact (negative value, as rotation typically reduces quality)
    $impact = $baseImpact * $strategyFactor

    # Ensure impact is between -1 and 0
    return [Math]::Max(-1, [Math]::Min(0, $impact))
}

<#
.SYNOPSIS
    Implementiert eine proaktive Kontext-Rotation.
.DESCRIPTION
    Implementiert eine proaktive Kontext-Rotation basierend auf den aktuellen Kontext-Metriken und der gewählten Strategie.
.PARAMETER ContextMetrics
    Die Kontext-Metriken, wie von Get-ContextWindowMetrics zurückgegeben.
.PARAMETER RotationStrategy
    Die Strategie für die Kontext-Rotation.
.PARAMETER ContextSegments
    Die Segmente des Kontexts, die für die Rotation berücksichtigt werden sollen.
.EXAMPLE
    $rotationResult = Implement-ProactiveContextRotation -ContextMetrics $contextMetrics -RotationStrategy "balanced" -ContextSegments $segments
.OUTPUTS
    Ein Hashtable mit den Ergebnissen der Kontext-Rotation.
#>
function Implement-ProactiveContextRotation {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ContextMetrics,

        [Parameter(Mandatory = $false)]
        [ValidateSet("aggressive", "balanced", "conservative")]
        [string]$RotationStrategy = "balanced",

        [Parameter(Mandatory = $true)]
        [array]$ContextSegments
    )

    # First, simulate rotation to get parameters
    $simulation = Simulate-ContextRotation -ContextMetrics $ContextMetrics -RotationStrategy $RotationStrategy

    # If no rotation needed, return early
    if ($simulation.tokens_rotated -eq 0) {
        return @{
            success           = $true
            message           = "No rotation needed"
            tokens_rotated    = 0
            segments_affected = 0
            new_context_size  = $ContextMetrics.used_tokens
        }
    }

    # Calculate priority scores for each segment
    $scoredSegments = @()
    foreach ($segment in $ContextSegments) {
        # Calculate base score based on segment properties
        $priorityScore = 0

        # Priority based on segment type
        $typePriority = switch ($segment.type) {
            "task_definition" { 0.9 }  # Very high priority
            "code_context" { 0.7 }     # High priority
            "system_prompt" { 0.8 }    # High priority
            "recent_decision" { 0.6 }  # Medium-high priority
            "chat_history" { 0.4 }     # Medium priority
            "background_info" { 0.3 }  # Lower priority
            default { 0.5 }            # Default medium priority
        }

        # Adjust by recency if available
        $recencyFactor = if ($segment.ContainsKey("timestamp")) {
            $age = (Get-Date) - [DateTime]$segment.timestamp
            [Math]::Exp(-$age.TotalHours / 24)  # Exponential decay based on age in days
        } else {
            0.5  # Default middle value if no timestamp
        }

        # Adjust by explicit priority if available
        $explicitPriority = if ($segment.ContainsKey("priority")) {
            switch ($segment.priority) {
                "high" { 0.8 }
                "medium" { 0.5 }
                "low" { 0.2 }
                default { 0.5 }
            }
        } else {
            0.5  # Default middle value if no explicit priority
        }

        # Calculate final score
        # Weight factors based on rotation strategy
        $typeWeight = 0.4
        $recencyWeight = $simulation.rotation_params.recency_weight
        $priorityWeight = $simulation.rotation_params.priority_weight

        $finalScore = ($typePriority * $typeWeight) +
                      ($recencyFactor * $recencyWeight) +
                      ($explicitPriority * $priorityWeight)

        # Normalize to 0-1 range
        $finalScore = [Math]::Min(1, [Math]::Max(0, $finalScore))

        # Add to scored segments
        $scoredSegments += @{
            segment = $segment
            score   = $finalScore
            tokens  = $segment.tokens
        }
    }

    # Sort segments by score (ascending, so lowest priority first)
    $sortedSegments = $scoredSegments | Sort-Object -Property score

    # Select segments to rotate out until we reach the target
    $segmentsToRotate = @()
    $tokensRotated = 0
    $targetTokens = $simulation.tokens_rotated

    foreach ($scoredSegment in $sortedSegments) {
        # If we've reached our target, stop
        if ($tokensRotated -ge $targetTokens) {
            break
        }

        # Add this segment to rotation list
        $segmentsToRotate += $scoredSegment.segment
        $tokensRotated += $scoredSegment.tokens
    }

    # Calculate new context size
    $newContextSize = $ContextMetrics.used_tokens - $tokensRotated

    # Return rotation results
    $result = @{
        success           = $true
        message           = "Rotation completed successfully"
        tokens_rotated    = $tokensRotated
        segments_affected = $segmentsToRotate.Count
        segments_rotated  = $segmentsToRotate
        new_context_size  = $newContextSize
        new_usage_ratio   = if ($ContextMetrics.total_tokens -gt 0) {
            $newContextSize / $ContextMetrics.total_tokens
        } else {
            0
        }
        rotation_strategy = $RotationStrategy
        quality_impact    = EstimateQualityImpact -RotationAmount $tokensRotated -TotalTokens $ContextMetrics.used_tokens -Strategy $RotationStrategy
    }

    Write-Verbose "Proactive context rotation: $tokensRotated tokens rotated across $($segmentsToRotate.Count) segments"

    return $result
}
