# Beispiel für die Verwendung der Git Commit Strategie

# Importieren des Moduls
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$srcPath = Join-Path $modulePath "src"
$modulePath = Join-Path $srcPath "MINTYgit.ps1"

# Importieren des Moduls
. $modulePath

# Initialisieren des Versionierungsagenten
Write-Host "Initialisiere Versionierungsagent..."
Initialize-VersionControl

# Erstelle ein Test-Repository
$testRepoPath = Join-Path $env:TEMP "MINTYgit-Test"
if (Test-Path $testRepoPath) {
    Remove-Item -Path $testRepoPath -Recurse -Force
}
New-Item -Path $testRepoPath -ItemType Directory -Force | Out-Null

# Wechsle in das Test-Repository
Push-Location $testRepoPath

try {
    # Initialisiere Git-Repository
    Write-Host "`nInitialisiere Git-Repository..."
    git init --initial-branch=main
    if (-not $?) {
        throw "Fehler beim Initialisieren des Git-Repositories."
    }

    # Erstelle README.md
    Write-Host "`nErstelle README.md..."
    @"
# Test-Repository

Dieses Repository dient zum Testen der Git Commit Strategie.

## Verwendung

Dieses Repository wird automatisch erstellt und gelöscht.
"@ | Set-Content -Path "README.md"

    # Erstelle .gitignore
    Write-Host "`nErstelle .gitignore..."
    @"
# Betriebssystemspezifische Dateien
.DS_Store
Thumbs.db

# Entwicklungsumgebungsspezifische Dateien
.vscode/
.idea/

# Umgebungsvariablen
.env
.env.local
.env.*
*.env

# Temporäre Dateien
/TEMP/
TEMP/
"@ | Set-Content -Path ".gitignore"

    # Erstelle Verzeichnisstruktur
    Write-Host "`nErstelle Verzeichnisstruktur..."
    New-Item -Path "src" -ItemType Directory -Force | Out-Null
    New-Item -Path "docs" -ItemType Directory -Force | Out-Null
    New-Item -Path "tests" -ItemType Directory -Force | Out-Null
    New-Item -Path "changes" -ItemType Directory -Force | Out-Null

    # Erstelle Beispieldateien
    Write-Host "`nErstelle Beispieldateien..."
    @"
# Beispiel-Skript

function Test-Function {
    param(
        [Parameter(Mandatory = `$true)][string]`$Parameter
    )

    Write-Host "Parameter: `$Parameter"
}

Test-Function -Parameter "Test"
"@ | Set-Content -Path "src\example.ps1"

    # Initialer Commit
    Write-Host "`nErstelle initialen Commit..."
    git add .
    git commit -m "Initial commit"

    # Erstelle Pretest-Snapshot
    Write-Host "`nErstelle Pretest-Snapshot..."
    New-GitSnapshot -Type "pretest" -Context "initial-test"

    # Ändere Dateien
    Write-Host "`nÄndere Dateien..."
    Add-Content -Path "src\example.ps1" -Value "`n# Neue Zeile"

    # Erstelle Change-Dokument
    Write-Host "`nErstelle Change-Dokument..."
    New-ChangeDoc -Type "feature" -Scope "example" -Reason "Beispiel für die Git Commit Strategie" -Status "completed" -Result "Erfolgreich" -Review "Reviewed" -Readme "Updated" -Gitignore "Updated" -IsPosttest $true

    # Erstelle Posttest-Snapshot
    Write-Host "`nErstelle Posttest-Snapshot..."
    New-GitSnapshot -Type "posttest" -Context "feature-complete"

    # Erstelle neuen Branch
    Write-Host "`nErstelle neuen Branch..."
    New-GitBranch -Type "feature" -Context "new-feature"

    # Ändere Dateien im neuen Branch
    Write-Host "`nÄndere Dateien im neuen Branch..."
    Add-Content -Path "src\example.ps1" -Value "`n# Weitere neue Zeile"

    # Erstelle Commit im neuen Branch
    Write-Host "`nErstelle Commit im neuen Branch..."
    # Verwende die New-GitCommit Funktion statt direkter Git-Befehle
    New-GitCommit -Message "Add new line" -Type "feat"

    # Demonstriere silent commit Funktionalität
    Write-Host "`nDemonstriere silent commit Funktionalität..."
    Add-Content -Path "src\example.ps1" -Value "`n# Weitere Zeile für silent commit"
    New-GitCommit -Message "Silent commit" -Type "chore" -Silent

    # Demonstriere Auto-Commit Funktionalität
    Write-Host "`nDemonstriere Auto-Commit Funktionalität..."
    Add-Content -Path "src\example.ps1" -Value "`n# Zeile für Auto-Commit"
    New-AutoCommit -Message "Automatischer Commit"

    # Wechsle zurück zum main-Branch
    Write-Host "`nWechsle zurück zum main-Branch..."
    git checkout main

    # Überprüfe Commit-Regeln
    Write-Host "`nÜberprüfe Commit-Regeln..."
    Test-CommitRules

    # Führe Branches zusammen
    Write-Host "`nFühre Branches zusammen..."
    Merge-GitBranch -Source "feature/new-feature" -Target "main"

    # Zeige Git-Log
    Write-Host "`nGit-Log:"
    git log --oneline --graph --decorate --all

    Write-Host "`nBeispiel abgeschlossen."
} catch {
    Write-Error "Fehler: $_"
} finally {
    # Zurück zum ursprünglichen Verzeichnis
    Pop-Location

    # Lösche Test-Repository
    Write-Host "`nLösche Test-Repository..."
    Remove-Item -Path $testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
}
