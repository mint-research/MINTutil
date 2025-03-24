# MINTYgit Installation Guide

Diese Anleitung beschreibt die Installation und Konfiguration des MINTYgit-Agents für das MINTYhive-System.

## Voraussetzungen

Bevor Sie mit der Installation beginnen, stellen Sie sicher, dass folgende Voraussetzungen erfüllt sind:

1. **PowerShell 5.1 oder höher** ist installiert
2. **Git** ist installiert und im PATH verfügbar
3. **Visual Studio Code** ist installiert (für die VS Code-Integration)
4. **MINTYhive-System** ist installiert und konfiguriert

## Installation

### 1. Herunterladen des MINTYgit-Agents

Der MINTYgit-Agent ist Teil des MINTYhive-Systems und sollte bereits in Ihrem MINTYhive-Verzeichnis unter `modules/M99_hive/MINTYgit` vorhanden sein. Falls nicht, können Sie ihn manuell herunterladen:

```powershell
# Erstelle Verzeichnis
New-Item -Path "modules/M99_hive/MINTYgit" -ItemType Directory -Force

# Klone Repository (falls als separates Repository verfügbar)
# git clone https://github.com/MINTYhive/MINTYgit.git modules/M99_hive/MINTYgit
```

### 2. Konfiguration

#### 2.1 Grundkonfiguration

Die Grundkonfiguration erfolgt über die Datei `config/git_config.json`. Sie können die Standardkonfiguration verwenden oder sie an Ihre Bedürfnisse anpassen:

```powershell
# Initialisiere MINTYgit mit Standardkonfiguration
Import-Module .\modules\M99_hive\MINTYgit\src\MINTYgit.ps1
Initialize-VersionControl
```

#### 2.2 Konfiguration der automatischen Commit-Strategie

Die automatische Commit-Strategie kann über die Funktion `Set-AutoCommitStrategy` konfiguriert werden:

```powershell
# Konfiguriere automatische Commit-Strategie
Set-AutoCommitStrategy -Interval "15m" -MinChanges 3 -GroupChanges $true -CommitOnSave $true
```

Parameter:
- `Interval`: Intervall für automatische Commits (z.B. "15m", "1h")
- `MinChanges`: Minimale Anzahl an Änderungen für einen automatischen Commit
- `GroupChanges`: Gruppiert ähnliche Änderungen in Commit-Nachrichten
- `CommitOnSave`: Erstellt einen Commit bei jedem Speichern

### 3. VS Code-Integration

#### 3.1 Installation der VS Code-Erweiterung

Die VS Code-Erweiterung kann auf zwei Arten installiert werden:

**Option 1: Über die PowerShell-Funktion**

```powershell
# Aktiviere VS Code-Integration
Enable-VSCodeIntegration
```

**Option 2: Manuelle Installation**

1. Kopieren Sie den Inhalt des `vscode`-Verzeichnisses in ein neues VS Code-Erweiterungsprojekt
2. Führen Sie `npm install` aus, um die Abhängigkeiten zu installieren
3. Führen Sie `npm run compile` aus, um die Erweiterung zu kompilieren
4. Kopieren Sie die kompilierte Erweiterung in das VS Code-Erweiterungsverzeichnis

#### 3.2 Konfiguration der VS Code-Erweiterung

Die VS Code-Erweiterung kann über die VS Code-Einstellungen konfiguriert werden:

1. Öffnen Sie die VS Code-Einstellungen (Datei > Einstellungen)
2. Suchen Sie nach "mintygit"
3. Passen Sie die Einstellungen an Ihre Bedürfnisse an

### 4. Integration mit anderen MINTYhive-Agenten

MINTYgit kann mit anderen MINTYhive-Agenten integriert werden:

#### 4.1 Integration mit MINTYcoder

```powershell
# Konfiguriere Integration mit MINTYcoder
$config = Get-Content -Path "modules/M99_hive/MINTYgit/config/git_config.json" -Raw | ConvertFrom-Json
$config.IntegrationSettings.EnableCoderIntegration = $true
$config | ConvertTo-Json -Depth 10 | Set-Content -Path "modules/M99_hive/MINTYgit/config/git_config.json"
```

#### 4.2 Integration mit MINTYtester

```powershell
# Konfiguriere Integration mit MINTYtester
$config = Get-Content -Path "modules/M99_hive/MINTYgit/config/git_config.json" -Raw | ConvertFrom-Json
$config.IntegrationSettings.EnableTesterIntegration = $true
$config | ConvertTo-Json -Depth 10 | Set-Content -Path "modules/M99_hive/MINTYgit/config/git_config.json"
```

#### 4.3 Integration mit MINTYhive

```powershell
# Konfiguriere Integration mit MINTYhive
$config = Get-Content -Path "modules/M99_hive/MINTYgit/config/git_config.json" -Raw | ConvertFrom-Json
$config.IntegrationSettings.EnableHiveIntegration = $true
$config | ConvertTo-Json -Depth 10 | Set-Content -Path "modules/M99_hive/MINTYgit/config/git_config.json"
```

## Überprüfung der Installation

Nach der Installation können Sie die Funktionalität von MINTYgit überprüfen:

```powershell
# Importiere MINTYgit
Import-Module .\modules\M99_hive\MINTYgit\src\MINTYgit.ps1

# Überprüfe Version
# Get-MINTYgitVersion

# Teste automatischen Commit
Invoke-AutoCommit -Path $PWD
```

## Fehlerbehebung

### Problem: MINTYgit wird nicht initialisiert

**Lösung**: Überprüfen Sie, ob die Pfade korrekt sind und ob alle Abhängigkeiten installiert sind:

```powershell
# Überprüfe, ob Git installiert ist
git --version

# Überprüfe, ob die MINTYgit-Dateien vorhanden sind
Test-Path .\modules\M99_hive\MINTYgit\src\MINTYgit.ps1
```

### Problem: Automatische Commits werden nicht erstellt

**Lösung**: Überprüfen Sie die Konfiguration und ob genügend Änderungen vorliegen:

```powershell
# Überprüfe Konfiguration
$config = Get-Content -Path "modules/M99_hive/MINTYgit/config/git_config.json" -Raw | ConvertFrom-Json
$config.RepositorySettings.AutoCommit
$config.CommitSettings.MinChangesForCommit

# Überprüfe Git-Status
git status --porcelain
```

### Problem: VS Code-Integration funktioniert nicht

**Lösung**: Überprüfen Sie, ob die VS Code-Erweiterung korrekt installiert ist:

```powershell
# Überprüfe VS Code-Einstellungen
$config = Get-Content -Path "modules/M99_hive/MINTYgit/config/git_config.json" -Raw | ConvertFrom-Json
$config.VSCodeSettings.EnableExtension

# Aktiviere VS Code-Integration erneut
Enable-VSCodeIntegration
```

## Nächste Schritte

Nach der erfolgreichen Installation können Sie:

1. Die [Dokumentation](GitCommitAutoStrategy.md) lesen, um mehr über die automatische Commit-Strategie zu erfahren
2. Das [Beispiel](../examples/git_usage.ps1) ausführen, um die Funktionalität zu testen
3. Die [VS Code-Erweiterung](../vscode/README.md) konfigurieren, um die Integration zu optimieren

## Support

Bei Problemen oder Fragen wenden Sie sich bitte an das MINTYhive-Team oder erstellen Sie ein Issue im Repository.
