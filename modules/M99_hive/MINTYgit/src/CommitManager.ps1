# MINTYgit CommitManager
# Beschreibung: Komponente für die Verwaltung von automatischen Commits und Commit-Nachrichten

# Importiere benötigte Module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$configPath = Join-Path $modulePath "config"

# Globale Variablen
$script:ConfigFile = Join-Path $configPath "git_config.json"
$script:Config = $null
$script:LastCommitTime = $null
$script:PendingChanges = @()
$script:CommitTimer = $null
$script:IsInitialized = $false

<#
.SYNOPSIS
    Initialisiert den CommitManager.
.DESCRIPTION
    Lädt die Konfiguration und initialisiert den CommitManager.
#>
function Initialize-CommitManager {
    try {
        # Lade Konfiguration
        if (Test-Path $script:ConfigFile) {
            $script:Config = Get-Content -Path $script:ConfigFile -Raw | ConvertFrom-Json
        } else {
            Write-Error "Konfigurationsdatei nicht gefunden: $script:ConfigFile"
            return $false
        }

        # Setze Startwerte
        $script:LastCommitTime = Get-Date
        $script:PendingChanges = @()
        $script:IsInitialized = $true

        # Starte Timer für automatische Commits, falls aktiviert
        if ($script:Config.RepositorySettings.AutoCommit) {
            Start-AutoCommitTimer
        }

        Write-Host "CommitManager initialisiert"
        return $true
    } catch {
        Write-Error "Fehler bei der Initialisierung des CommitManagers: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Startet den Timer für automatische Commits.
.DESCRIPTION
    Startet einen Timer, der in regelmäßigen Abständen automatische Commits auslöst.
#>
function Start-AutoCommitTimer {
    try {
        # Stoppe vorhandenen Timer, falls vorhanden
        if ($script:CommitTimer -ne $null) {
            Unregister-Event -SourceIdentifier "AutoCommitTimer" -ErrorAction SilentlyContinue
            $script:CommitTimer = $null
        }

        # Parse Intervall aus Konfiguration
        $intervalString = $script:Config.CommitSettings.AutoCommitInterval
        $intervalValue = [int]($intervalString -replace "[^0-9]", "")
        $intervalUnit = $intervalString -replace "[0-9]", ""

        # Konvertiere in Sekunden
        $intervalSeconds = switch ($intervalUnit) {
            "s" { $intervalValue }
            "m" { $intervalValue * 60 }
            "h" { $intervalValue * 3600 }
            default { 900 } # 15 Minuten als Standard
        }

        # Erstelle Timer
        $timer = New-Object System.Timers.Timer
        $timer.Interval = $intervalSeconds * 1000 # Millisekunden
        $timer.AutoReset = $true
        $timer.Enabled = $true

        # Registriere Event
        Register-ObjectEvent -InputObject $timer -EventName Elapsed -SourceIdentifier "AutoCommitTimer" -Action {
            Invoke-AutoCommit
        } | Out-Null

        $script:CommitTimer = $timer
        Write-Host "AutoCommitTimer gestartet mit Intervall: $intervalString"
        return $true
    } catch {
        Write-Error "Fehler beim Starten des AutoCommitTimers: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Stoppt den Timer für automatische Commits.
.DESCRIPTION
    Stoppt den Timer für automatische Commits.
#>
function Stop-AutoCommitTimer {
    try {
        if ($script:CommitTimer -ne $null) {
            Unregister-Event -SourceIdentifier "AutoCommitTimer" -ErrorAction SilentlyContinue
            $script:CommitTimer.Dispose()
            $script:CommitTimer = $null
            Write-Host "AutoCommitTimer gestoppt"
        }
        return $true
    } catch {
        Write-Error "Fehler beim Stoppen des AutoCommitTimers: $_"
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

    try {
        # Überprüfe, ob das Verzeichnis ein Git-Repository ist
        if (-not (Test-Path (Join-Path $Path ".git"))) {
            Write-Error "Das angegebene Verzeichnis ist kein Git-Repository: $Path"
            return $false
        }

        # Wechsle in das Verzeichnis
        Push-Location $Path

        try {
            # Überprüfe, ob Änderungen vorliegen
            $status = git status --porcelain
            if (-not $status) {
                Write-Host "Keine Änderungen für Commit vorhanden"
                return $true
            }

            # Analysiere Änderungen
            $changes = @{
                "Added"     = @()
                "Modified"  = @()
                "Deleted"   = @()
                "Renamed"   = @()
                "Untracked" = @()
            }

            foreach ($line in $status) {
                $statusCode = $line.Substring(0, 2).Trim()
                $file = $line.Substring(3)

                switch ($statusCode) {
                    "A" { $changes["Added"] += $file }
                    "M" { $changes["Modified"] += $file }
                    "D" { $changes["Deleted"] += $file }
                    "R" { $changes["Renamed"] += $file }
                    "??" { $changes["Untracked"] += $file }
                    default {
                        # Für andere Status-Codes
                        if ($statusCode -match "A") { $changes["Added"] += $file }
                        elseif ($statusCode -match "M") { $changes["Modified"] += $file }
                        elseif ($statusCode -match "D") { $changes["Deleted"] += $file }
                        elseif ($statusCode -match "R") { $changes["Renamed"] += $file }
                        else { $changes["Modified"] += $file }
                    }
                }
            }

            # Überprüfe, ob genügend Änderungen für einen Commit vorliegen
            $totalChanges = ($changes.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
            if ($totalChanges -lt $script:Config.CommitSettings.MinChangesForCommit) {
                Write-Host "Nicht genügend Änderungen für einen automatischen Commit ($totalChanges/$($script:Config.CommitSettings.MinChangesForCommit))"
                return $true
            }

            # Bestimme Commit-Typ basierend auf Änderungen
            $commitType = "chore"
            if ($changes["Added"].Count -gt 0 -and $changes["Modified"].Count -eq 0 -and $changes["Deleted"].Count -eq 0) {
                $commitType = "feat"
            } elseif ($changes["Deleted"].Count -gt 0 -and $changes["Added"].Count -eq 0) {
                $commitType = "chore"
            } elseif ($changes["Modified"].Count -gt 0 -and $changes["Added"].Count -eq 0 -and $changes["Deleted"].Count -eq 0) {
                # Überprüfe, ob es sich um Dokumentationsänderungen handelt
                $docChanges = $changes["Modified"] | Where-Object { $_ -match "\.(md|txt|doc|docx|pdf)$" }
                if ($docChanges.Count -eq $changes["Modified"].Count) {
                    $commitType = "docs"
                } else {
                    $commitType = "fix"
                }
            }

            # Generiere Commit-Nachricht
            $commitMessage = "Automatischer Commit"

            # Füge Informationen über die Art der Änderungen hinzu
            $changeDescriptions = @()
            if ($changes["Added"].Count -gt 0) {
                $changeDescriptions += "Hinzugefügt: $($changes["Added"].Count) Dateien"
            }
            if ($changes["Modified"].Count -gt 0) {
                $changeDescriptions += "Geändert: $($changes["Modified"].Count) Dateien"
            }
            if ($changes["Deleted"].Count -gt 0) {
                $changeDescriptions += "Gelöscht: $($changes["Deleted"].Count) Dateien"
            }
            if ($changes["Renamed"].Count -gt 0) {
                $changeDescriptions += "Umbenannt: $($changes["Renamed"].Count) Dateien"
            }
            if ($changes["Untracked"].Count -gt 0) {
                $changeDescriptions += "Neu: $($changes["Untracked"].Count) Dateien"
            }

            if ($changeDescriptions.Count -gt 0) {
                $commitMessage = $changeDescriptions -join ", "
            }

            # Füge Dateiliste hinzu, wenn konfiguriert
            if ($script:Config.CommitSettings.IncludeFileList) {
                $fileList = @()
                $maxFiles = $script:Config.CommitSettings.MaxFilesInMessage

                # Sammle alle Dateien
                $allFiles = @()
                $allFiles += $changes["Added"]
                $allFiles += $changes["Modified"]
                $allFiles += $changes["Deleted"]
                $allFiles += $changes["Renamed"]
                $allFiles += $changes["Untracked"]

                # Begrenze die Anzahl der Dateien
                if ($allFiles.Count -gt $maxFiles) {
                    $fileList = $allFiles[0..($maxFiles - 1)]
                    $fileList += "... und $($allFiles.Count - $maxFiles) weitere Dateien"
                } else {
                    $fileList = $allFiles
                }

                if ($fileList.Count -gt 0) {
                    $commitMessage += "`n`nDateien:`n- " + ($fileList -join "`n- ")
                }
            }

            # Formatiere Commit-Nachricht gemäß Template
            $formattedMessage = $script:Config.CommitSettings.MessageTemplate -replace "{type}", $commitType -replace "{message}", $commitMessage

            # Füge alle Dateien hinzu
            git add .
            if (-not $?) {
                throw "Fehler beim Hinzufügen der Dateien zum Commit."
            }

            # Erstelle Commit
            git commit -m $formattedMessage
            if (-not $?) {
                throw "Fehler beim Erstellen des Commits."
            }

            # Aktualisiere Zeitstempel
            $script:LastCommitTime = Get-Date

            # Führe Push durch, falls konfiguriert
            if ($script:Config.RepositorySettings.AutoPush) {
                $currentBranch = git rev-parse --abbrev-ref HEAD
                git push origin $currentBranch
                if (-not $?) {
                    Write-Warning "Fehler beim automatischen Push. Fahre fort."
                } else {
                    Write-Host "Automatischer Push erfolgreich: origin/$currentBranch"
                }
            }

            Write-Host "Automatischer Commit erstellt: $formattedMessage"
            return $true
        } finally {
            # Zurück zum ursprünglichen Verzeichnis
            Pop-Location
        }
    } catch {
        Write-Error "Fehler beim automatischen Commit: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Registriert eine Dateiänderung.
.DESCRIPTION
    Registriert eine Dateiänderung für den nächsten automatischen Commit.
.PARAMETER File
    Die geänderte Datei.
.PARAMETER ChangeType
    Die Art der Änderung (Added, Modified, Deleted, Renamed).
#>
function Register-FileChange {
    param(
        [Parameter(Mandatory = $true)][string]$File,
        [Parameter(Mandatory = $true)][ValidateSet("Added", "Modified", "Deleted", "Renamed")][string]$ChangeType
    )

    try {
        if (-not $script:IsInitialized) {
            Write-Error "CommitManager ist nicht initialisiert."
            return $false
        }

        # Füge Änderung zur Liste hinzu
        $change = @{
            "File"      = $File
            "Type"      = $ChangeType
            "Timestamp" = Get-Date
        }
        $script:PendingChanges += $change

        # Überprüfe, ob ein automatischer Commit ausgelöst werden soll
        if ($script:PendingChanges.Count -ge $script:Config.CommitSettings.MinChangesForCommit) {
            # Parse Verzögerung aus Konfiguration
            $delayString = $script:Config.VSCodeSettings.AutoCommitDelay
            $delayValue = [int]($delayString -replace "[^0-9]", "")
            $delayUnit = $delayString -replace "[0-9]", ""

            # Konvertiere in Sekunden
            $delaySeconds = switch ($delayUnit) {
                "s" { $delayValue }
                "m" { $delayValue * 60 }
                default { 30 } # 30 Sekunden als Standard
            }

            # Starte verzögerten Commit
            Start-Sleep -Seconds $delaySeconds
            Invoke-AutoCommit
        }

        return $true
    } catch {
        Write-Error "Fehler beim Registrieren der Dateiänderung: $_"
        return $false
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

    try {
        if (-not $script:IsInitialized) {
            Write-Error "CommitManager ist nicht initialisiert."
            return $false
        }

        # Lade aktuelle Konfiguration
        $config = Get-Content -Path $script:ConfigFile -Raw | ConvertFrom-Json

        # Aktualisiere Konfiguration
        if ($PSBoundParameters.ContainsKey('Interval')) {
            $config.CommitSettings.AutoCommitInterval = $Interval
        }
        if ($PSBoundParameters.ContainsKey('MinChanges')) {
            $config.CommitSettings.MinChangesForCommit = $MinChanges
        }
        if ($PSBoundParameters.ContainsKey('GroupChanges')) {
            $config.CommitSettings.GroupSimilarChanges = $GroupChanges
        }
        if ($PSBoundParameters.ContainsKey('CommitOnSave')) {
            $config.VSCodeSettings.CommitOnSave = $CommitOnSave
        }

        # Speichere aktualisierte Konfiguration
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile

        # Aktualisiere lokale Konfiguration
        $script:Config = $config

        # Starte Timer neu, falls Intervall geändert wurde
        if ($PSBoundParameters.ContainsKey('Interval')) {
            Stop-AutoCommitTimer
            Start-AutoCommitTimer
        }

        Write-Host "Automatische Commit-Strategie konfiguriert"
        return $true
    } catch {
        Write-Error "Fehler bei der Konfiguration der automatischen Commit-Strategie: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Generiert eine Commit-Nachricht basierend auf Änderungen.
.DESCRIPTION
    Analysiert die Änderungen und generiert eine passende Commit-Nachricht.
.PARAMETER Path
    Der Pfad zum Repository.
#>
function Get-CommitMessageSuggestion {
    param(
        [Parameter(Mandatory = $false)][string]$Path = $PWD
    )

    try {
        # Überprüfe, ob das Verzeichnis ein Git-Repository ist
        if (-not (Test-Path (Join-Path $Path ".git"))) {
            Write-Error "Das angegebene Verzeichnis ist kein Git-Repository: $Path"
            return $null
        }

        # Wechsle in das Verzeichnis
        Push-Location $Path

        try {
            # Überprüfe, ob Änderungen vorliegen
            $status = git status --porcelain
            if (-not $status) {
                return "Keine Änderungen vorhanden"
            }

            # Analysiere Änderungen
            $changes = @{
                "Added"     = @()
                "Modified"  = @()
                "Deleted"   = @()
                "Renamed"   = @()
                "Untracked" = @()
            }

            foreach ($line in $status) {
                $statusCode = $line.Substring(0, 2).Trim()
                $file = $line.Substring(3)

                switch ($statusCode) {
                    "A" { $changes["Added"] += $file }
                    "M" { $changes["Modified"] += $file }
                    "D" { $changes["Deleted"] += $file }
                    "R" { $changes["Renamed"] += $file }
                    "??" { $changes["Untracked"] += $file }
                    default {
                        # Für andere Status-Codes
                        if ($statusCode -match "A") { $changes["Added"] += $file }
                        elseif ($statusCode -match "M") { $changes["Modified"] += $file }
                        elseif ($statusCode -match "D") { $changes["Deleted"] += $file }
                        elseif ($statusCode -match "R") { $changes["Renamed"] += $file }
                        else { $changes["Modified"] += $file }
                    }
                }
            }

            # Bestimme Commit-Typ basierend auf Änderungen
            $commitType = "chore"
            if ($changes["Added"].Count -gt 0 -and $changes["Modified"].Count -eq 0 -and $changes["Deleted"].Count -eq 0) {
                $commitType = "feat"
            } elseif ($changes["Deleted"].Count -gt 0 -and $changes["Added"].Count -eq 0) {
                $commitType = "chore"
            } elseif ($changes["Modified"].Count -gt 0 -and $changes["Added"].Count -eq 0 -and $changes["Deleted"].Count -eq 0) {
                # Überprüfe, ob es sich um Dokumentationsänderungen handelt
                $docChanges = $changes["Modified"] | Where-Object { $_ -match "\.(md|txt|doc|docx|pdf)$" }
                if ($docChanges.Count -eq $changes["Modified"].Count) {
                    $commitType = "docs"
                } else {
                    $commitType = "fix"
                }
            }

            # Generiere Commit-Nachricht
            $commitMessage = "Änderungen"

            # Füge Informationen über die Art der Änderungen hinzu
            $changeDescriptions = @()
            if ($changes["Added"].Count -gt 0) {
                $changeDescriptions += "Hinzugefügt: $($changes["Added"].Count) Dateien"
            }
            if ($changes["Modified"].Count -gt 0) {
                $changeDescriptions += "Geändert: $($changes["Modified"].Count) Dateien"
            }
            if ($changes["Deleted"].Count -gt 0) {
                $changeDescriptions += "Gelöscht: $($changes["Deleted"].Count) Dateien"
            }
            if ($changes["Renamed"].Count -gt 0) {
                $changeDescriptions += "Umbenannt: $($changes["Renamed"].Count) Dateien"
            }
            if ($changes["Untracked"].Count -gt 0) {
                $changeDescriptions += "Neu: $($changes["Untracked"].Count) Dateien"
            }

            if ($changeDescriptions.Count -gt 0) {
                $commitMessage = $changeDescriptions -join ", "
            }

            # Formatiere Commit-Nachricht gemäß Template
            $formattedMessage = $script:Config.CommitSettings.MessageTemplate -replace "{type}", $commitType -replace "{message}", $commitMessage

            return $formattedMessage
        } finally {
            # Zurück zum ursprünglichen Verzeichnis
            Pop-Location
        }
    } catch {
        Write-Error "Fehler bei der Generierung der Commit-Nachricht: $_"
        return $null
    }
}

# Exportiere Funktionen
Export-ModuleMember -Function Initialize-CommitManager, Start-AutoCommitTimer, Stop-AutoCommitTimer, Invoke-AutoCommit, Register-FileChange, Set-AutoCommitStrategy, Get-CommitMessageSuggestion
