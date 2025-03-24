# MINTYcache - Context Window Manager
# Manages and optimizes the context window for LLMs

class ContextWindowManager {
    [hashtable] $Config
    [hashtable] $Stats
    
    ContextWindowManager([hashtable]$config) {
        $this.Config = $config
        $this.Stats = @{
            rotationCount = 0
            optimizationCount = 0
            tokensSaved = 0
            averageUsage = 0
            usageSamples = 0
        }
    }
    
    [hashtable] GetStatus([int]$usedTokens, [int]$totalTokens) {
        $usage = $usedTokens / $totalTokens
        
        # Update stats
        $this.Stats.usageSamples++
        $this.Stats.averageUsage = (($this.Stats.averageUsage * ($this.Stats.usageSamples - 1)) + $usage) / $this.Stats.usageSamples
        
        $status = @{
            usedTokens = $usedTokens
            totalTokens = $totalTokens
            usage = $usage
            timestamp = Get-Date
        }
        
        # Determine status based on usage
        if ($usage -lt $this.Config.optimalUsageMin) {
            $status.status = 'Underutilized'
            $status.recommendation = 'Consider adding more context to improve model performance'
            $status.action = 'expand'
            $status.urgency = 'low'
        }
        elseif ($usage -gt $this.Config.optimalUsageMax) {
            if ($usage -gt $this.Config.rotationThreshold) {
                $status.status = 'Critical'
                $status.recommendation = 'Context window nearly full. Immediate rotation recommended'
                $status.action = 'rotate'
                $status.urgency = 'high'
            }
            else {
                $status.status = 'High'
                $status.recommendation = 'Context window usage high. Consider optimization or rotation'
                $status.action = 'optimize'
                $status.urgency = 'medium'
            }
        }
        else {
            $status.status = 'Optimal'
            $status.recommendation = 'Maintain current context management strategy'
            $status.action = 'maintain'
            $status.urgency = 'none'
        }
        
        return $status
    }
    
    [hashtable] GetStats() {
        return $this.Stats
    }
}

# Export the class
Export-ModuleMember -Variable ContextWindowManager
