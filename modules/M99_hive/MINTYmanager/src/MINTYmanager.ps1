# MINTYmanager Manager
# Beschreibung: Hauptkomponente des Management-Agents für die Verwaltung von Roadmap, Backlog und Task-Listen

# Importiere benötigte Module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path (Split-Path -Parent $scriptPath) "config"
$dataPath = Join-Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) "data"

# Globale Variablen
$script:ConfigFile = Join-Path $configPath "manager_config.json"
$script:RoadmapFile = Join-Path $dataPath "roadmap.json"
$script:BacklogFile = Join-Path $dataPath "backlog.json"
$script:TaskListFile = Join-Path $dataPath "tasklist.json"
$script:Config = $null
$script:Roadmap = @()
$script:Backlog = @()
$script:TaskList = @()
$script:CapabilityCache = @{}

<#
.SYNOPSIS
    Initialisiert den Manager Manager.
.DESCRIPTION
    Lädt die Konfiguration und initialisiert den Manager Manager.
#>
function Initialize-ManagerManager {
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
                "Roadmap"            = @{
                    "TimeframeMonths" = 12
                    "Categories"      = @("Feature", "Enhancement", "Bugfix", "Infrastructure")
                }
                "Backlog"            = @{
                    "PriorityLevels" = @("Critical", "High", "Medium", "Low")
                    "Categories"     = @("Feature", "Enhancement", "Bugfix", "Infrastructure")
                }
                "TaskList"           = @{
                    "StatusOptions" = @("Todo", "InProgress", "Review", "Done")
                    "Categories"    = @("Development", "Testing", "Documentation", "Deployment")
                }
                "CapabilityChecking" = @{
                    "AutoCheckEnabled"         = $true
                    "CheckFrequency"           = "Daily"
                    "ProactiveDevelopment"     = $true
                    "UserConfirmationRequired" = $true
                }
                "Interfaces"         = @{
                    "MINTYhive"       = $true
                    "AllAgents"       = $true
                    "MINTYlogger"     = $true
                    "ExternalSystems" = $false
                }
            }

            # Speichere Standardkonfiguration
            $script:Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile
        }

        # Lade Roadmap
        if (Test-Path $script:RoadmapFile) {
            $script:Roadmap = Get-Content -Path $script:RoadmapFile -Raw | ConvertFrom-Json
        } else {
            # Erstelle leere Roadmap
            $script:Roadmap = @()
            $script:Roadmap | ConvertTo-Json -Depth 10 | Set-Content -Path $script:RoadmapFile
        }

        # Lade Backlog
        if (Test-Path $script:BacklogFile) {
            $script:Backlog = Get-Content -Path $script:BacklogFile -Raw | ConvertFrom-Json
        } else {
            # Erstelle leeres Backlog
            $script:Backlog = @()
            $script:Backlog | ConvertTo-Json -Depth 10 | Set-Content -Path $script:BacklogFile
        }

        # Lade Task-Liste
        if (Test-Path $script:TaskListFile) {
            $script:TaskList = Get-Content -Path $script:TaskListFile -Raw | ConvertFrom-Json
        } else {
            # Erstelle leere Task-Liste
            $script:TaskList = @()
            $script:TaskList | ConvertTo-Json -Depth 10 | Set-Content -Path $script:TaskListFile
        }

        # Initialisiere Capability Cache
        $script:CapabilityCache = @{}

        Write-Host "Manager Manager initialisiert"
        return $true
    } catch {
        Write-Error "Fehler bei der Initialisierung des Manager Managers: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Ruft die aktuelle Roadmap ab.
.DESCRIPTION
    Gibt die aktuelle Roadmap zurück.
#>
function Get-Roadmap {
    return $script:Roadmap
}

<#
.SYNOPSIS
    Ruft das aktuelle Backlog ab.
.DESCRIPTION
    Gibt das aktuelle Backlog zurück.
#>
function Get-Backlog {
    return $script:Backlog
}

<#
.SYNOPSIS
    Ruft die aktuelle Task-Liste ab.
.DESCRIPTION
    Gibt die aktuelle Task-Liste zurück.
#>
function Get-TaskList {
    return $script:TaskList
}

<#
.SYNOPSIS
    Fügt ein neues Item zur Roadmap hinzu.
.DESCRIPTION
    Fügt ein neues Item zur Roadmap hinzu und prüft proaktiv die Verfügbarkeit benötigter Fähigkeiten.
.PARAMETER Title
    Der Titel des Items.
.PARAMETER Description
    Die Beschreibung des Items.
.PARAMETER Category
    Die Kategorie des Items.
.PARAMETER PlannedMonth
    Der geplante Monat für die Umsetzung.
.PARAMETER RequiredCapabilities
    Die für die Umsetzung benötigten Fähigkeiten.
#>
function Add-RoadmapItem {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][int]$PlannedMonth,
        [Parameter(Mandatory = $false)][string[]]$RequiredCapabilities = @()
    )

    try {
        # Erstelle neues Roadmap-Item
        $newItem = @{
            "Id"                   = [Guid]::NewGuid().ToString()
            "Title"                = $Title
            "Description"          = $Description
            "Category"             = $Category
            "PlannedMonth"         = $PlannedMonth
            "RequiredCapabilities" = $RequiredCapabilities
            "Status"               = "Planned"
            "CreatedAt"            = [DateTime]::Now.ToString("o")
            "UpdatedAt"            = [DateTime]::Now.ToString("o")
        }

        # Füge Item zur Roadmap hinzu
        $script:Roadmap += $newItem

        # Speichere Roadmap
        $script:Roadmap | ConvertTo-Json -Depth 10 | Set-Content -Path $script:RoadmapFile

        # Prüfe proaktiv die Verfügbarkeit benötigter Fähigkeiten
        if ($script:Config.CapabilityChecking.AutoCheckEnabled -and $RequiredCapabilities.Count -gt 0) {
            foreach ($capability in $RequiredCapabilities) {
                $available = Check-CapabilityAvailability -Capability $capability
                if (-not $available) {
                    Write-Host "Fähigkeit '$capability' ist nicht verfügbar. Starte proaktive Entwicklung..."
                    Request-CapabilityDevelopment -Capability $capability -RequiredBy $newItem.Id
                }
            }
        }

        return $newItem
    } catch {
        Write-Error "Fehler beim Hinzufügen eines Roadmap-Items: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Fügt ein neues Item zum Backlog hinzu.
.DESCRIPTION
    Fügt ein neues Item zum Backlog hinzu und prüft proaktiv die Verfügbarkeit benötigter Fähigkeiten.
.PARAMETER Title
    Der Titel des Items.
.PARAMETER Description
    Die Beschreibung des Items.
.PARAMETER Category
    Die Kategorie des Items.
.PARAMETER Priority
    Die Priorität des Items.
.PARAMETER RequiredCapabilities
    Die für die Umsetzung benötigten Fähigkeiten.
#>
function Add-BacklogItem {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][string]$Priority,
        [Parameter(Mandatory = $false)][string[]]$RequiredCapabilities = @()
    )

    try {
        # Erstelle neues Backlog-Item
        $newItem = @{
            "Id"                   = [Guid]::NewGuid().ToString()
            "Title"                = $Title
            "Description"          = $Description
            "Category"             = $Category
            "Priority"             = $Priority
            "RequiredCapabilities" = $RequiredCapabilities
            "Status"               = "New"
            "CreatedAt"            = [DateTime]::Now.ToString("o")
            "UpdatedAt"            = [DateTime]::Now.ToString("o")
        }

        # Füge Item zum Backlog hinzu
        $script:Backlog += $newItem

        # Speichere Backlog
        $script:Backlog | ConvertTo-Json -Depth 10 | Set-Content -Path $script:BacklogFile

        # Prüfe proaktiv die Verfügbarkeit benötigter Fähigkeiten
        if ($script:Config.CapabilityChecking.AutoCheckEnabled -and $RequiredCapabilities.Count -gt 0) {
            foreach ($capability in $RequiredCapabilities) {
                $available = Check-CapabilityAvailability -Capability $capability
                if (-not $available) {
                    Write-Host "Fähigkeit '$capability' ist nicht verfügbar. Starte proaktive Entwicklung..."
                    Request-CapabilityDevelopment -Capability $capability -RequiredBy $newItem.Id
                }
            }
        }

        return $newItem
    } catch {
        Write-Error "Fehler beim Hinzufügen eines Backlog-Items: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Fügt eine neue Aufgabe zur Task-Liste hinzu.
.DESCRIPTION
    Fügt eine neue Aufgabe zur Task-Liste hinzu und prüft proaktiv die Verfügbarkeit benötigter Fähigkeiten.
.PARAMETER Title
    Der Titel der Aufgabe.
.PARAMETER Description
    Die Beschreibung der Aufgabe.
.PARAMETER Category
    Die Kategorie der Aufgabe.
.PARAMETER AssignedTo
    Der Agent, dem die Aufgabe zugewiesen ist.
.PARAMETER RequiredCapabilities
    Die für die Umsetzung benötigten Fähigkeiten.
#>
function Add-TaskItem {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $false)][string]$AssignedTo = "",
        [Parameter(Mandatory = $false)][string[]]$RequiredCapabilities = @()
    )

    try {
        # Erstelle neue Aufgabe
        $newItem = @{
            "Id"                   = [Guid]::NewGuid().ToString()
            "Title"                = $Title
            "Description"          = $Description
            "Category"             = $Category
            "AssignedTo"           = $AssignedTo
            "RequiredCapabilities" = $RequiredCapabilities
            "Status"               = "Todo"
            "CreatedAt"            = [DateTime]::Now.ToString("o")
            "UpdatedAt"            = [DateTime]::Now.ToString("o")
        }

        # Füge Aufgabe zur Task-Liste hinzu
        $script:TaskList += $newItem

        # Speichere Task-Liste
        $script:TaskList | ConvertTo-Json -Depth 10 | Set-Content -Path $script:TaskListFile

        # Prüfe proaktiv die Verfügbarkeit benötigter Fähigkeiten
        if ($script:Config.CapabilityChecking.AutoCheckEnabled -and $RequiredCapabilities.Count -gt 0) {
            foreach ($capability in $RequiredCapabilities) {
                $available = Check-CapabilityAvailability -Capability $capability
                if (-not $available) {
                    Write-Host "Fähigkeit '$capability' ist nicht verfügbar. Starte proaktive Entwicklung..."
                    Request-CapabilityDevelopment -Capability $capability -RequiredBy $newItem.Id
                }
            }
        }

        return $newItem
    } catch {
        Write-Error "Fehler beim Hinzufügen einer Aufgabe: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Aktualisiert den Status eines Items.
.DESCRIPTION
    Aktualisiert den Status eines Items in Roadmap, Backlog oder Task-Liste.
.PARAMETER Id
    Die ID des Items.
.PARAMETER Status
    Der neue Status des Items.
.PARAMETER ItemType
    Der Typ des Items (Roadmap, Backlog oder TaskList).
#>
function Update-ItemStatus {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Status,
        [Parameter(Mandatory = $true)][ValidateSet("Roadmap", "Backlog", "TaskList")][string]$ItemType
    )

    try {
        switch ($ItemType) {
            "Roadmap" {
                $itemIndex = $script:Roadmap.IndexOf(($script:Roadmap | Where-Object { $_.Id -eq $Id }))
                if ($itemIndex -ge 0) {
                    $script:Roadmap[$itemIndex].Status = $Status
                    $script:Roadmap[$itemIndex].UpdatedAt = [DateTime]::Now.ToString("o")
                    $script:Roadmap | ConvertTo-Json -Depth 10 | Set-Content -Path $script:RoadmapFile
                    return $true
                }
            }
            "Backlog" {
                $itemIndex = $script:Backlog.IndexOf(($script:Backlog | Where-Object { $_.Id -eq $Id }))
                if ($itemIndex -ge 0) {
                    $script:Backlog[$itemIndex].Status = $Status
                    $script:Backlog[$itemIndex].UpdatedAt = [DateTime]::Now.ToString("o")
                    $script:Backlog | ConvertTo-Json -Depth 10 | Set-Content -Path $script:BacklogFile
                    return $true
                }
            }
            "TaskList" {
                $itemIndex = $script:TaskList.IndexOf(($script:TaskList | Where-Object { $_.Id -eq $Id }))
                if ($itemIndex -ge 0) {
                    $script:TaskList[$itemIndex].Status = $Status
                    $script:TaskList[$itemIndex].UpdatedAt = [DateTime]::Now.ToString("o")
                    $script:TaskList | ConvertTo-Json -Depth 10 | Set-Content -Path $script:TaskListFile
                    return $true
                }
            }
        }

        Write-Warning "Item mit ID '$Id' nicht gefunden in $ItemType"
        return $false
    } catch {
        Write-Error "Fehler beim Aktualisieren des Item-Status: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Prüft die Verfügbarkeit einer Fähigkeit im System.
.DESCRIPTION
    Prüft, ob eine bestimmte Fähigkeit im System verfügbar ist, indem MINTYhive abgefragt wird.
.PARAMETER Capability
    Die zu prüfende Fähigkeit.
#>
function Check-CapabilityAvailability {
    param(
        [Parameter(Mandatory = $true)][string]$Capability
    )

    try {
        # Prüfe Cache
        if ($script:CapabilityCache.ContainsKey($Capability)) {
            $cacheEntry = $script:CapabilityCache[$Capability]
            $cacheAge = [DateTime]::Now - $cacheEntry.Timestamp

            # Wenn Cache-Eintrag nicht älter als 1 Tag ist, verwende ihn
            if ($cacheAge.TotalDays -lt 1) {
                return $cacheEntry.Available
            }
        }

        # Hier würde in einer realen Implementierung eine Kommunikation mit MINTYhive stattfinden
        # Für diese Beispielimplementierung simulieren wir die Verfügbarkeit

        # Simuliere Verfügbarkeit basierend auf Capability-Name
        $available = $false

        # Simuliere einige Standard-Fähigkeiten als verfügbar
        $standardCapabilities = @(
            "PowerShell", "Scripting", "FileManagement", "LogManagement",
            "ConfigurationManagement", "ErrorHandling", "Logging", "Monitoring"
        )

        if ($standardCapabilities -contains $Capability) {
            $available = $true
        }

        # Aktualisiere Cache
        $script:CapabilityCache[$Capability] = @{
            "Available" = $available
            "Timestamp" = [DateTime]::Now
        }

        return $available
    } catch {
        Write-Error "Fehler bei der Prüfung der Fähigkeitsverfügbarkeit: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Fordert die Entwicklung einer neuen Fähigkeit an.
.DESCRIPTION
    Fordert die Entwicklung einer neuen Fähigkeit an, indem geprüft wird, ob sie in das Portfolio eines bestehenden Agenten passt.
.PARAMETER Capability
    Die zu entwickelnde Fähigkeit.
.PARAMETER RequiredBy
    Die ID des Items, das die Fähigkeit benötigt.
#>
function Request-CapabilityDevelopment {
    param(
        [Parameter(Mandatory = $true)][string]$Capability,
        [Parameter(Mandatory = $false)][string]$RequiredBy = ""
    )

    try {
        Write-Host "Fordere Entwicklung der Fähigkeit '$Capability' an..."

        # Prüfe, ob die Fähigkeit in das Portfolio eines bestehenden Agenten passt
        $existingAgent = Find-SuitableAgentForCapability -Capability $Capability

        if ($existingAgent) {
            Write-Host "Fähigkeit '$Capability' passt in das Portfolio des Agenten '$existingAgent'"

            if ($script:Config.CapabilityChecking.UserConfirmationRequired) {
                # In einer realen Implementierung würde hier eine Benutzerabfrage stattfinden
                # Für diese Beispielimplementierung simulieren wir die Bestätigung
                $confirmed = $true

                if ($confirmed) {
                    return Coordinate-AgentExtension -Agent $existingAgent -Capability $Capability -RequiredBy $RequiredBy
                } else {
                    Write-Host "Benutzer hat die Erweiterung des Agenten abgelehnt"
                    return $false
                }
            } else {
                return Coordinate-AgentExtension -Agent $existingAgent -Capability $Capability -RequiredBy $RequiredBy
            }
        } else {
            Write-Host "Fähigkeit '$Capability' passt in kein bestehendes Agentenprofil, neuer Agent erforderlich"

            if ($script:Config.CapabilityChecking.UserConfirmationRequired) {
                # In einer realen Implementierung würde hier eine Benutzerabfrage stattfinden
                # Für diese Beispielimplementierung simulieren wir die Bestätigung
                $confirmed = $true

                if ($confirmed) {
                    return Coordinate-NewAgentDevelopment -Capability $Capability -RequiredBy $RequiredBy
                } else {
                    Write-Host "Benutzer hat die Entwicklung eines neuen Agenten abgelehnt"
                    return $false
                }
            } else {
                return Coordinate-NewAgentDevelopment -Capability $Capability -RequiredBy $RequiredBy
            }
        }
    } catch {
        Write-Error "Fehler bei der Anforderung der Fähigkeitsentwicklung: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Findet einen geeigneten Agenten für eine Fähigkeit.
.DESCRIPTION
    Prüft, welcher bestehende Agent am besten für die Erweiterung um eine neue Fähigkeit geeignet ist.
.PARAMETER Capability
    Die zu entwickelnde Fähigkeit.
#>
function Find-SuitableAgentForCapability {
    param(
        [Parameter(Mandatory = $true)][string]$Capability
    )

    try {
        # Hier würde in einer realen Implementierung eine Analyse der Agenten und ihrer Fähigkeiten stattfinden
        # Für diese Beispielimplementierung simulieren wir die Zuordnung

        # Simuliere Zuordnung basierend auf Capability-Name
        switch -Wildcard ($Capability) {
            "*Code*" { return "MINTYcoder" }
            "*Test*" { return "MINTYtester" }
            "*Archiv*" { return "MINTYarchivar" }
            "*Cache*" { return "MINTYcache" }
            "*Log*" { return "MINTYlogger" }
            "*Clean*" { return "MINTYcleaner" }
            "*Update*" { return "MINTYupdater" }
            "*Version*" { return "MINTYgit" }
            "*Architect*" { return "MINTYarchitect" }
            "*Docker*" { return "MINTYcoder" }  # Docker-Fähigkeiten passen zum Code-Agenten
            "*Container*" { return "MINTYcoder" }  # Container-Fähigkeiten passen zum Code-Agenten
            "*Deployment*" { return "MINTYcoder" }  # Deployment-Fähigkeiten passen zum Code-Agenten
            default { return $null }  # Kein passender Agent gefunden
        }
    } catch {
        Write-Error "Fehler bei der Suche nach einem geeigneten Agenten: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Koordiniert die Erweiterung eines bestehenden Agenten.
.DESCRIPTION
    Koordiniert die Erweiterung eines bestehenden Agenten um eine neue Fähigkeit.
.PARAMETER Agent
    Der zu erweiternde Agent.
.PARAMETER Capability
    Die zu entwickelnde Fähigkeit.
.PARAMETER RequiredBy
    Die ID des Items, das die Fähigkeit benötigt.
#>
function Coordinate-AgentExtension {
    param(
        [Parameter(Mandatory = $true)][string]$Agent,
        [Parameter(Mandatory = $true)][string]$Capability,
        [Parameter(Mandatory = $false)][string]$RequiredBy = ""
    )

    try {
        Write-Host "Koordiniere Erweiterung des Agenten '$Agent' um die Fähigkeit '$Capability'..."

        # Hier würde in einer realen Implementierung die Koordination mit MINTYhive stattfinden
        # Für diese Beispielimplementierung simulieren wir die Erweiterung

        # Erstelle Aufgabe für die Erweiterung
        $taskTitle = "Erweitere $Agent um $Capability"
        $taskDescription = "Erweitere den Agenten $Agent um die Fähigkeit $Capability"
        if ($RequiredBy) {
            $taskDescription += " (benötigt von Item $RequiredBy)"
        }

        Add-TaskItem -Title $taskTitle -Description $taskDescription -Category "Development" -AssignedTo "MINTYhive" -RequiredCapabilities @()

        # Aktualisiere Cache
        $script:CapabilityCache[$Capability] = @{
            "Available" = $true  # Markiere als verfügbar, da die Entwicklung eingeleitet wurde
            "Timestamp" = [DateTime]::Now
        }

        return $true
    } catch {
        Write-Error "Fehler bei der Koordination der Agentenerweiterung: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Koordiniert die Entwicklung eines neuen Agenten.
.DESCRIPTION
    Koordiniert die Entwicklung eines neuen Agenten für eine neue Fähigkeit.
.PARAMETER Capability
    Die zu entwickelnde Fähigkeit.
.PARAMETER RequiredBy
    Die ID des Items, das die Fähigkeit benötigt.
#>
function Coordinate-NewAgentDevelopment {
    param(
        [Parameter(Mandatory = $true)][string]$Capability,
        [Parameter(Mandatory = $false)][string]$RequiredBy = ""
    )

    try {
        Write-Host "Koordiniere Entwicklung eines neuen Agenten für die Fähigkeit '$Capability'..."

        # Hier würde in einer realen Implementierung die Koordination mit MINTYhive stattfinden
        # Für diese Beispielimplementierung simulieren wir die Entwicklung

        # Generiere Namen für den neuen Agenten
        $newAgentName = "MINTY" + $Capability.Replace(" ", "")

        # Erstelle Aufgabe für die Entwicklung
        $taskTitle = "Entwickle neuen Agenten $newAgentName"
        $taskDescription = "Entwickle einen neuen Agenten $newAgentName für die Fähigkeit $Capability"
        if ($RequiredBy) {
            $taskDescription += " (benötigt von Item $RequiredBy)"
        }

        Add-TaskItem -Title $taskTitle -Description $taskDescription -Category "Development" -AssignedTo "MINTYhive" -RequiredCapabilities @()

        # Aktualisiere Cache
        $script:CapabilityCache[$Capability] = @{
            "Available" = $true  # Markiere als verfügbar, da die Entwicklung eingeleitet wurde
            "Timestamp" = [DateTime]::Now
        }

        return $true
    } catch {
        Write-Error "Fehler bei der Koordination der Agentenentwicklung: $_"
        return $false
    }
}

# Exportiere Funktionen
Export-ModuleMember -Function Initialize-ManagerManager, Get-Roadmap, Get-Backlog, Get-TaskList, Add-RoadmapItem, Add-BacklogItem, Add-TaskItem, Update-ItemStatus, Check-CapabilityAvailability, Request-CapabilityDevelopment, Coordinate-AgentExtension, Coordinate-NewAgentDevelopment
