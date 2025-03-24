# MINTYgit GitCommitStrategy
# Beschreibung: Implementierung der Git Commit Auto Strategie für MINTYgit

# Importiere benötigte Module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$configPath = Join-Path $modulePath "config"
$dataPath = Join-Path $modulePath "data"

# Globale Variablen
$script:ConfigFile = Join-Path $configPath "git_commit_strategy.json"
$script:Config = $null
$script:IsInitialized = $false

<#
.SYNOPSIS
    Initialisiert die Git Commit Strategie.
.DESCRIPTION
    Lädt die Konfiguration und initialisiert die Git Commit Strategie.
#>
function Initialize-GitCommitStrategy {
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
            Write-Error "Konfigurationsdatei nicht gefunden: $script:ConfigFile"
            return $false
        }

        $script:IsInitialized = $true
        Write-Host "Git Commit Strategie initialisiert"
        return $true
    } catch {
        Write-Error "Fehler bei der Initialisierung der Git Commit Strategie: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Erstellt einen Snapshot.
.DESCRIPTION
    Erstellt einen Snapshot des aktuellen Zustands.
.PARAMETER Type
    Der Typ des Snapshots (pretest, posttest, checkpoint, prerisk, session, stable).
.PARAMETER Context
    Der Kontext des Snapshots.
.PARAMETER Path
    Der Pfad zum Repository.
#>
function New-GitSnapshot {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("pretest", "posttest", "checkpoint", "prerisk", "session", "stable")][string]$Type,
        [Parameter(Mandatory = $true)][string]$Context,
        [Parameter(Mandatory = $false)][string]$Path = $PWD
    )

    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-GitCommitStrategy)) {
                return $false
            }
        }

        # Überprüfe, ob das Verzeichnis ein Git-Repository ist
        if (-not (Test-Path (Join-Path $Path ".git"))) {
            Write-Error "Das angegebene Verzeichnis ist kein Git-Repository: $Path"
            return $false
        }

        # Wechsle in das Verzeichnis
        Push-Location $Path

        try {
            # Hole Snapshot-Typ-Konfiguration
            $snapshotType = $script:Config.snapshot_types.$Type

            if (-not $snapshotType) {
                Write-Error "Ungültiger Snapshot-Typ: $Type"
                return $false
            }

            # Überprüfe, ob README.md und .gitignore vorhanden sind, falls erforderlich
            if ($snapshotType.requires_gitignore_and_readme -eq $true) {
                if (-not (Test-Path (Join-Path $Path "README.md"))) {
                    Write-Error "README.md ist erforderlich für Snapshot-Typ $Type"
                    return $false
                }

                if (-not (Test-Path (Join-Path $Path ".gitignore"))) {
                    Write-Error ".gitignore ist erforderlich für Snapshot-Typ $Type"
                    return $false
                }

                # Überprüfe, ob TEMP-Ordner in .gitignore ausgeschlossen ist
                $gitignoreContent = Get-Content -Path (Join-Path $Path ".gitignore") -Raw
                $tempExcluded = $false
                foreach ($entry in $script:Config.env_handling.gitignore_required_entries) {
                    if ($entry -like "*TEMP*" -and $gitignoreContent -match [regex]::Escape($entry)) {
                        $tempExcluded = $true
                        break
                    }
                }

                if (-not $tempExcluded) {
                    Write-Error "TEMP-Ordner muss in .gitignore ausgeschlossen sein für Snapshot-Typ $Type"
                    return $false
                }
            }

            # Formatiere Snapshot-Name
            $date = Get-Date -Format "yyyyMMdd"
            $snapshotName = $snapshotType.naming -replace "<yyyyMMdd>", $date -replace "<context>", $Context

            if ($Type -eq "session") {
                if ($Context -notmatch "^(start|end)$") {
                    Write-Error "Kontext für Session-Snapshot muss 'start' oder 'end' sein"
                    return $false
                }
                $snapshotName = $snapshotType.naming -replace "<yyyyMMdd>", $date -replace "<start\|end>", $Context
            }

            # Erstelle Branch, falls erforderlich
            if ($snapshotType.branch -eq $true) {
                # Überprüfe, ob Branch bereits existiert
                $existingBranches = git branch --list $snapshotName
                if ($existingBranches) {
                    Write-Error "Branch $snapshotName existiert bereits"
                    return $false
                }

                # Erstelle Branch
                git checkout -b $snapshotName
                if (-not $?) {
                    throw "Fehler beim Erstellen des Branches $snapshotName"
                }

                Write-Host "Branch $snapshotName erstellt"
            }

            # Erstelle Commit
            git add .
            if (-not $?) {
                throw "Fehler beim Hinzufügen der Dateien zum Commit"
            }

            $commitMessage = "[$Type] $Context"
            git commit -m $commitMessage
            if (-not $?) {
                throw "Fehler beim Erstellen des Commits"
            }

            # Erstelle Tag
            git tag $snapshotName
            if (-not $?) {
                throw "Fehler beim Erstellen des Tags $snapshotName"
            }

            Write-Host "Snapshot $snapshotName erstellt"
            return $true
        } finally {
            # Zurück zum ursprünglichen Verzeichnis
            Pop-Location
        }
    } catch {
        Write-Error "Fehler beim Erstellen des Snapshots: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Erstellt einen Branch.
.DESCRIPTION
    Erstellt einen Branch des angegebenen Typs.
.PARAMETER Type
    Der Typ des Branches (main, dev, agent, review, fallback, stable, archive).
.PARAMETER Context
    Der Kontext des Branches.
.PARAMETER Path
    Der Pfad zum Repository.
#>
function New-GitBranch {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("main", "dev", "agent", "review", "fallback", "stable", "archive")][string]$Type,
        [Parameter(Mandatory = $true)][string]$Context,
        [Parameter(Mandatory = $false)][string]$Path = $PWD
    )

    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-GitCommitStrategy)) {
                return $false
            }
        }

        # Überprüfe, ob das Verzeichnis ein Git-Repository ist
        if (-not (Test-Path (Join-Path $Path ".git"))) {
            Write-Error "Das angegebene Verzeichnis ist kein Git-Repository: $Path"
            return $false
        }

        # Wechsle in das Verzeichnis
        Push-Location $Path

        try {
            # Hole Branch-Typ-Konfiguration
            $branchType = $script:Config.branch_types.$Type

            if (-not $branchType) {
                Write-Error "Ungültiger Branch-Typ: $Type"
                return $false
            }

            # Überprüfe, ob Branch schreibgeschützt ist
            if ($branchType.write_protected -eq $true) {
                Write-Error "Branch-Typ $Type ist schreibgeschützt"
                return $false
            }

            # Formatiere Branch-Name
            $branchName = $Type
            if ($branchType.naming) {
                $date = Get-Date -Format "yyyyMMdd"
                $branchName = $branchType.naming -replace "<yyyyMMdd>", $date -replace "<session>|<topic>|<reason>|<feature>|<context>", $Context
            }

            # Überprüfe, ob Branch bereits existiert
            $existingBranches = git branch --list $branchName
            if ($existingBranches) {
                Write-Error "Branch $branchName existiert bereits"
                return $false
            }

            # Erstelle Branch
            git checkout -b $branchName
            if (-not $?) {
                throw "Fehler beim Erstellen des Branches $branchName"
            }

            Write-Host "Branch $branchName erstellt"
            return $true
        } finally {
            # Zurück zum ursprünglichen Verzeichnis
            Pop-Location
        }
    } catch {
        Write-Error "Fehler beim Erstellen des Branches: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Erstellt ein Change-Dokument.
.DESCRIPTION
    Erstellt ein Change-Dokument für einen Commit.
.PARAMETER Type
    Der Typ der Änderung.
.PARAMETER Scope
    Der Umfang der Änderung.
.PARAMETER Reason
    Der Grund für die Änderung.
.PARAMETER Status
    Der Status der Änderung.
.PARAMETER Result
    Das Ergebnis der Änderung.
.PARAMETER Review
    Die Review-Informationen.
.PARAMETER Linked
    Verknüpfte Informationen.
.PARAMETER Branch
    Der Branch, auf dem die Änderung durchgeführt wurde.
.PARAMETER Readme
    Informationen zur README.md.
.PARAMETER Gitignore
    Informationen zur .gitignore.
.PARAMETER Env
    Informationen zur Umgebungskonfiguration.
.PARAMETER Path
    Der Pfad zum Repository.
.PARAMETER IsPosttest
    Gibt an, ob es sich um ein Posttest-Change-Dokument handelt.
#>
function New-ChangeDoc {
    param(
        [Parameter(Mandatory = $true)][string]$Type,
        [Parameter(Mandatory = $true)][string]$Scope,
        [Parameter(Mandatory = $true)][string]$Reason,
        [Parameter(Mandatory = $false)][string]$Status,
        [Parameter(Mandatory = $false)][string]$Result,
        [Parameter(Mandatory = $false)][string]$Review,
        [Parameter(Mandatory = $false)][string]$Linked,
        [Parameter(Mandatory = $false)][string]$Branch,
        [Parameter(Mandatory = $false)][string]$Readme,
        [Parameter(Mandatory = $false)][string]$Gitignore,
        [Parameter(Mandatory = $false)][string]$Env,
        [Parameter(Mandatory = $false)][string]$Path = $PWD,
        [Parameter(Mandatory = $false)][bool]$IsPosttest = $false
    )

    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-GitCommitStrategy)) {
                return $false
            }
        }

        # Überprüfe, ob das Verzeichnis ein Git-Repository ist
        if (-not (Test-Path (Join-Path $Path ".git"))) {
            Write-Error "Das angegebene Verzeichnis ist kein Git-Repository: $Path"
            return $false
        }

        # Überprüfe erforderliche Felder
        foreach ($field in $script:Config.change_doc_format.required_fields) {
            $fieldName = $field -replace "@", ""
            $fieldValue = Get-Variable -Name $fieldName -ValueOnly -ErrorAction SilentlyContinue
            if ([string]::IsNullOrWhiteSpace($fieldValue)) {
                Write-Error "Feld $field ist erforderlich"
                return $false
            }
        }

        # Überprüfe zusätzliche erforderliche Felder für Posttest
        if ($IsPosttest) {
            foreach ($field in $script:Config.change_doc_format.posttest_required_fields) {
                $fieldName = $field -replace "@", ""
                $fieldValue = Get-Variable -Name $fieldName -ValueOnly -ErrorAction SilentlyContinue
                if ([string]::IsNullOrWhiteSpace($fieldValue)) {
                    Write-Error "Feld $field ist erforderlich für Posttest"
                    return $false
                }
            }
        }

        # Erstelle Verzeichnis für Change-Dokumente, falls es nicht existiert
        $changeDocDir = Join-Path $Path "changes"
        if (-not (Test-Path $changeDocDir)) {
            New-Item -Path $changeDocDir -ItemType Directory -Force | Out-Null
        }

        # Erstelle Change-Dokument
        $date = Get-Date -Format "yyyyMMdd-HHmmss"
        $changeDocPath = Join-Path $changeDocDir "change-$date.md"

        $content = "# Change-Dokument: $date`n`n"

        foreach ($field in $script:Config.change_doc_format.structure) {
            $fieldName = $field -replace "@", ""
            $fieldValue = Get-Variable -Name $fieldName -ValueOnly -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($fieldValue)) {
                $content += "$field`: $fieldValue`n`n"
            }
        }

        # Speichere Change-Dokument
        $content | Set-Content -Path $changeDocPath

        Write-Host "Change-Dokument erstellt: $changeDocPath"
        return $true
    } catch {
        Write-Error "Fehler beim Erstellen des Change-Dokuments: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Überprüft, ob ein Commit die Regeln erfüllt.
.DESCRIPTION
    Überprüft, ob ein Commit die definierten Regeln erfüllt.
.PARAMETER Path
    Der Pfad zum Repository.
#>
function Test-CommitRules {
    param(
        [Parameter(Mandatory = $false)][string]$Path = $PWD
    )

    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-GitCommitStrategy)) {
                return $false
            }
        }

        # Überprüfe, ob das Verzeichnis ein Git-Repository ist
        if (-not (Test-Path (Join-Path $Path ".git"))) {
            Write-Error "Das angegebene Verzeichnis ist kein Git-Repository: $Path"
            return $false
        }

        # Wechsle in das Verzeichnis
        Push-Location $Path

        try {
            $errors = @()

            # Überprüfe, ob README.md vorhanden ist
            if (-not (Test-Path (Join-Path $Path "README.md"))) {
                $errors += "README.md ist nicht vorhanden"
            }

            # Überprüfe, ob .gitignore vorhanden ist
            if (-not (Test-Path (Join-Path $Path ".gitignore"))) {
                $errors += ".gitignore ist nicht vorhanden"
            } else {
                # Überprüfe, ob TEMP-Ordner in .gitignore ausgeschlossen ist
                $gitignoreContent = Get-Content -Path (Join-Path $Path ".gitignore") -Raw
                $tempExcluded = $false
                foreach ($entry in $script:Config.env_handling.gitignore_required_entries) {
                    if ($entry -like "*TEMP*" -and $gitignoreContent -match [regex]::Escape($entry)) {
                        $tempExcluded = $true
                        break
                    }
                }

                if (-not $tempExcluded) {
                    $errors += "TEMP-Ordner ist nicht in .gitignore ausgeschlossen"
                }

                # Überprüfe, ob .env-Dateien in .gitignore ausgeschlossen sind
                $envExcluded = $true
                foreach ($entry in $script:Config.env_handling.gitignore_required_entries) {
                    if ($entry -like "*.env*" -and -not ($gitignoreContent -match [regex]::Escape($entry))) {
                        $envExcluded = $false
                        break
                    }
                }

                if (-not $envExcluded) {
                    $errors += ".env-Dateien sind nicht in .gitignore ausgeschlossen"
                }
            }

            # Überprüfe, ob Change-Dokumente vorhanden sind
            $changeDocDir = Join-Path $Path "changes"
            if (-not (Test-Path $changeDocDir) -or (Get-ChildItem -Path $changeDocDir -Filter "*.md" | Measure-Object).Count -eq 0) {
                $errors += "Keine Change-Dokumente vorhanden"
            }

            # Überprüfe, ob Posttest-Snapshot vorhanden ist
            $posttestTags = git tag -l "posttest-*"
            if (-not $posttestTags) {
                $errors += "Kein Posttest-Snapshot vorhanden"
            }

            if ($errors.Count -gt 0) {
                Write-Host "Commit-Regeln nicht erfüllt:"
                foreach ($error in $errors) {
                    Write-Host "- $error"
                }
                return $false
            }

            Write-Host "Alle Commit-Regeln erfüllt"
            return $true
        } finally {
            # Zurück zum ursprünglichen Verzeichnis
            Pop-Location
        }
    } catch {
        Write-Error "Fehler bei der Überprüfung der Commit-Regeln: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Führt einen Merge durch.
.DESCRIPTION
    Führt einen Merge von einem Branch in einen anderen durch.
.PARAMETER Source
    Der Quell-Branch.
.PARAMETER Target
    Der Ziel-Branch.
.PARAMETER Path
    Der Pfad zum Repository.
#>
function Merge-GitBranch {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $false)][string]$Path = $PWD
    )

    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-GitCommitStrategy)) {
                return $false
            }
        }

        # Überprüfe, ob das Verzeichnis ein Git-Repository ist
        if (-not (Test-Path (Join-Path $Path ".git"))) {
            Write-Error "Das angegebene Verzeichnis ist kein Git-Repository: $Path"
            return $false
        }

        # Wechsle in das Verzeichnis
        Push-Location $Path

        try {
            # Überprüfe, ob Branches existieren
            $sourceBranches = git branch --list $Source
            if (-not $sourceBranches) {
                Write-Error "Quell-Branch $Source existiert nicht"
                return $false
            }

            $targetBranches = git branch --list $Target
            if (-not $targetBranches) {
                Write-Error "Ziel-Branch $Target existiert nicht"
                return $false
            }

            # Überprüfe, ob Ziel-Branch schreibgeschützt ist
            $targetType = $null
            foreach ($branchType in $script:Config.branch_types.PSObject.Properties) {
                if ($Target -eq $branchType.Name -or $Target -match "^$($branchType.Name)/") {
                    $targetType = $branchType.Name
                    break
                }
            }

            if ($targetType -and $script:Config.branch_types.$targetType.write_protected -eq $true) {
                # Überprüfe zusätzliche Regeln für Merge in main
                if ($Target -eq "main") {
                    if (-not (Test-CommitRules -Path $Path)) {
                        Write-Error "Commit-Regeln nicht erfüllt für Merge in main"
                        return $false
                    }
                }
            }

            # Speichere aktuellen Branch
            $currentBranch = git rev-parse --abbrev-ref HEAD
            if (-not $?) {
                throw "Fehler beim Ermitteln des aktuellen Branches"
            }

            # Wechsle zum Ziel-Branch
            git checkout $Target
            if (-not $?) {
                throw "Fehler beim Wechseln zum Ziel-Branch $Target"
            }

            # Führe Merge durch
            git merge --no-ff $Source -m "Merge $Source into $Target"
            if (-not $?) {
                # Überprüfe, ob Konflikte vorliegen
                $conflicts = git diff --name-only --diff-filter=U
                if ($conflicts) {
                    Write-Warning "Konflikte beim Merge gefunden. Bitte löse die Konflikte in folgenden Dateien:"
                    $conflicts | ForEach-Object { Write-Warning "- $_" }

                    # Breche Merge ab
                    git merge --abort
                    throw "Konflikte beim Merge gefunden. Merge abgebrochen."
                } else {
                    throw "Fehler beim Merge."
                }
            }

            # Wechsle zurück zum ursprünglichen Branch
            git checkout $currentBranch
            if (-not $?) {
                Write-Warning "Fehler beim Wechseln zurück zum ursprünglichen Branch $currentBranch"
            }

            Write-Host "Branch $Source in $Target zusammengeführt"
            return $true
        } finally {
            # Zurück zum ursprünglichen Verzeichnis
            Pop-Location
        }
    } catch {
        Write-Error "Fehler beim Zusammenführen der Branches: $_"
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
.PARAMETER Silent
    Gibt an, ob der Commit ohne Ausgabe erstellt werden soll.
#>
function New-GitCommit {
    param(
        [Parameter(Mandatory = $false)][string]$Path = $PWD,
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $false)][string]$Type = "feat",
        [Parameter(Mandatory = $false)][switch]$Silent
    )

    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-GitCommitStrategy)) {
                if ($Silent) {
                    return $false
                } else {
                    throw "Git Commit Strategie konnte nicht initialisiert werden."
                }
            }
        }

        # Überprüfe, ob ein Nutzer existiert
        $gitUser = git config user.name
        $gitEmail = git config user.email

        if ([string]::IsNullOrWhiteSpace($gitUser) -or [string]::IsNullOrWhiteSpace($gitEmail)) {
            if ($Silent) {
                return $false
            } else {
                throw "Git Benutzer ist nicht konfiguriert. Bitte konfiguriere Git mit 'git config --global user.name' und 'git config --global user.email'."
            }
        }

        # Überprüfe, ob der Pfad existiert
        if (-not (Test-Path $Path)) {
            if ($Silent) {
                return $false
            } else {
                throw "Der angegebene Pfad existiert nicht: $Path"
            }
        }

        # Überprüfe, ob das Verzeichnis ein Git-Repository ist
        if (-not (Test-Path (Join-Path $Path ".git"))) {
            if ($Silent) {
                return $false
            } else {
                throw "Das angegebene Verzeichnis ist kein Git-Repository: $Path"
            }
        }

        # Überprüfe Schreibzugriff
        try {
            $testFile = Join-Path $Path ".git\MINTYgit_write_test"
            "test" | Out-File -FilePath $testFile -ErrorAction Stop
            Remove-Item -Path $testFile -ErrorAction Stop
        } catch {
            if ($Silent) {
                return $false
            } else {
                throw "Kein Schreibzugriff auf das Git-Repository: $Path"
            }
        }

        # Wechsle in das Verzeichnis
        Push-Location $Path

        try {
            # Überprüfe, ob es Änderungen gibt
            $status = git status --porcelain
            if (-not $status) {
                if (-not $Silent) {
                    Write-Host "Keine Änderungen zum Committen"
                }
                return $true
            }

            # Füge alle Änderungen hinzu
            git add .
            if (-not $?) {
                if ($Silent) {
                    return $false
                } else {
                    throw "Fehler beim Hinzufügen der Dateien zum Commit"
                }
            }

            # Erstelle Commit
            $commitMessage = "[$Type] $Message"

            # Führe den Commit aus, je nach Silent-Parameter
            if ($Silent) {
                git commit -m $commitMessage | Out-Null
            } else {
                git commit -m $commitMessage
            }

            if (-not $?) {
                if ($Silent) {
                    return $false
                } else {
                    throw "Fehler beim Erstellen des Commits"
                }
            }

            if (-not $Silent) {
                Write-Host "Commit erstellt: $commitMessage"
            }
            return $true
        } finally {
            # Zurück zum ursprünglichen Verzeichnis
            Pop-Location
        }
    } catch {
        if (-not $Silent) {
            Write-Error "Fehler beim Erstellen des Commits: $_"
        }
        return $false
    }
}

