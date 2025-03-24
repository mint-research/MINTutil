# MINTYgit
# Beschreibung: Hauptkomponente des Versionierungsagenten für Versionskontrolle, Branching und Merging

# Pfade
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$configPath = Join-Path $modulePath "config"
$dataPath = Join-Path $modulePath "data"

# Importiere Module
$versioningManagerPath = Join-Path $scriptPath "VersioningManager.ps1"
$commitManagerPath = Join-Path $scriptPath "CommitManager.ps1"
$vsCodeIntegrationPath = Join-Path $scriptPath "VSCodeIntegration.ps1"
$gitCommitStrategyPath = Join-Path $scriptPath "GitCommitStrategy.ps1"
$vsCodeGitCheckerPath = Join-Path $scriptPath "VSCodeGitChecker.ps1"

if (Test-Path $versioningManagerPath) {
    . $versioningManagerPath
}
if (Test-Path $commitManagerPath) {
    . $commitManagerPath
}
if (Test-Path $vsCodeIntegrationPath) {
    . $vsCodeIntegrationPath
}
if (Test-Path $gitCommitStrategyPath) {
    . $gitCommitStrategyPath
}
if (Test-Path $vsCodeGitCheckerPath) {
    . $vsCodeGitCheckerPath
}

# Globale Variablen
$script:ConfigFile = Join-Path $configPath "git_config.json"
$script:Config = $null
$script:GitManager = $null
$script:CommitManager = $null
$script:BranchManager = $null
$script:MergeManager = $null
$script:HistoryAnalyzer = $null
$script:VSCodeIntegration = $null

<#
.SYNOPSIS
    Initialisiert den Versionierungsagenten.
.DESCRIPTION
    Lädt die Konfiguration und initialisiert alle Komponenten des Versionierungsagenten.
