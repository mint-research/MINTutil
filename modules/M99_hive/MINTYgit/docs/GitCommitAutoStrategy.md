# Git Commit Auto Strategie

Dieses Dokument beschreibt die automatische Commit-Strategie, die vom MINTYgit-Agent implementiert wird. Die Strategie ermöglicht eine automatisierte Versionskontrolle mit intelligenten Commit-Nachrichten und ist über VS Code integriert.

## Übersicht

Die Git Commit Auto Strategie automatisiert den Prozess der Versionskontrolle, indem sie:

1. Änderungen an Dateien überwacht
2. Automatisch Commits erstellt, basierend auf definierten Regeln
3. Intelligente Commit-Nachrichten generiert
4. Nahtlos in die VS Code-Entwicklungsumgebung integriert ist

Diese Strategie reduziert den manuellen Aufwand für die Versionskontrolle und stellt sicher, dass alle Änderungen ordnungsgemäß dokumentiert werden.

## Komponenten

Die Git Commit Auto Strategie besteht aus folgenden Hauptkomponenten:

### 1. CommitManager

Der CommitManager ist verantwortlich für:
- Überwachung von Dateiänderungen
- Automatische Erstellung von Commits
- Generierung von Commit-Nachrichten
- Verwaltung der Commit-Intervalle

### 2. VSCodeIntegration

Die VSCodeIntegration ermöglicht:
- Nahtlose Integration in VS Code
- Statusleisten-Anzeige
- Tastenkombinationen für Git-Operationen
- Automatische Commits bei Speichervorgängen

### 3. GitManager

Der GitManager führt die eigentlichen Git-Operationen durch:
- Repository-Initialisierung
- Branch-Verwaltung
- Merge-Operationen
- Push/Pull-Operationen

## Auslöser für automatische Commits

Automatische Commits können durch verschiedene Ereignisse ausgelöst werden:

### 1. Zeitbasierte Auslöser

- **Intervall-basiert**: Commits werden in regelmäßigen Zeitabständen erstellt (z.B. alle 15 Minuten)
- **Konfigurierbar**: Das Intervall kann in der Konfigurationsdatei angepasst werden

### 2. Ereignisbasierte Auslöser

- **Dateiänderungen**: Commits werden nach einer bestimmten Anzahl von Änderungen erstellt
- **Speichervorgänge**: Commits können bei jedem Speichervorgang in VS Code erstellt werden
- **Bestimmte Aktionen**: Commits können durch bestimmte Aktionen wie Tests oder Builds ausgelöst werden

## Intelligente Commit-Nachrichten

Die Strategie generiert automatisch Commit-Nachrichten basierend auf:

### 1. Art der Änderungen

- **Neue Dateien**: Erkennt hinzugefügte Dateien
- **Geänderte Dateien**: Erkennt Änderungen an bestehenden Dateien
- **Gelöschte Dateien**: Erkennt gelöschte Dateien
- **Umbenannte Dateien**: Erkennt umbenannte Dateien

### 2. Konventionelles Commit-Format

Verwendet das konventionelle Commit-Format mit Typen wie:
- `feat`: Neue Funktionen
- `fix`: Fehlerbehebungen
- `docs`: Dokumentationsänderungen
- `style`: Formatierungsänderungen
- `refactor`: Code-Refactoring
- `test`: Test-bezogene Änderungen
- `chore`: Routineaufgaben und Wartung

### 3. Gruppierung von Änderungen

- Ähnliche Änderungen werden in logischen Gruppen zusammengefasst
- Die Anzahl der Dateien in der Commit-Nachricht kann begrenzt werden

## Konfiguration

Die Git Commit Auto Strategie kann über die Datei `config/git_config.json` konfiguriert werden:

### CommitSettings

```json
"CommitSettings": {
    "MessageTemplate": "[{type}] {message}",
    "CommitTypes": ["feat", "fix", "docs", "style", "refactor", "test", "chore"],
    "AutoCommitInterval": "15m",
    "MinChangesForCommit": 3,
    "GroupSimilarChanges": true,
    "IncludeFileList": true,
    "MaxFilesInMessage": 5
}
```

- **MessageTemplate**: Template für Commit-Nachrichten
- **CommitTypes**: Gültige Commit-Typen
- **AutoCommitInterval**: Intervall für automatische Commits (Format: Zahl + Einheit, z.B. "15m", "1h")
- **MinChangesForCommit**: Minimale Anzahl an Änderungen für einen automatischen Commit
- **GroupSimilarChanges**: Gruppierung ähnlicher Änderungen
- **IncludeFileList**: Gibt an, ob eine Liste der geänderten Dateien in die Commit-Nachricht aufgenommen werden soll
- **MaxFilesInMessage**: Maximale Anzahl der Dateien, die in der Commit-Nachricht aufgeführt werden

### VSCodeSettings

```json
"VSCodeSettings": {
    "EnableExtension": true,
    "CommitOnSave": true,
    "ShowNotifications": true,
    "StatusBarIntegration": true,
    "AutoCommitDelay": "30s",
    "SuggestCommitMessages": true
}
```