<#
.SYNOPSIS
    Erstellt einen automatischen Commit.
.DESCRIPTION
    Erstellt einen automatischen Commit basierend auf dem aktuellen Branch.
.PARAMETER Path
    Der Pfad zum Repository.
.PARAMETER Message
    Die Commit-Nachricht. Wenn nicht angegeben, wird eine automatische Nachricht generiert.
#>
function New-AutoCommit {
    param(
        [Parameter(Mandatory = $false)][string]$Path = $PWD,
        [Parameter(Mandatory = $false)][string]$Message = "Automatischer Commit"
    )

    try {
        # Überprüfe, ob ein Nutzer existiert (silent)
        $gitUser = git config user.name
        $gitEmail = git config user.email

        if ([string]::IsNullOrWhiteSpace($gitUser) -or [string]::IsNullOrWhiteSpace($gitEmail)) {
            # Frage Benutzerinformationen ab, wenn sie fehlen
            Write-Host "Git Benutzer ist nicht konfiguriert."
            $gitUser = Read-Host "Bitte gib deinen Namen ein"
            $gitEmail = Read-Host "Bitte gib deine E-Mail-Adresse ein"

            if ([string]::IsNullOrWhiteSpace($gitUser) -or [string]::IsNullOrWhiteSpace($gitEmail)) {
                Write-Error "Git Benutzer konnte nicht konfiguriert werden."
                return $false
            }

            git config --global user.name $gitUser
            git config --global user.email $gitEmail
        }

        # Überprüfe, ob der Pfad existiert (silent)
        if (-not (Test-Path $Path)) {
            # Frage nach dem Pfad, wenn er nicht existiert
            Write-Host "Der angegebene Pfad existiert nicht: $Path"
            $Path = Read-Host "Bitte gib den Pfad zum Git-Repository ein"

            if (-not (Test-Path $Path)) {
                Write-Error "Der angegebene Pfad existiert nicht: $Path"
                return $false
            }
        }

        if (-not $script:IsInitialized) {
            if (-not (Initialize-GitCommitStrategy)) {
                Write-Error "Git Commit Strategie konnte nicht initialisiert werden."
                return $false
            }
        }

        # Überprüfe, ob das Verzeichnis ein Git-Repository ist (silent)
        if (-not (Test-Path (Join-Path $Path ".git"))) {
            Write-Host "Das angegebene Verzeichnis ist kein Git-Repository: $Path"
            $initRepo = Read-Host "Möchtest du ein neues Git-Repository initialisieren? (j/n)"

            if ($initRepo -eq "j") {
                Push-Location $Path
                git init
                Pop-Location
            } else {
                Write-Error "Das angegebene Verzeichnis ist kein Git-Repository: $Path"
                return $false
            }
        }

        # Überprüfe Schreibzugriff (silent)
        try {
            $testFile = Join-Path $Path ".git\MINTYgit_write_test"
            "test" | Out-File -FilePath $testFile -ErrorAction Stop
            Remove-Item -Path $testFile -ErrorAction Stop
        } catch {
            Write-Error "Kein Schreibzugriff auf das Git-Repository: $Path"
            return $false
        }

        # Wechsle in das Verzeichnis
        Push-Location $Path

        try {
            # Hole aktuellen Branch
            $currentBranch = git rev-parse --abbrev-ref HEAD
            if (-not $?) {
                Write-Error "Konnte aktuellen Branch nicht ermitteln."
                return $false
            }

            # Überprüfe, ob der aktuelle Branch auto_commit aktiviert hat
            $branchType = $null
            foreach ($type in $script:Config.branch_types.PSObject.Properties) {
                if ($currentBranch -eq $type.Name -or $currentBranch -match "^$($type.Name)/") {
                    $branchType = $type.Value
                    break
                }
            }

            # Wenn der Branch auto_commit aktiviert hat, führe den Commit durch
            if ($branchType -and $branchType.auto_commit -eq $true) {
                $silent = $branchType.silent_commits -eq $true
                return (New-GitCommit -Path $Path -Message $Message -Type "auto" -Silent:$silent)
            } else {
                Write-Host "Der aktuelle Branch '$currentBranch' unterstützt keine automatischen Commits."
                $forceCommit = Read-Host "Möchtest du trotzdem einen Commit erstellen? (j/n)"

                if ($forceCommit -eq "j") {
                    return (New-GitCommit -Path $Path -Message $Message -Type "manual")
                }
            }

            return $true
        } finally {
            # Zurück zum ursprünglichen Verzeichnis
            Pop-Location
        }
    } catch {
        Write-Error "Fehler beim Erstellen des automatischen Commits: $_"
        return $false
    }
}

# Exportiere Funktionen
Export-ModuleMember -Function Initialize-GitCommitStrategy, New-GitSnapshot, New-GitBranch, New-ChangeDoc, Test-CommitRules, Merge-GitBranch, New-GitCommit, New-AutoCommit