#>
function Initialize-VersionControl {
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
                "RepositorySettings"  = @{
                    "DefaultBranch" = "main"
                    "RemoteUrl"     = ""
                    "LocalPath"     = ""
                    "AutoCommit"    = $true
                    "AutoPush"      = $false
                }
                "BranchSettings"      = @{
                    "NamingConvention"      = "feature/{name}"
                    "RequireDescription"    = $true
                    "RequireIssueReference" = $true
                }
                "CommitSettings"      = @{
                    "MessageTemplate"     = "[{type}] {message}"
                    "CommitTypes"         = @("feat", "fix", "docs", "style", "refactor", "test", "chore")
                    "AutoCommitInterval"  = "15m"
                    "MinChangesForCommit" = 3
                    "GroupSimilarChanges" = $true
                    "IncludeFileList"     = $true
                    "MaxFilesInMessage"   = 5
                }
                "MergeSettings"       = @{
                    "RequireReview"        = $true
                    "AutoResolveConflicts" = $false
                    "PreferSource"         = $false
                    "PreferTarget"         = $false
                }
                "HistorySettings"     = @{
                    "MaxHistoryDepth"       = 100
                    "IncludeCommitMessages" = $true
                    "IncludeFileChanges"    = $true
                    "IncludeAuthors"        = $true
                }
                "VSCodeSettings"      = @{
                    "EnableExtension"       = $true
                    "CommitOnSave"          = $true
                    "ShowNotifications"     = $true
                    "StatusBarIntegration"  = $true
                    "AutoCommitDelay"       = "30s"
                    "SuggestCommitMessages" = $true
                }
                "IntegrationSettings" = @{
                    "EnableHiveIntegration"    = $true
                    "EnableLoggerIntegration"  = $true
                    "EnableManagerIntegration" = $true
                    "EnableCoderIntegration"   = $true
                    "EnableTesterIntegration"  = $true
                    "HiveUpdateInterval"       = 60
                }
            }

            # Speichere Standardkonfiguration
            $script:Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile
        }

        # Initialisiere Komponenten
        if (Get-Command "Initialize-VersioningManager" -ErrorAction SilentlyContinue) {
            Initialize-VersioningManager
        }

        if (Get-Command "Initialize-CommitManager" -ErrorAction SilentlyContinue) {
            Initialize-CommitManager
        }

        if (Get-Command "Initialize-VSCodeIntegration" -ErrorAction SilentlyContinue) {
            Initialize-VSCodeIntegration
        }

        if (Get-Command "Initialize-GitCommitStrategy" -ErrorAction SilentlyContinue) {
            Initialize-GitCommitStrategy
        }

        if (Get-Command "Initialize-VSCodeGitChecker" -ErrorAction SilentlyContinue) {
            Initialize-VSCodeGitChecker -Silent
        }

        $script:GitManager = New-Object -TypeName PSObject
        $script:BranchManager = New-Object -TypeName PSObject
        $script:MergeManager = New-Object -TypeName PSObject
        $script:HistoryAnalyzer = New-Object -TypeName PSObject

        Write-Host "Versionierungsagent initialisiert"
        return $true
    } catch {
        Write-Error "Fehler bei der Initialisierung des Versionierungsagenten: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Erstellt einen neuen Branch.
.DESCRIPTION
    Erstellt einen neuen Branch mit dem angegebenen Namen.
.PARAMETER Name
    Der Name des neuen Branches.
.PARAMETER Description
    Die Beschreibung des neuen Branches.
.PARAMETER IssueReference
    Die Referenz zu einem Issue oder einer Aufgabe.
#>
function New-Branch {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $false)][string]$Description = "",
        [Parameter(Mandatory = $false)][string]$IssueReference = ""
    )

    try {
        # Überprüfe, ob der Branch-Name der Namenskonvention entspricht
        $namingConvention = $script:Config.BranchSettings.NamingConvention
        $expectedPattern = $namingConvention -replace "{name}", ".*"

        if ($Name -notmatch $expectedPattern) {
            $suggestedName = $namingConvention -replace "{name}", $Name
            Write-Warning "Der Branch-Name entspricht nicht der Namenskonvention. Vorschlag: $suggestedName"
            $Name = $suggestedName
        }

        # Überprüfe, ob eine Beschreibung erforderlich ist
        if ($script:Config.BranchSettings.RequireDescription -and [string]::IsNullOrWhiteSpace($Description)) {
            throw "Eine Beschreibung ist für neue Branches erforderlich."
        }

        # Überprüfe, ob eine Issue-Referenz erforderlich ist
        if ($script:Config.BranchSettings.RequireIssueReference -and [string]::IsNullOrWhiteSpace($IssueReference)) {
            throw "Eine Issue-Referenz ist für neue Branches erforderlich."
        }

        # Führe Git-Befehl aus
        git checkout -b $Name
        if (-not $?) {
            throw "Fehler beim Erstellen des Branches."
        }

        # Erstelle Commit mit Beschreibung und Issue-Referenz, falls vorhanden
        if (-not [string]::IsNullOrWhiteSpace($Description) -or -not [string]::IsNullOrWhiteSpace($IssueReference)) {
            $message = ""
            if (-not [string]::IsNullOrWhiteSpace($Description)) {
                $message += $Description
            }
            if (-not [string]::IsNullOrWhiteSpace($IssueReference)) {
                if (-not [string]::IsNullOrWhiteSpace($message)) {
                    $message += " "
                }
                $message += "($IssueReference)"
            }

            # Erstelle leere Commit-Nachricht
            git commit --allow-empty -m "[chore] Branch erstellt: $message"
        }

        Write-Host "Branch $Name erstellt"
        return $true
    } catch {
        Write-Error "Fehler beim Erstellen des Branches: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Wechselt zu einem Branch.
.DESCRIPTION
    Wechselt zu dem angegebenen Branch.
.PARAMETER Name
    Der Name des Branches, zu dem gewechselt werden soll.
#>
function Switch-Branch {
    param(
        [Parameter(Mandatory = $true)][string]$Name
    )

    try {
        # Führe Git-Befehl aus
        git checkout $Name
        if (-not $?) {
            throw "Fehler beim Wechseln zum Branch."
        }

        Write-Host "Zu Branch $Name gewechselt"
        return $true
    } catch {
        Write-Error "Fehler beim Wechseln zum Branch: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Führt Branches zusammen.
.DESCRIPTION
    Führt den Quell-Branch in den Ziel-Branch zusammen.
.PARAMETER Source
    Der Name des Quell-Branches.
.PARAMETER Target
    Der Name des Ziel-Branches.
.PARAMETER Message
    Die Commit-Nachricht für den Merge.
#>
function Merge-Branch {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $false)][string]$Message = "Merge $Source into $Target"
    )

    try {
        # Speichere aktuellen Branch
        $currentBranch = git rev-parse --abbrev-ref HEAD
        if (-not $?) {
            throw "Fehler beim Ermitteln des aktuellen Branches."
        }

        # Wechsle zum Ziel-Branch
        git checkout $Target
        if (-not $?) {
            throw "Fehler beim Wechseln zum Ziel-Branch."
        }

        # Führe Merge durch
        git merge --no-ff $Source -m $Message
        if (-not $?) {
            # Überprüfe, ob Konflikte vorliegen
            $conflicts = git diff --name-only --diff-filter=U
            if ($conflicts) {
                Write-Warning "Konflikte beim Merge gefunden. Bitte löse die Konflikte in folgenden Dateien:"
                $conflicts | ForEach-Object { Write-Warning "- $_" }

                # Überprüfe, ob automatische Konfliktlösung aktiviert ist
                if ($script:Config.MergeSettings.AutoResolveConflicts) {
                    Write-Host "Versuche, Konflikte automatisch zu lösen..."

                    # Strategie für Konfliktlösung
                    if ($script:Config.MergeSettings.PreferSource) {
                        git checkout --theirs .
                        git add .
                        git commit -m "$Message (Konflikte automatisch gelöst, Quell-Änderungen bevorzugt)"
                        Write-Host "Konflikte automatisch gelöst (Quell-Änderungen bevorzugt)"
                    } elseif ($script:Config.MergeSettings.PreferTarget) {
                        git checkout --ours .
                        git add .
                        git commit -m "$Message (Konflikte automatisch gelöst, Ziel-Änderungen bevorzugt)"
                        Write-Host "Konflikte automatisch gelöst (Ziel-Änderungen bevorzugt)"
                    } else {
                        # Breche Merge ab, wenn keine Strategie definiert ist
                        git merge --abort
                        throw "Automatische Konfliktlösung ist aktiviert, aber keine Strategie definiert."
                    }
                } else {
                    # Breche Merge ab
                    git merge --abort
                    throw "Konflikte beim Merge gefunden. Merge abgebrochen."
                }
            } else {
                throw "Fehler beim Merge."
            }
        }

        # Wechsle zurück zum ursprünglichen Branch
        git checkout $currentBranch

        Write-Host "Branch $Source in $Target zusammengeführt"
        return $true
    } catch {
        Write-Error "Fehler beim Zusammenführen der Branches: $_"

        # Versuche, zum ursprünglichen Branch zurückzukehren
        try {
            git checkout $currentBranch -ErrorAction SilentlyContinue
        } catch {
            # Ignoriere Fehler
        }

        return $false
    }
}

