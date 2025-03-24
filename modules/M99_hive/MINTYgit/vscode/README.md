# MINTYgit VS Code Extension

Diese VS Code-Erweiterung integriert den MINTYgit-Agent in Visual Studio Code und ermöglicht eine nahtlose Versionskontrolle mit automatischen Commits.

## Funktionen

- **Automatische Commits**: Automatische Erstellung von Commits basierend auf definierten Regeln
- **Intelligente Commit-Nachrichten**: Generierung von Commit-Nachrichten basierend auf Änderungen
- **Statusleiste**: Anzeige des aktuellen Branches und Status in der Statusleiste
- **Tastenkombinationen**: Schneller Zugriff auf Git-Operationen
- **Branch-Verwaltung**: Einfache Erstellung und Verwaltung von Branches
- **Merge-Unterstützung**: Unterstützung bei der Zusammenführung von Branches

## Installation

1. Kopieren Sie den Inhalt des `vscode`-Verzeichnisses in ein neues VS Code-Erweiterungsprojekt
2. Führen Sie `npm install` aus, um die Abhängigkeiten zu installieren
3. Führen Sie `npm run compile` aus, um die Erweiterung zu kompilieren
4. Drücken Sie F5, um die Erweiterung im Debug-Modus zu starten

## Verwendung

### Tastenkombinationen

- `Ctrl+Alt+C`: Commit erstellen
- `Ctrl+Alt+P`: Push durchführen
- `Ctrl+Alt+L`: Pull durchführen
- `Ctrl+Alt+A`: Automatischen Commit auslösen

### Befehle

Die folgenden Befehle sind über die Befehlspalette (F1) verfügbar:

- `MINTYgit: Commit`: Erstellt einen Commit
- `MINTYgit: Push`: Führt einen Push durch
- `MINTYgit: Pull`: Führt einen Pull durch
- `MINTYgit: Auto-Commit`: Löst einen automatischen Commit aus
- `MINTYgit: Enable Auto-Commit`: Aktiviert automatische Commits
- `MINTYgit: Disable Auto-Commit`: Deaktiviert automatische Commits
- `MINTYgit: Show History`: Zeigt die Entwicklungshistorie an
- `MINTYgit: Create Branch`: Erstellt einen neuen Branch
- `MINTYgit: Switch Branch`: Wechselt zu einem Branch
- `MINTYgit: Merge Branch`: Führt Branches zusammen

### Einstellungen

Die Erweiterung kann über die VS Code-Einstellungen konfiguriert werden:

- `mintygit.enabled`: Aktiviert oder deaktiviert die Erweiterung
- `mintygit.autoCommit`: Aktiviert oder deaktiviert automatische Commits
- `mintygit.commitOnSave`: Erstellt einen Commit bei jedem Speichern
- `mintygit.showNotifications`: Zeigt Benachrichtigungen an
- `mintygit.statusBarIntegration`: Zeigt Informationen in der Statusleiste an
- `mintygit.autoCommitInterval`: Intervall für automatische Commits (z.B. "15m", "1h")
- `mintygit.minChangesForCommit`: Minimale Anzahl an Änderungen für einen automatischen Commit
- `mintygit.groupSimilarChanges`: Gruppiert ähnliche Änderungen in Commit-Nachrichten
- `mintygit.includeFileList`: Fügt eine Liste der geänderten Dateien in die Commit-Nachricht ein
- `mintygit.maxFilesInMessage`: Maximale Anzahl der Dateien in der Commit-Nachricht
- `mintygit.autoCommitDelay`: Verzögerung für automatische Commits nach Dateiänderungen
- `mintygit.suggestCommitMessages`: Schlägt Commit-Nachrichten basierend auf Änderungen vor

## Anforderungen

- Visual Studio Code 1.60.0 oder höher
- Git muss installiert und im PATH verfügbar sein
- PowerShell muss installiert sein

## Bekannte Probleme

- Die Erweiterung ist noch in der Entwicklung und kann instabil sein
- Die automatische Konfliktlösung ist noch nicht vollständig implementiert
- Die Integration mit anderen MINTYhive-Agenten ist noch in Arbeit

## Roadmap

1. **MVP-Phase (Aktuell)**: Grundlegende automatische Commits und VS Code-Integration
2. **Erweiterungsphase**: Verbesserte Analyse von Dateiänderungen und erweiterte Konfliktlösung
3. **Integrationsphase**: Tiefere Integration mit anderen MINTYhive-Agenten
4. **KI-Phase**: KI-gestützte Commit-Nachrichten und Vorhersage von Konflikten

## Mitwirken

Beiträge sind willkommen! Bitte erstellen Sie einen Pull Request oder ein Issue, wenn Sie Verbesserungsvorschläge haben.

## Lizenz

Diese Erweiterung ist unter der MIT-Lizenz lizenziert.