- **EnableExtension**: Aktivierung der VS Code-Erweiterung
- **CommitOnSave**: Commit bei Speichern
- **ShowNotifications**: Anzeige von Benachrichtigungen
- **StatusBarIntegration**: Integration in die Statusleiste
- **AutoCommitDelay**: Verzögerung für automatische Commits nach Dateiänderungen
- **SuggestCommitMessages**: Vorschläge für Commit-Nachrichten

## VS Code-Integration

Die VS Code-Integration bietet folgende Funktionen:

### 1. Statusleiste

- Anzeige des aktuellen Branches
- Anzeige der Anzahl der geänderten Dateien
- Visuelles Feedback zum Status des Repositories

### 2. Tastenkombinationen

- `Ctrl+Alt+C`: Commit erstellen
- `Ctrl+Alt+P`: Push durchführen
- `Ctrl+Alt+L`: Pull durchführen
- `Ctrl+Alt+A`: Automatischen Commit auslösen

### 3. Tasks

- Vordefinierte Tasks für Git-Operationen
- Einfacher Zugriff über die Befehlspalette

### 4. Einstellungen

- Integration in die VS Code-Einstellungen
- Konfiguration über die settings.json-Datei

## Implementierung

Die Git Commit Auto Strategie ist als PowerShell-Module implementiert:

### 1. CommitManager.ps1

Enthält die Logik für:
- Überwachung von Dateiänderungen
- Automatische Commits
- Generierung von Commit-Nachrichten

### 2. VSCodeIntegration.ps1

Enthält die Logik für:
- Integration in VS Code
- Ereignisbehandlung für Speichervorgänge
- Statusleisten-Anzeige

### 3. MINTYgit.ps1

Hauptmodul, das:
- Die anderen Module importiert
- Die Hauptfunktionen exportiert
- Die Konfiguration verwaltet

## Verwendung

### 1. Initialisierung

```powershell
# Importieren des Moduls
Import-Module .\src\MINTYgit.ps1

# Initialisieren des Versionierungsagenten
Initialize-VersionControl
```

### 2. Konfiguration der automatischen Commit-Strategie

```powershell
# Konfigurieren der automatischen Commit-Strategie
Set-AutoCommitStrategy -Interval "15m" -MinChanges 5 -GroupChanges $true -CommitOnSave $true
```

### 3. Aktivierung der VS Code-Integration

```powershell
# Aktivieren der VS Code-Integration
Enable-VSCodeIntegration
```

### 4. Manuelles Auslösen eines automatischen Commits

```powershell
# Manuelles Auslösen eines automatischen Commits
Invoke-AutoCommit -Path $PWD
```

## Best Practices

### 1. Commit-Intervall

- Wählen Sie ein Intervall, das zu Ihrem Arbeitsfluss passt
- Zu häufige Commits können die Entwicklungshistorie unübersichtlich machen
- Zu seltene Commits können zu Datenverlust führen

### 2. Commit-Nachrichten

- Überprüfen Sie die automatisch generierten Commit-Nachrichten
- Passen Sie die Nachrichtenvorlage an Ihre Bedürfnisse an
- Verwenden Sie aussagekräftige Commit-Typen

### 3. VS Code-Integration

- Nutzen Sie die Tastenkombinationen für effizientes Arbeiten
- Konfigurieren Sie die VS Code-Einstellungen nach Ihren Vorlieben
- Verwenden Sie die Statusleiste für schnelles Feedback

## Fehlerbehebung

### 1. Automatische Commits werden nicht erstellt

- Überprüfen Sie, ob `AutoCommit` in den Repository-Einstellungen aktiviert ist
- Überprüfen Sie das konfigurierte Intervall
- Überprüfen Sie, ob genügend Änderungen für einen Commit vorliegen

### 2. VS Code-Integration funktioniert nicht

- Überprüfen Sie, ob `EnableExtension` in den VS Code-Einstellungen aktiviert ist
- Überprüfen Sie, ob die VS Code-Einstellungen korrekt sind
- Starten Sie VS Code neu

### 3. Commit-Nachrichten sind nicht wie erwartet

- Überprüfen Sie die Nachrichtenvorlage
- Überprüfen Sie die konfigurierten Commit-Typen
- Überprüfen Sie die Gruppierungseinstellungen

## Roadmap

Die Git Commit Auto Strategie wird kontinuierlich weiterentwickelt:

### 1. MVP-Phase (Aktuell)

- Grundlegende automatische Commits
- VS Code-Integration
- Intelligente Commit-Nachrichten

### 2. Erweiterungsphase

- Verbesserte Analyse von Dateiänderungen
- Erweiterte Konfliktlösung
- Unterstützung für mehrere Repositories

### 3. Integrationsphase

- Tiefere Integration mit anderen MINTYhive-Agenten
- Integration mit CI/CD-Pipelines
- Erweiterte Berichterstattung

### 4. KI-Phase

- KI-gestützte Commit-Nachrichten
- Vorhersage von Konflikten
- Automatische Code-Qualitätsverbesserungen

## Fazit

Die Git Commit Auto Strategie bietet eine leistungsstarke Lösung für die automatisierte Versionskontrolle. Durch die Integration in VS Code und die intelligente Generierung von Commit-Nachrichten wird der manuelle Aufwand reduziert und die Qualität der Versionskontrolle verbessert.