<#
.SYNOPSIS
    Analysiert die Entwicklungshistorie.
.DESCRIPTION
    Analysiert die Entwicklungshistorie und gibt Informationen zurück.
.PARAMETER Depth
    Die Tiefe der Analyse.
.PARAMETER IncludeCommitMessages
    Gibt an, ob Commit-Nachrichten einbezogen werden sollen.
.PARAMETER IncludeFileChanges
    Gibt an, ob Dateiänderungen einbezogen werden sollen.
.PARAMETER IncludeAuthors
    Gibt an, ob Autoren einbezogen werden sollen.
#>
function Get-History {
    param(
        [Parameter(Mandatory = $false)][int]$Depth = 10,
        [Parameter(Mandatory = $false)][bool]$IncludeCommitMessages = $true,
        [Parameter(Mandatory = $false)][bool]$IncludeFileChanges = $true,
        [Parameter(Mandatory = $false)][bool]$IncludeAuthors = $true
    )

    try {
        # Erstelle Format-String für Git-Log
        $format = ""
        if ($IncludeCommitMessages) {
            $format += "%s%n"
        }
        if ($IncludeAuthors) {
            $format += "Author: %an <%ae>%n"
        }
        $format += "Date: %ad%n"
        if ($IncludeFileChanges) {
            $format += "Files:%n"
        }

        # Führe Git-Log aus
        $logCommand = "git log -n $Depth --pretty=format:`"$format`""
        if ($IncludeFileChanges) {
            $logCommand += " --name-status"
        }

        $log = Invoke-Expression $logCommand

        # Formatiere Ausgabe
        $history = $log -join "`n"

        Write-Host "Entwicklungshistorie analysiert"
        return $history
    } catch {
        Write-Error "Fehler bei der Analyse der Entwicklungshistorie: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Konfiguriert die automatische Commit-Strategie.
.DESCRIPTION
    Konfiguriert die Parameter für die automatische Commit-Strategie.
.PARAMETER Interval
    Das Intervall für automatische Commits (z.B. "15m", "1h").
.PARAMETER MinChanges
    Die minimale Anzahl an Änderungen für einen automatischen Commit.
.PARAMETER GroupChanges
    Gibt an, ob ähnliche Änderungen gruppiert werden sollen.
.PARAMETER CommitOnSave
    Gibt an, ob bei jedem Speichern ein Commit erstellt werden soll.
#>
function Set-AutoCommitStrategy {
    param(
        [Parameter(Mandatory = $false)][string]$Interval,
        [Parameter(Mandatory = $false)][int]$MinChanges,
        [Parameter(Mandatory = $false)][bool]$GroupChanges,
        [Parameter(Mandatory = $false)][bool]$CommitOnSave
    )

    # Rufe die Funktion im CommitManager auf, falls verfügbar
    if (Get-Command "Set-AutoCommitStrategy" -ErrorAction SilentlyContinue) {
        return Set-AutoCommitStrategy -Interval $Interval -MinChanges $MinChanges -GroupChanges $GroupChanges -CommitOnSave $CommitOnSave
    } else {
        Write-Error "CommitManager ist nicht verfügbar."
        return $false
    }
}

<#
.SYNOPSIS
    Aktiviert die VS Code-Integration.
.DESCRIPTION
    Aktiviert die Integration von MINTYgit in VS Code.
#>
function Enable-VSCodeIntegration {
    # Rufe die Funktion im VSCodeIntegration-Modul auf, falls verfügbar
    if (Get-Command "Enable-VSCodeIntegration" -ErrorAction SilentlyContinue) {
        return Enable-VSCodeIntegration
    } else {
        Write-Error "VSCodeIntegration ist nicht verfügbar."
        return $false
    }
}

<#
.SYNOPSIS
    Führt einen automatischen Commit durch.
.DESCRIPTION
    Überprüft, ob Änderungen vorliegen und führt einen automatischen Commit durch.
.PARAMETER Path
    Der Pfad zum Repository.
#>
function Invoke-AutoCommit {
    param(
        [Parameter(Mandatory = $false)][string]$Path = $PWD
    )

    # Rufe die Funktion im CommitManager auf, falls verfügbar
    if (Get-Command "Invoke-AutoCommit" -ErrorAction SilentlyContinue) {
        return Invoke-AutoCommit -Path $Path
    } else {
        Write-Error "CommitManager ist nicht verfügbar."
        return $false
    }
}

# Exportiere Funktionen
Export-ModuleMember -Function Initialize-VersionControl, New-Branch, Switch-Branch, Merge-Branch, Get-History, Set-AutoCommitStrategy, Enable-VSCodeIntegration, Invoke-AutoCommit, New-GitSnapshot, New-GitBranch, New-ChangeDoc, Test-CommitRules, Merge-GitBranch, New-GitCommit, New-AutoCommit, Test-VSCodeState, Test-GitExtension, Test-GitConfiguration, Test-Repository, Test-GitAuthentication, Test-GitEnvironment
