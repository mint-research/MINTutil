# Beispiel für die Verwendung von MINTYgit

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

# Konfigurieren der automatischen Commit-Strategie
Write-Host "`nKonfiguriere automatische Commit-Strategie..."
Set-AutoCommitStrategy -Interval "10m" -MinChanges 2 -GroupChanges $true -CommitOnSave $true

# Aktivieren der VS Code-Integration
Write-Host "`nAktiviere VS Code-Integration..."
Enable-VSCodeIntegration

# Erstellen eines neuen Branches
Write-Host "`nErstelle neuen Branch..."
New-Branch -Name "feature/new-feature" -Description "Eine neue Funktion" -IssueReference "ISSUE-123"

# Wechseln zu einem Branch
Write-Host "`nWechsle zu Branch..."
Switch-Branch -Name "feature/new-feature"

# Simuliere Änderungen
Write-Host "`nSimuliere Änderungen..."
$testFilePath = Join-Path $PWD "test_file.txt"
"Dies ist eine Testdatei für MINTYgit" | Out-File -FilePath $testFilePath
Write-Host "Testdatei erstellt: $testFilePath"

# Manuelles Erstellen eines Commits
Write-Host "`nErstelle manuellen Commit..."
if (Get-Command "New-GitCommit" -ErrorAction SilentlyContinue) {
    New-GitCommit -Path $PWD -Message "Testdatei hinzugefügt" -Type "feat"
} else {
    Write-Host "Funktion New-GitCommit nicht verfügbar, überspringe..."
}

# Simuliere weitere Änderungen
Write-Host "`nSimuliere weitere Änderungen..."
"Diese Zeile wurde hinzugefügt." | Out-File -FilePath $testFilePath -Append
Write-Host "Testdatei aktualisiert"

# Automatisches Commit
Write-Host "`nFühre automatischen Commit durch..."
Invoke-AutoCommit -Path $PWD

# Zusammenführen von Branches
Write-Host "`nFühre Branches zusammen..."
Merge-Branch -Source "feature/new-feature" -Target "main" -Message "Implementiere neue Funktion"

# Analysieren der Entwicklungshistorie
Write-Host "`nAnalysiere Entwicklungshistorie..."
$history = Get-History -Depth 5 -IncludeCommitMessages $true -IncludeFileChanges $true -IncludeAuthors $true
Write-Host $history

# Aufräumen
Write-Host "`nRäume auf..."
if (Test-Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Testdatei entfernt"
}

Write-Host "`nBeispiel abgeschlossen."
