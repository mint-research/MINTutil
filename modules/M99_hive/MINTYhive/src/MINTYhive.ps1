# MINTYhive Manager
# Beschreibung: Hauptkomponente des Hive-Agents für die Orchestrierung aller Agenten

# Importiere benötigte Module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path (Split-Path -Parent $scriptPath) "config"
$dataPath = Join-Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) "data"

# Globale Variablen
$script:ConfigFile = Join-Path $configPath "hive_config.json"
$script:CapabilitiesFile = Join-Path $dataPath "capabilities.json"
$script:Config = $null
$script:Agents = @{}
$script:AgentStatus = @{}
$script:CommunicationPaths = @{}
$script:Capabilities = @{}

<#
.SYNOPSIS
    Initialisiert den Hive Manager.
.DESCRIPTION
    Lädt die Konfiguration und initialisiert den Hive Manager.
#>
function Initialize-HiveManager {
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
                "Agents"                  = @(
                    "MINTYmanager",
                    "MINTYarchitect",
                    "MINTYcoder",
                    "MINTYtester",
                    "MINTYarchivar",
                    "MINTYcache",
                    "MINTYlogger",
                    "MINTYcleaner",
                    "MINTYupdater",
                    "MINTYgit"
                )
                "Schedule"                = @{
                    "Continuous"            = $true
                    "ReevaluationInterval"  = "5s"
                    "CoordinationWindow"    = "100ms"
                    "AdjustsOtherSchedules" = $true
                }
                "Interfaces"              = @{
                    "AllAgents"       = $true
                    "Log"             = $true
                    "Manager"         = $true
                    "ExternalSystems" = $false
                }
                "CommunicationPriorities" = @{
                    "MINTYmanager"   = 1
                    "MINTYarchitect" = 2
                    "MINTYcoder"     = 3
                    "MINTYtester"    = 4
                    "MINTYarchivar"  = 5
                    "MINTYcache"     = 6
                    "MINTYlogger"    = 7
                    "MINTYcleaner"   = 8
                    "MINTYupdater"   = 9
                    "MINTYgit"       = 10
                }
                "CapabilityManagement"    = @{
                    "ProactiveDevelopment"     = $true
                    "UserConfirmationRequired" = $true
                    "AutoUpdateCapabilities"   = $true
                }
            }

            # Speichere Standardkonfiguration
            $script:Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile
        }

        # Initialisiere Agenten-Status
        foreach ($agent in $script:Config.Agents) {
            $script:AgentStatus[$agent] = @{
                "Status"       = "Inactive"
                "LastUpdate"   = [DateTime]::Now
                "Tasks"        = @()
                "Resources"    = @{}
                "Conflicts"    = @()
                "Capabilities" = @()
            }
        }

        # Lade Capabilities
        if (Test-Path $script:CapabilitiesFile) {
            $script:Capabilities = Get-Content -Path $script:CapabilitiesFile -Raw | ConvertFrom-Json
        } else {
            # Erstelle Standard-Capabilities
            $script:Capabilities = @{
                "AgentCapabilities"  = @{
                    "MINTYmanager"   = @("ProjectManagement", "TaskTracking", "Roadmapping", "Backlog", "CapabilityChecking")
                    "MINTYarchitect" = @("SystemDesign", "ArchitectureReview", "TechnicalPlanning", "DesignPatterns")
                    "MINTYcoder"     = @("CodeGeneration", "CodeReview", "Refactoring", "Debugging", "PowerShell", "Scripting")
                    "MINTYtester"    = @("UnitTesting", "IntegrationTesting", "TestAutomation", "QualityAssurance")
                    "MINTYarchivar"  = @("DataArchiving", "VersionHistory", "DataRetention")
                    "MINTYcache"     = @("CacheManagement", "MemoryOptimization", "DataCaching")
                    "MINTYlogger"    = @("Logging", "LogAnalysis", "ErrorTracking", "AuditTrail")
                    "MINTYcleaner"   = @("SystemCleaning", "TempFileCleaning", "ResourceOptimization")
                    "MINTYupdater"   = @("SystemUpdates", "ModuleUpdates", "UpdateManagement")
                    "MINTYgit"       = @("VersionControl", "ReleaseManagement", "ChangeTracking")
                }
                "GlobalCapabilities" = @(
                    "PowerShell", "Scripting", "FileManagement", "LogManagement",
                    "ConfigurationManagement", "ErrorHandling", "Logging", "Monitoring"
                )
                "LastUpdated"        = [DateTime]::Now.ToString("o")
            }

            # Speichere Standard-Capabilities
            $script:Capabilities | ConvertTo-Json -Depth 10 | Set-Content -Path $script:CapabilitiesFile
        }

        # Initialisiere Kommunikationspfade
        Initialize-CommunicationPaths

        Write-Host "Hive Manager initialisiert"
        return $true
    } catch {
        Write-Error "Fehler bei der Initialisierung des Hive Managers: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Initialisiert die Kommunikationspfade zwischen Agenten.
.DESCRIPTION
    Erstellt die Kommunikationspfade zwischen allen Agenten basierend auf den Prioritäten.
#>
function Initialize-CommunicationPaths {
    try {
        $script:CommunicationPaths = @{}

        # Erstelle Kommunikationspfade für jeden Agenten
        foreach ($agent in $script:Config.Agents) {
            $script:CommunicationPaths[$agent] = @{
                "Inputs"   = @()
                "Outputs"  = @()
                "Priority" = $script:Config.CommunicationPriorities[$agent]
            }
        }

        # Verbinde Agenten basierend auf Prioritäten und Abhängigkeiten
        # Dies ist eine vereinfachte Implementierung, die in der Praxis erweitert werden sollte

        # MINTYcache ist mit allen verbunden (Kontext-Management)
        foreach ($agent in $script:Config.Agents) {
            if ($agent -ne "MINTYcache") {
                $script:CommunicationPaths["MINTYcache"].Outputs += $agent
                $script:CommunicationPaths[$agent].Inputs += "MINTYcache"
            }
        }

        # MINTYlogger ist mit allen verbunden (Logging)
        foreach ($agent in $script:Config.Agents) {
            if ($agent -ne "MINTYlogger") {
                $script:CommunicationPaths["MINTYlogger"].Inputs += $agent
                $script:CommunicationPaths[$agent].Outputs += "MINTYlogger"
            }
        }

        # Spezifische Verbindungen basierend auf Workflow
        $script:CommunicationPaths["MINTYmanager"].Outputs += "MINTYarchitect"
        $script:CommunicationPaths["MINTYarchitect"].Inputs += "MINTYmanager"

        $script:CommunicationPaths["MINTYarchitect"].Outputs += "MINTYcoder"
        $script:CommunicationPaths["MINTYcoder"].Inputs += "MINTYarchitect"

        $script:CommunicationPaths["MINTYcoder"].Outputs += "MINTYtester"
        $script:CommunicationPaths["MINTYtester"].Inputs += "MINTYcoder"

        $script:CommunicationPaths["MINTYcoder"].Outputs += "MINTYgit"
        $script:CommunicationPaths["MINTYgit"].Inputs += "MINTYcoder"

        $script:CommunicationPaths["MINTYcleaner"].Inputs += "MINTYcoder"
        $script:CommunicationPaths["MINTYcoder"].Outputs += "MINTYcleaner"

        $script:CommunicationPaths["MINTYupdater"].Inputs += "MINTYarchivar"
        $script:CommunicationPaths["MINTYarchivar"].Outputs += "MINTYupdater"

        Write-Host "Kommunikationspfade initialisiert"
        return $true
    } catch {
        Write-Error "Fehler bei der Initialisierung der Kommunikationspfade: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Orchestriert alle Agenten und ihre Interaktionen.
.DESCRIPTION
    Koordiniert die Kommunikation und Aufgabenverteilung zwischen allen Agenten.
.PARAMETER Continuous
    Gibt an, ob die Orchestrierung kontinuierlich ausgeführt werden soll.
#>
function Invoke-AgentOrchestration {
    param(
        [Parameter(Mandatory = $false)][bool]$Continuous = $false
    )

    try {
        Write-Host "Starte Agenten-Orchestrierung..."

        # Wenn kontinuierlich, führe in einer Schleife aus
        if ($Continuous -or $script:Config.Schedule.Continuous) {
            $running = $true
            while ($running) {
                $result = Orchestrate-SingleCycle
                if (-not $result) {
                    Write-Warning "Orchestrierungszyklus fehlgeschlagen, versuche erneut..."
                }

                # Warte für das Reevaluierungsintervall
                $interval = [TimeSpan]::FromSeconds([int]($script:Config.Schedule.ReevaluationInterval -replace "s", ""))
                Start-Sleep -Milliseconds $interval.TotalMilliseconds
            }
        } else {
            # Einmalige Ausführung
            return Orchestrate-SingleCycle
        }

        return $true
    } catch {
        Write-Error "Fehler bei der Agenten-Orchestrierung: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Führt einen einzelnen Orchestrierungszyklus aus.
.DESCRIPTION
    Koordiniert einen einzelnen Zyklus der Kommunikation und Aufgabenverteilung zwischen allen Agenten.
#>
function Orchestrate-SingleCycle {
    try {
        # Sammle Status aller Agenten
        Update-AgentStatus

        # Optimiere Kommunikationspfade basierend auf aktuellem Status
        Optimize-CommunicationPaths

        # Erkenne und löse Konflikte
        Resolve-AgentConflicts

        # Verteile Aufgaben basierend auf Prioritäten und Verfügbarkeit
        Distribute-AgentTasks

        # Überwache Systemzustand
        Monitor-SystemState

        return $true
    } catch {
        Write-Error "Fehler bei der Ausführung eines Orchestrierungszyklus: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Aktualisiert den Status aller Agenten.
.DESCRIPTION
    Sammelt Statusinformationen von allen Agenten.
#>
function Update-AgentStatus {
    try {
        foreach ($agent in $script:Config.Agents) {
            # In einer realen Implementierung würde hier eine Kommunikation mit dem Agenten stattfinden
            # Für diese Beispielimplementierung simulieren wir den Status

            $script:AgentStatus[$agent].LastUpdate = [DateTime]::Now

            # Simuliere verschiedene Status basierend auf Agent-Typ
            switch ($agent) {
                "MINTYcache" {
                    $script:AgentStatus[$agent].Status = "Active"
                    $script:AgentStatus[$agent].Resources = @{
                        "MemoryUsage" = "45%"
                        "CacheSize"   = "128MB"
                    }
                }
                "MINTYlog" {
                    $script:AgentStatus[$agent].Status = "Active"
                    $script:AgentStatus[$agent].Resources = @{
                        "LogEntries" = 1245
                        "ErrorRate"  = "0.5%"
                    }
                }
                default {
                    $script:AgentStatus[$agent].Status = "Standby"
                    $script:AgentStatus[$agent].Resources = @{
                        "CPUUsage"    = "5%"
                        "MemoryUsage" = "10%"
                    }
                }
            }
        }

        return $true
    } catch {
        Write-Error "Fehler beim Aktualisieren des Agenten-Status: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Optimiert die Kommunikationspfade zwischen Agenten.
.DESCRIPTION
    Passt die Kommunikationspfade basierend auf dem aktuellen Systemzustand an.
#>
function Optimize-CommunicationPaths {
    try {
        # Identifiziere aktive Agenten
        $activeAgents = $script:Config.Agents | Where-Object { $script:AgentStatus[$_].Status -eq "Active" }

        # Priorisiere Kommunikationspfade zu aktiven Agenten
        foreach ($agent in $activeAgents) {
            # Implementiere Optimierungslogik hier
            # ...
        }

        return $true
    } catch {
        Write-Error "Fehler bei der Optimierung der Kommunikationspfade: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Erkennt und löst Konflikte zwischen Agenten.
.DESCRIPTION
    Identifiziert und löst Konflikte, Redundanzen und Blockaden zwischen Agenten.
#>
function Resolve-AgentConflicts {
    try {
        $conflicts = @()

        # Identifiziere Konflikte
        foreach ($agent1 in $script:Config.Agents) {
            foreach ($agent2 in $script:Config.Agents) {
                if ($agent1 -ne $agent2) {
                    # Überprüfe auf Ressourcenkonflikte
                    # Implementiere Konflikterkennungslogik hier
                    # ...
                }
            }
        }

        # Löse Konflikte
        foreach ($conflict in $conflicts) {
            # Implementiere Konfliktlösungslogik hier
            # ...
        }

        return $true
    } catch {
        Write-Error "Fehler bei der Erkennung und Lösung von Agenten-Konflikten: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Verteilt Aufgaben an Agenten.
.DESCRIPTION
    Verteilt Aufgaben basierend auf Prioritäten und Verfügbarkeit der Agenten.
#>
function Distribute-AgentTasks {
    try {
        # Implementiere Aufgabenverteilungslogik hier
        # ...

        return $true
    } catch {
        Write-Error "Fehler bei der Verteilung von Agenten-Aufgaben: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Überwacht den Systemzustand.
.DESCRIPTION
    Überwacht den Zustand des Gesamtsystems und passt die Orchestrierung entsprechend an.
#>
function Monitor-SystemState {
    try {
        # Sammle Systemmetriken
        $metrics = @{
            "AgentCount"             = $script:Config.Agents.Count
            "ActiveAgents"           = ($script:Config.Agents | Where-Object { $script:AgentStatus[$_].Status -eq "Active" }).Count
            "ConflictCount"          = 0
            "CommunicationPathCount" = 0
        }

        # Zähle Kommunikationspfade
        foreach ($agent in $script:Config.Agents) {
            $metrics.CommunicationPathCount += $script:CommunicationPaths[$agent].Inputs.Count
            $metrics.CommunicationPathCount += $script:CommunicationPaths[$agent].Outputs.Count
        }

        # Logge Systemzustand
        Write-Host "Systemzustand: $($metrics.ActiveAgents)/$($metrics.AgentCount) Agenten aktiv, $($metrics.ConflictCount) Konflikte, $($metrics.CommunicationPathCount) Kommunikationspfade"

        return $true
    } catch {
        Write-Error "Fehler bei der Überwachung des Systemzustands: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Prüft die Verfügbarkeit einer Fähigkeit im System.
.DESCRIPTION
    Prüft, ob eine bestimmte Fähigkeit im System verfügbar ist.
.PARAMETER Capability
    Die zu prüfende Fähigkeit.
#>
function Test-CapabilityAvailability {
    param(
        [Parameter(Mandatory = $true)][string]$Capability
    )

    try {
        # Prüfe in globalen Fähigkeiten
        if ($script:Capabilities.GlobalCapabilities -contains $Capability) {
            return @{
                "Available" = $true
                "Agent"     = "Global"
                "Details"   = "Globale Fähigkeit, verfügbar in allen Agenten"
            }
        }

        # Prüfe in agenten-spezifischen Fähigkeiten
        foreach ($agent in $script:Config.Agents) {
            if ($script:Capabilities.AgentCapabilities.$agent -contains $Capability) {
                return @{
                    "Available" = $true
                    "Agent"     = $agent
                    "Details"   = "Fähigkeit verfügbar in Agent $agent"
                }
            }
        }

        # Fähigkeit nicht gefunden
        return @{
            "Available" = $false
            "Agent"     = $null
            "Details"   = "Fähigkeit nicht verfügbar im System"
        }
    } catch {
        Write-Error "Fehler bei der Prüfung der Fähigkeitsverfügbarkeit: $_"
        return @{
            "Available" = $false
            "Agent"     = $null
            "Details"   = "Fehler bei der Prüfung: $_"
        }
    }
}

<#
.SYNOPSIS
    Findet den am besten geeigneten Agenten für eine neue Fähigkeit.
.DESCRIPTION
    Analysiert, welcher Agent am besten für die Implementierung einer neuen Fähigkeit geeignet ist.
.PARAMETER Capability
    Die zu implementierende Fähigkeit.
#>
function Find-BestAgentForCapability {
    param(
        [Parameter(Mandatory = $true)][string]$Capability
    )

    try {
        $bestAgent = $null
        $bestScore = 0

        # Analysiere jeden Agenten
        foreach ($agent in $script:Config.Agents) {
            $score = 0

            # Prüfe auf ähnliche Fähigkeiten
            foreach ($existingCapability in $script:Capabilities.AgentCapabilities.$agent) {
                # Einfache Ähnlichkeitsprüfung basierend auf gemeinsamen Teilstrings
                # In einer realen Implementierung würde hier eine komplexere Analyse stattfinden
                if ($existingCapability -like "*$Capability*" -or $Capability -like "*$existingCapability*") {
                    $score += 2
                }

                # Prüfe auf Wortübereinstimmungen
                $capWords = $Capability -split '[^a-zA-Z0-9]'
                $existingWords = $existingCapability -split '[^a-zA-Z0-9]'

                foreach ($word in $capWords) {
                    if ($word -and $existingWords -contains $word) {
                        $score += 1
                    }
                }
            }

            # Berücksichtige Priorität des Agenten
            $priority = $script:Config.CommunicationPriorities.$agent
            if ($priority) {
                # Höhere Priorität (niedrigere Zahl) ist besser
                $score += (11 - $priority) / 2
            }

            # Aktualisiere besten Agenten, wenn Score höher ist
            if ($score -gt $bestScore) {
                $bestScore = $score
                $bestAgent = $agent
            }
        }

        # Wenn kein passender Agent gefunden wurde, verwende MINTYcode als Standard
        if (-not $bestAgent -or $bestScore -lt 1) {
            return @{
                "Agent"    = "MINTYcode"
                "Score"    = 0
                "Reason"   = "Kein passender Agent gefunden, verwende MINTYcode als Standard"
                "NewAgent" = $true
            }
        }

        return @{
            "Agent"    = $bestAgent
            "Score"    = $bestScore
            "Reason"   = "Agent hat ähnliche Fähigkeiten und eine hohe Priorität"
            "NewAgent" = $false
        }
    } catch {
        Write-Error "Fehler bei der Suche nach dem besten Agenten: $_"
        return @{
            "Agent"    = "MINTYcode"
            "Score"    = 0
            "Reason"   = "Fehler bei der Suche: $_"
            "NewAgent" = $true
        }
    }
}

<#
.SYNOPSIS
    Fügt eine neue Fähigkeit zu einem Agenten hinzu.
.DESCRIPTION
    Erweitert einen bestehenden Agenten um eine neue Fähigkeit.
.PARAMETER Agent
    Der zu erweiternde Agent.
.PARAMETER Capability
    Die hinzuzufügende Fähigkeit.
#>
function Add-AgentCapability {
    param(
        [Parameter(Mandatory = $true)][string]$Agent,
        [Parameter(Mandatory = $true)][string]$Capability
    )

    try {
        # Prüfe, ob Agent existiert
        if (-not ($script:Config.Agents -contains $Agent)) {
            Write-Error "Agent '$Agent' existiert nicht"
            return $false
        }

        # Prüfe, ob Fähigkeit bereits vorhanden ist
        if ($script:Capabilities.AgentCapabilities.$Agent -contains $Capability) {
            Write-Host "Fähigkeit '$Capability' ist bereits in Agent '$Agent' vorhanden"
            return $true
        }

        # Füge Fähigkeit hinzu
        $script:Capabilities.AgentCapabilities.$Agent += $Capability
        $script:Capabilities.LastUpdated = [DateTime]::Now.ToString("o")

        # Speichere aktualisierte Capabilities
        $script:Capabilities | ConvertTo-Json -Depth 10 | Set-Content -Path $script:CapabilitiesFile

        Write-Host "Fähigkeit '$Capability' erfolgreich zu Agent '$Agent' hinzugefügt"
        return $true
    } catch {
        Write-Error "Fehler beim Hinzufügen der Fähigkeit: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Erstellt einen neuen Agenten für eine Fähigkeit.
.DESCRIPTION
    Erstellt einen neuen Agenten speziell für eine bestimmte Fähigkeit.
.PARAMETER Capability
    Die Fähigkeit, für die der Agent erstellt werden soll.
#>
function New-AgentForCapability {
    param(
        [Parameter(Mandatory = $true)][string]$Capability
    )

    try {
        # Generiere Namen für den neuen Agenten
        $agentName = "MINTY" + $Capability.Replace(" ", "")

        # Prüfe, ob Agent bereits existiert
        if ($script:Config.Agents -contains $agentName) {
            Write-Warning "Agent '$agentName' existiert bereits"
            return Add-AgentCapability -Agent $agentName -Capability $Capability
        }

        # Füge Agent zur Konfiguration hinzu
        $script:Config.Agents += $agentName
        $script:Config.CommunicationPriorities[$agentName] = $script:Config.Agents.Count

        # Speichere aktualisierte Konfiguration
        $script:Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile

        # Initialisiere Agenten-Status
        $script:AgentStatus[$agentName] = @{
            "Status"       = "Inactive"
            "LastUpdate"   = [DateTime]::Now
            "Tasks"        = @()
            "Resources"    = @{}
            "Conflicts"    = @()
            "Capabilities" = @()
        }

        # Initialisiere Capabilities für den neuen Agenten
        $script:Capabilities.AgentCapabilities[$agentName] = @($Capability)
        $script:Capabilities.LastUpdated = [DateTime]::Now.ToString("o")

        # Speichere aktualisierte Capabilities
        $script:Capabilities | ConvertTo-Json -Depth 10 | Set-Content -Path $script:CapabilitiesFile

        # Aktualisiere Kommunikationspfade
        $script:CommunicationPaths[$agentName] = @{
            "Inputs"   = @()
            "Outputs"  = @()
            "Priority" = $script:Config.CommunicationPriorities[$agentName]
        }

        # Verbinde mit MINTYhive
        $script:CommunicationPaths["MINTYhive"].Outputs += $agentName
        $script:CommunicationPaths[$agentName].Inputs += "MINTYhive"

        # Verbinde mit MINTYcache und MINTYlog
        $script:CommunicationPaths["MINTYcache"].Outputs += $agentName
        $script:CommunicationPaths[$agentName].Inputs += "MINTYcache"

        $script:CommunicationPaths["MINTYlog"].Inputs += $agentName
        $script:CommunicationPaths[$agentName].Outputs += "MINTYlog"

        Write-Host "Neuer Agent '$agentName' für Fähigkeit '$Capability' erfolgreich erstellt"
        return $true
    } catch {
        Write-Error "Fehler beim Erstellen des neuen Agenten: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Entwickelt eine neue Fähigkeit im System.
.DESCRIPTION
    Koordiniert die Entwicklung einer neuen Fähigkeit, entweder durch Erweiterung eines bestehenden Agenten oder durch Erstellung eines neuen Agenten.
.PARAMETER Capability
    Die zu entwickelnde Fähigkeit.
.PARAMETER RequiredBy
    Die ID des Items, das die Fähigkeit benötigt.
.PARAMETER ForceNewAgent
    Gibt an, ob ein neuer Agent erstellt werden soll, auch wenn ein bestehender Agent geeignet wäre.
#>
function Develop-Capability {
    param(
        [Parameter(Mandatory = $true)][string]$Capability,
        [Parameter(Mandatory = $false)][string]$RequiredBy = "",
        [Parameter(Mandatory = $false)][bool]$ForceNewAgent = $false
    )

    try {
        # Prüfe, ob Fähigkeit bereits verfügbar ist
        $availabilityCheck = Test-CapabilityAvailability -Capability $Capability
        if ($availabilityCheck.Available) {
            Write-Host "Fähigkeit '$Capability' ist bereits verfügbar in Agent '$($availabilityCheck.Agent)'"
            return $true
        }

        # Wenn ForceNewAgent, erstelle direkt einen neuen Agenten
        if ($ForceNewAgent) {
            Write-Host "Erstelle neuen Agenten für Fähigkeit '$Capability' (erzwungen)"
            return New-AgentForCapability -Capability $Capability
        }

        # Finde besten Agenten für die Fähigkeit
        $bestAgent = Find-BestAgentForCapability -Capability $Capability

        # Entscheide, ob bestehender Agent erweitert oder neuer Agent erstellt werden soll
        if ($bestAgent.NewAgent -or $bestAgent.Score -lt 1) {
            Write-Host "Erstelle neuen Agenten für Fähigkeit '$Capability' (Score: $($bestAgent.Score), Grund: $($bestAgent.Reason))"
            return New-AgentForCapability -Capability $Capability
        } else {
            Write-Host "Erweitere Agent '$($bestAgent.Agent)' um Fähigkeit '$Capability' (Score: $($bestAgent.Score), Grund: $($bestAgent.Reason))"
            return Add-AgentCapability -Agent $bestAgent.Agent -Capability $Capability
        }
    } catch {
        Write-Error "Fehler bei der Entwicklung der Fähigkeit: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Aktualisiert eine bestehende Fähigkeit im System.
.DESCRIPTION
    Aktualisiert eine bestehende Fähigkeit auf die neueste Version.
.PARAMETER Capability
    Die zu aktualisierende Fähigkeit.
.PARAMETER Agent
    Der Agent, dessen Fähigkeit aktualisiert werden soll.
#>
function Update-Capability {
    param(
        [Parameter(Mandatory = $true)][string]$Capability,
        [Parameter(Mandatory = $false)][string]$Agent = ""
    )

    try {
        # Prüfe, ob Fähigkeit verfügbar ist
        $availabilityCheck = Test-CapabilityAvailability -Capability $Capability
        if (-not $availabilityCheck.Available) {
            Write-Warning "Fähigkeit '$Capability' ist nicht verfügbar und kann nicht aktualisiert werden"
            return $false
        }

        # Wenn kein Agent angegeben wurde, verwende den Agenten aus der Verfügbarkeitsprüfung
        if (-not $Agent -or $Agent -eq "") {
            $Agent = $availabilityCheck.Agent
        }

        # Wenn Agent "Global" ist, aktualisiere die globale Fähigkeit
        if ($Agent -eq "Global") {
            Write-Host "Aktualisiere globale Fähigkeit '$Capability'"
            # In einer realen Implementierung würde hier die Aktualisierung stattfinden
            return $true
        }

        # Prüfe, ob Agent existiert
        if (-not ($script:Config.Agents -contains $Agent)) {
            Write-Error "Agent '$Agent' existiert nicht"
            return $false
        }

        # Prüfe, ob Agent die Fähigkeit hat
        if (-not ($script:Capabilities.AgentCapabilities.$Agent -contains $Capability)) {
            Write-Error "Agent '$Agent' hat die Fähigkeit '$Capability' nicht"
            return $false
        }

        Write-Host "Aktualisiere Fähigkeit '$Capability' in Agent '$Agent'"
        # In einer realen Implementierung würde hier die Aktualisierung stattfinden

        # Aktualisiere Zeitstempel
        $script:Capabilities.LastUpdated = [DateTime]::Now.ToString("o")

        # Speichere aktualisierte Capabilities
        $script:Capabilities | ConvertTo-Json -Depth 10 | Set-Content -Path $script:CapabilitiesFile

        return $true
    } catch {
        Write-Error "Fehler bei der Aktualisierung der Fähigkeit: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Verarbeitet eine Anfrage zur Fähigkeitsprüfung von MINTYmanager.
.DESCRIPTION
    Verarbeitet eine Anfrage von MINTYmanager zur Prüfung der Verfügbarkeit einer Fähigkeit und koordiniert ggf. die Entwicklung.
.PARAMETER Capability
    Die zu prüfende Fähigkeit.
.PARAMETER RequiredBy
    Die ID des Items, das die Fähigkeit benötigt.
.PARAMETER DevelopIfMissing
    Gibt an, ob die Fähigkeit entwickelt werden soll, wenn sie nicht verfügbar ist.
.PARAMETER ForceNewAgent
    Gibt an, ob ein neuer Agent erstellt werden soll, auch wenn ein bestehender Agent geeignet wäre.
#>
function Process-CapabilityRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Capability,
        [Parameter(Mandatory = $false)][string]$RequiredBy = "",
        [Parameter(Mandatory = $false)][bool]$DevelopIfMissing = $true,
        [Parameter(Mandatory = $false)][bool]$ForceNewAgent = $false
    )

    try {
        Write-Host "Verarbeite Anfrage zur Prüfung der Fähigkeit '$Capability'"

        # Prüfe Verfügbarkeit
        $availabilityCheck = Test-CapabilityAvailability -Capability $Capability

        # Wenn verfügbar, prüfe auf Updates
        if ($availabilityCheck.Available) {
            Write-Host "Fähigkeit '$Capability' ist verfügbar in Agent '$($availabilityCheck.Agent)'"

            # Prüfe, ob Aktualisierung erforderlich ist
            if ($script:Config.CapabilityManagement.AutoUpdateCapabilities) {
                Update-Capability -Capability $Capability -Agent $availabilityCheck.Agent
            }

            return @{
                "Available" = $true
                "Agent"     = $availabilityCheck.Agent
                "Details"   = $availabilityCheck.Details
                "Developed" = $false
                "Updated"   = $script:Config.CapabilityManagement.AutoUpdateCapabilities
            }
        }

        # Wenn nicht verfügbar und Entwicklung gewünscht, entwickle die Fähigkeit
        if ($DevelopIfMissing -and $script:Config.CapabilityManagement.ProactiveDevelopment) {
            Write-Host "Fähigkeit '$Capability' ist nicht verfügbar, starte Entwicklung..."

            # Prüfe, ob Benutzerbestätigung erforderlich ist
            if ($script:Config.CapabilityManagement.UserConfirmationRequired) {
                # In einer realen Implementierung würde hier eine Benutzerabfrage stattfinden
                # Für diese Beispielimplementierung simulieren wir die Bestätigung
                $confirmed = $true

                if (-not $confirmed) {
                    Write-Host "Benutzer hat die Entwicklung abgelehnt"
                    return @{
                        "Available" = $false
                        "Agent"     = $null
                        "Details"   = "Entwicklung vom Benutzer abgelehnt"
                        "Developed" = $false
                        "Updated"   = $false
                    }
                }
            }

            # Entwickle die Fähigkeit
            $developmentResult = Develop-Capability -Capability $Capability -RequiredBy $RequiredBy -ForceNewAgent $ForceNewAgent

            if ($developmentResult) {
                # Prüfe erneut die Verfügbarkeit nach der Entwicklung
                $newAvailabilityCheck = Test-CapabilityAvailability -Capability $Capability

                return @{
                    "Available" = $newAvailabilityCheck.Available
                    "Agent"     = $newAvailabilityCheck.Agent
                    "Details"   = "Fähigkeit erfolgreich entwickelt"
                    "Developed" = $true
                    "Updated"   = $false
                }
            } else {
                return @{
                    "Available" = $false
                    "Agent"     = $null
                    "Details"   = "Entwicklung fehlgeschlagen"
                    "Developed" = $false
                    "Updated"   = $false
                }
            }
        }

        # Wenn nicht verfügbar und keine Entwicklung gewünscht, gib Fehlermeldung zurück
        return @{
            "Available" = $false
            "Agent"     = $null
            "Details"   = "Fähigkeit nicht verfügbar und Entwicklung nicht aktiviert"
            "Developed" = $false
            "Updated"   = $false
        }
    } catch {
        Write-Error "Fehler bei der Verarbeitung der Fähigkeitsanfrage: $_"
        return @{
            "Available" = $false
            "Agent"     = $null
            "Details"   = "Fehler bei der Verarbeitung: $_"
            "Developed" = $false
            "Updated"   = $false
        }
    }
}

# Exportiere Funktionen
Export-ModuleMember -Function Initialize-HiveManager, Invoke-AgentOrchestration, Orchestrate-SingleCycle, Update-AgentStatus, Optimize-CommunicationPaths, Resolve-AgentConflicts, Distribute-AgentTasks, Monitor-SystemState, Test-CapabilityAvailability, Find-BestAgentForCapability, Add-AgentCapability, New-AgentForCapability, Develop-Capability, Update-Capability, Process-CapabilityRequest
