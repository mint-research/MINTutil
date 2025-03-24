# MINTYversioning Manager
# Beschreibung: Hauptkomponente des MINTYversioning-Agents für Git-Aktivitäten und Versionsverwaltung

# Importiere benötigte Module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path (Split-Path -Parent $scriptPath) "config"

# Globale Variablen
$script:ConfigFile = Join-Path $configPath "versioning_config.json"
$script:Config = $null

<#
.SYNOPSIS
    Initialisiert den MINTYversioning Manager.
.DESCRIPTION
    Lädt die Konfiguration und initialisiert den MINTYversioning Manager.
#>
function Initialize-VersioningManager {
    try {
        # Lade Konfiguration
        if (Test-Path $script:ConfigFile) {
            $script:Config = Get-Content -Path $script:ConfigFile -Raw | ConvertFrom-Json
        } else {
            # Erstelle Standardkonfiguration
            $script:Config = @{
                "GitSettings" = @{
                    "DefaultBranch"         = "main"
                    "CommitMessageTemplate" = "[{type}] {message}"
                    "CommitTypes"           = @("feat", "fix", "docs", "style", "refactor", "test", "chore")
                    "AutoRebase"            = $true
                    "AutoMerge"             = $false
                }
                "Schedule"    = @{
                    "EventDriven"     = $true
                    "PollingInterval" = "60s"
                    "HookIntegration" = $true
                    "BatchWindow"     = "5s"
                }
                "Interfaces"  = @{
                    "Coder"   = $true
                    "Tester"  = $true
                    "Updater" = $true
                    "Log"     = $true
                    "Hive"    = $true
                }
            }

            # Speichere Standardkonfiguration
            $script:Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile
        }

        Write-Host "MINTYversioning Manager initialisiert"
        return $true
    } catch {
        Write-Error "Fehler bei der Initialisierung des MINTYversioning Managers: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Initialisiert ein Git-Repository.
.DESCRIPTION
    Initialisiert ein neues Git-Repository oder konfiguriert ein bestehendes.
.PARAMETER Path
    Der Pfad zum Repository.
.PARAMETER RemoteUrl
    Die URL des Remote-Repositories.
#>
function Initialize-GitRepository {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $false)][string]$RemoteUrl = $null
    )

    try {
        # Überprüfe, ob Git installiert ist
        $gitVersion = git --version
        if (-not $?) {
            Write-Error "Git ist nicht installiert oder nicht im PATH verfügbar."
            return $false
        }

        # Erstelle Verzeichnis, falls es nicht existiert
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
        }

        # Wechsle in das Verzeichnis
        Push-Location $Path

        try {
            # Überprüfe, ob bereits ein Git-Repository existiert
            $isGitRepo = Test-Path (Join-Path $Path ".git")

            if (-not $isGitRepo) {
                # Initialisiere neues Repository
                git init --initial-branch=$script:Config.GitSettings.DefaultBranch
                if (-not $?) {
                    throw "Fehler beim Initialisieren des Git-Repositories."
                }

                Write-Host "Git-Repository initialisiert in: $Path"

                # Erstelle .gitignore, falls nicht vorhanden
                $gitignorePath = Join-Path $Path ".gitignore"
                if (-not (Test-Path $gitignorePath)) {
                    @"
# Allgemeine Dateien
*.log
*.tmp
*.temp
*.bak

# Betriebssystemspezifische Dateien
.DS_Store
Thumbs.db

# Entwicklungsumgebungsspezifische Dateien
.vscode/
.idea/
*.suo
*.user
*.userosscache
*.sln.docstates

# Build-Ausgaben
bin/
obj/
out/
build/
"@ | Set-Content -Path $gitignorePath

                    git add .gitignore
                    git commit -m "[chore] Initial commit with .gitignore"
                }
            } else {
                Write-Host "Bestehendes Git-Repository gefunden in: $Path"
            }

            # Konfiguriere Remote, falls angegeben
            if ($RemoteUrl) {
                $remotes = git remote
                if ($remotes -contains "origin") {
                    git remote set-url origin $RemoteUrl
                } else {
                    git remote add origin $RemoteUrl
                }

                Write-Host "Remote 'origin' konfiguriert: $RemoteUrl"
            }

            return $true
        } finally {
            # Zurück zum ursprünglichen Verzeichnis
            Pop-Location
        }
    } catch {
        Write-Error "Fehler bei der Initialisierung des Git-Repositories: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Erstellt einen Commit.
.DESCRIPTION
    Erstellt einen Commit mit der angegebenen Nachricht.
.PARAMETER Path
    Der Pfad zum Repository.
.PARAMETER Message
    Die Commit-Nachricht.
.PARAMETER Type
    Der Typ des Commits (feat, fix, docs, etc.).
.PARAMETER Files
    Die Dateien, die dem Commit hinzugefügt werden sollen.
#>
function New-GitCommit {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $false)][string]$Type = "chore",
        [Parameter(Mandatory = $false)][string[]]$Files = @(".")
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
            # Überprüfe, ob der Commit-Typ gültig ist
            if ($script:Config.GitSettings.CommitTypes -notcontains $Type) {
                Write-Warning "Der angegebene Commit-Typ '$Type' ist nicht in der Konfiguration definiert. Verwende 'chore'."
                $Type = "chore"
            }

            # Formatiere Commit-Nachricht gemäß Template
            $commitMessage = $script:Config.GitSettings.CommitMessageTemplate -replace "{type}", $Type -replace "{message}", $Message

            # Füge Dateien hinzu
            foreach ($file in $Files) {
                git add $file
                if (-not $?) {
                    throw "Fehler beim Hinzufügen der Datei(en): $file"
                }
            }

            # Erstelle Commit
            git commit -m $commitMessage
            if (-not $?) {
                throw "Fehler beim Erstellen des Commits."
            }

            Write-Host "Commit erstellt: $commitMessage"
            return $true
        } finally {
            # Zurück zum ursprünglichen Verzeichnis
            Pop-Location
        }
    } catch {
        Write-Error "Fehler beim Erstellen des Commits: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Führt einen Push durch.
.DESCRIPTION
    Führt einen Push zum Remote-Repository durch.
.PARAMETER Path
    Der Pfad zum Repository.
.PARAMETER Remote
    Der Name des Remote-Repositories.
.PARAMETER Branch
    Der Name des Branches.
#>
function Invoke-GitPush {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $false)][string]$Remote = "origin",
        [Parameter(Mandatory = $false)][string]$Branch = $null
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
            # Bestimme aktuellen Branch, falls nicht angegeben
            if (-not $Branch) {
                $Branch = git rev-parse --abbrev-ref HEAD
                if (-not $?) {
                    throw "Fehler beim Ermitteln des aktuellen Branches."
                }
            }

            # Führe Push durch
            git push $Remote $Branch
            if (-not $?) {
                throw "Fehler beim Pushen zum Remote-Repository."
            }

            Write-Host "Push erfolgreich: $Remote/$Branch"
            return $true
        } finally {
            # Zurück zum ursprünglichen Verzeichnis
            Pop-Location
        }
    } catch {
        Write-Error "Fehler beim Pushen: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Führt einen Pull durch.
.DESCRIPTION
    Führt einen Pull vom Remote-Repository durch.
.PARAMETER Path
    Der Pfad zum Repository.
.PARAMETER Remote
    Der Name des Remote-Repositories.
.PARAMETER Branch
    Der Name des Branches.
#>
function Invoke-GitPull {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $false)][string]$Remote = "origin",
        [Parameter(Mandatory = $false)][string]$Branch = $null
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
            # Bestimme aktuellen Branch, falls nicht angegeben
            if (-not $Branch) {
                $Branch = git rev-parse --abbrev-ref HEAD
                if (-not $?) {
                    throw "Fehler beim Ermitteln des aktuellen Branches."
                }
            }

            # Führe Pull durch
            if ($script:Config.GitSettings.AutoRebase) {
                git pull --rebase $Remote $Branch
            } else {
                git pull $Remote $Branch
            }

            if (-not $?) {
                throw "Fehler beim Pullen vom Remote-Repository."
            }

            Write-Host "Pull erfolgreich: $Remote/$Branch"
            return $true
        } finally {
            # Zurück zum ursprünglichen Verzeichnis
            Pop-Location
        }
    } catch {
        Write-Error "Fehler beim Pullen: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Erstellt einen Tag.
.DESCRIPTION
    Erstellt einen Tag mit der angegebenen Version.
.PARAMETER Path
    Der Pfad zum Repository.
.PARAMETER Version
    Die Versionsnummer.
.PARAMETER Message
    Die Tag-Nachricht.
.PARAMETER Push
    Gibt an, ob der Tag gepusht werden soll.
#>
function New-GitTag {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Version,
        [Parameter(Mandatory = $false)][string]$Message = "",
        [Parameter(Mandatory = $false)][bool]$Push = $false
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
            # Formatiere Version
            $tagName = "v$Version"

            # Erstelle Tag
            if ($Message) {
                git tag -a $tagName -m $Message
            } else {
                git tag $tagName
            }

            if (-not $?) {
                throw "Fehler beim Erstellen des Tags."
            }

            Write-Host "Tag erstellt: $tagName"

            # Pushe Tag, falls gewünscht
            if ($Push) {
                git push origin $tagName
                if (-not $?) {
                    throw "Fehler beim Pushen des Tags."
                }

                Write-Host "Tag gepusht: $tagName"
            }

            return $true
        } finally {
            # Zurück zum ursprünglichen Verzeichnis
            Pop-Location
        }
    } catch {
        Write-Error "Fehler beim Erstellen des Tags: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Validiert eine Commit-Nachricht.
.DESCRIPTION
    Überprüft, ob eine Commit-Nachricht den Konventionen entspricht.
.PARAMETER Message
    Die zu validierende Commit-Nachricht.
#>
function Test-CommitMessage {
    param(
        [Parameter(Mandatory = $true)][string]$Message
    )

    try {
        # Überprüfe, ob die Nachricht dem Template entspricht
        $pattern = "\[(" + ($script:Config.GitSettings.CommitTypes -join "|") + ")\] .+"
        $isValid = $Message -match $pattern

        if (-not $isValid) {
            Write-Warning "Die Commit-Nachricht entspricht nicht dem Template: $($script:Config.GitSettings.CommitMessageTemplate)"
            Write-Warning "Gültige Commit-Typen: $($script:Config.GitSettings.CommitTypes -join ", ")"
        }

        return $isValid
    } catch {
        Write-Error "Fehler bei der Validierung der Commit-Nachricht: $_"
        return $false
    }
}

# Exportiere Funktionen
Export-ModuleMember -Function Initialize-VersioningManager, Initialize-GitRepository, New-GitCommit, Invoke-GitPush, Invoke-GitPull, New-GitTag, Test-CommitMessage
