# Beispielskript zur Demonstration der proaktiven Fähigkeitsentwicklung
# Dieses Skript zeigt, wie MINTYmanage mit MINTYhive kommuniziert, um Fähigkeiten zu prüfen und zu entwickeln

# Importiere benötigte Module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesPath = Split-Path -Parent $scriptPath
$hivePath = Join-Path $modulesPath "MINTYhive\src\HiveManager.ps1"
$managePath = Join-Path $modulesPath "MINTYmanager\src\ManagerManager.ps1"

# Importiere Module
. $hivePath
. $managePath

# Initialisiere Manager
Write-Host "Initialisiere MINTYhive und MINTYmanage..."
$hiveInitialized = Initialize-HiveManager
$manageInitialized = Initialize-ManagerManager

if (-not $hiveInitialized -or -not $manageInitialized) {
    Write-Error "Fehler bei der Initialisierung. Bitte prüfen Sie die Konfiguration."
    exit 1
}

Write-Host "Initialisierung erfolgreich." -ForegroundColor Green
Write-Host ""

# Beispiel 1: Prüfe eine vorhandene Fähigkeit
Write-Host "Beispiel 1: Prüfe eine vorhandene Fähigkeit (PowerShell)" -ForegroundColor Cyan
$capability = "PowerShell"
$availabilityCheck = Test-CapabilityAvailability -Capability $capability
Write-Host "Fähigkeit '$capability' verfügbar: $($availabilityCheck.Available)"
Write-Host "Agent: $($availabilityCheck.Agent)"
Write-Host "Details: $($availabilityCheck.Details)"
Write-Host ""

# Beispiel 2: Prüfe eine nicht vorhandene Fähigkeit und entwickle sie
Write-Host "Beispiel 2: Prüfe eine nicht vorhandene Fähigkeit (Docker) und entwickle sie" -ForegroundColor Cyan
$capability = "Docker"
$availabilityCheck = Test-CapabilityAvailability -Capability $capability
Write-Host "Fähigkeit '$capability' verfügbar: $($availabilityCheck.Available)"

if (-not $availabilityCheck.Available) {
    Write-Host "Entwickle Fähigkeit '$capability'..." -ForegroundColor Yellow
    $developmentResult = Develop-Capability -Capability $capability

    if ($developmentResult) {
        Write-Host "Fähigkeit '$capability' erfolgreich entwickelt." -ForegroundColor Green

        # Prüfe erneut die Verfügbarkeit
        $newAvailabilityCheck = Test-CapabilityAvailability -Capability $capability
        Write-Host "Fähigkeit '$capability' verfügbar: $($newAvailabilityCheck.Available)"
        Write-Host "Agent: $($newAvailabilityCheck.Agent)"
        Write-Host "Details: $($newAvailabilityCheck.Details)"
    } else {
        Write-Host "Fehler bei der Entwicklung der Fähigkeit '$capability'." -ForegroundColor Red
    }
}
Write-Host ""

# Beispiel 3: MINTYmanager prüft Fähigkeiten für ein Roadmap-Item
Write-Host "Beispiel 3: MINTYmanager prüft Fähigkeiten für ein Roadmap-Item" -ForegroundColor Cyan
$roadmapItem = @{
    "Title"                = "Docker Container Deployment Integration"
    "Description"          = "Implementierung einer Funktion zum Deployment von Containern über Docker"
    "Category"             = "Feature"
    "PlannedMonth"         = 1
    "RequiredCapabilities" = @("Docker", "ContainerManagement", "Deployment")
}

Write-Host "Neues Roadmap-Item: $($roadmapItem.Title)"
Write-Host "Benötigte Fähigkeiten: $($roadmapItem.RequiredCapabilities -join ', ')"

# Füge Item zur Roadmap hinzu (prüft automatisch Fähigkeiten)
$newItem = Add-RoadmapItem -Title $roadmapItem.Title -Description $roadmapItem.Description -Category $roadmapItem.Category -PlannedMonth $roadmapItem.PlannedMonth -RequiredCapabilities $roadmapItem.RequiredCapabilities

Write-Host "Roadmap-Item hinzugefügt mit ID: $($newItem.Id)" -ForegroundColor Green
Write-Host ""

# Beispiel 4: Prüfe eine Fähigkeit, die einen neuen Agenten erfordert
Write-Host "Beispiel 4: Prüfe eine Fähigkeit, die einen neuen Agenten erfordert" -ForegroundColor Cyan
$capability = "MachineLearning"
$availabilityCheck = Test-CapabilityAvailability -Capability $capability
Write-Host "Fähigkeit '$capability' verfügbar: $($availabilityCheck.Available)"

if (-not $availabilityCheck.Available) {
    Write-Host "Entwickle Fähigkeit '$capability' mit neuem Agenten..." -ForegroundColor Yellow
    $developmentResult = Develop-Capability -Capability $capability -ForceNewAgent $true

    if ($developmentResult) {
        Write-Host "Fähigkeit '$capability' erfolgreich entwickelt mit neuem Agenten." -ForegroundColor Green

        # Prüfe erneut die Verfügbarkeit
        $newAvailabilityCheck = Test-CapabilityAvailability -Capability $capability
        Write-Host "Fähigkeit '$capability' verfügbar: $($newAvailabilityCheck.Available)"
        Write-Host "Agent: $($newAvailabilityCheck.Agent)"
        Write-Host "Details: $($newAvailabilityCheck.Details)"
    } else {
        Write-Host "Fehler bei der Entwicklung der Fähigkeit '$capability'." -ForegroundColor Red
    }
}
Write-Host ""

# Beispiel 5: Verarbeite eine Anfrage zur Fähigkeitsprüfung von MINTYmanager
Write-Host "Beispiel 5: Verarbeite eine Anfrage zur Fähigkeitsprüfung von MINTYmanager" -ForegroundColor Cyan
$capability = "ContainerOrchestration"
Write-Host "MINTYmanage fragt Fähigkeit '$capability' an..."

$requestResult = Process-CapabilityRequest -Capability $capability -DevelopIfMissing $true
Write-Host "Anfrage verarbeitet:"
Write-Host "Verfügbar: $($requestResult.Available)"
Write-Host "Agent: $($requestResult.Agent)"
Write-Host "Details: $($requestResult.Details)"
Write-Host "Entwickelt: $($requestResult.Developed)"
Write-Host "Aktualisiert: $($requestResult.Updated)"
Write-Host ""

Write-Host "Demonstration abgeschlossen." -ForegroundColor Green
