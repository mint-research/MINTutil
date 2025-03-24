# MINTYgit

MINTYgit ist der Versionierungsagent des MINTYhive-Systems. Er ist verantwortlich für die Versionskontrolle, das Branching und das Merging von Codeänderungen. Als MVP (Minimal Viable Product) bietet MINTYgit eine automatisierte Git-Commit-Strategie über VS Code-Integration.

## Funktionen

- **Versionskontrolle**: Verwaltet Versionen von Dateien und Verzeichnissen
- **Branching**: Erstellt und verwaltet Branches für parallele Entwicklung
- **Merging**: Führt Änderungen aus verschiedenen Branches zusammen
- **Konfliktlösung**: Erkennt und löst Konflikte bei Merges
- **Historienanalyse**: Analysiert die Entwicklungshistorie
- **Automatische Commits**: Führt automatische Commits basierend auf definierten Regeln durch
- **VS Code-Integration**: Nahtlose Integration in die VS Code-Entwicklungsumgebung
- **Commit-Konventionen**: Erzwingt einheitliche Commit-Nachrichten nach definierten Standards
- **Git Commit Strategie**: Implementiert eine strukturierte Strategie für Snapshots, Branches und Änderungsdokumentation

## Komponenten

- **GitManager**: Hauptkomponente für die Git-Operationen
- **CommitManager**: Verwaltet automatische Commits und Commit-Nachrichten
- **BranchManager**: Verwaltet Branches und deren Beziehungen
- **MergeManager**: Führt Merges durch und löst Konflikte
- **HistoryAnalyzer**: Analysiert die Entwicklungshistorie
- **VSCodeIntegration**: Integriert MINTYgit in VS Code
- **GitCommitStrategy**: Implementiert die Git Commit Strategie

## Automatische Commit-Strategie

MINTYgit implementiert eine automatische Commit-Strategie, die folgende Aspekte umfasst:

1. **Ereignisbasierte Commits**: Automatische Commits werden durch definierte Ereignisse ausgelöst:
   - Zeitintervalle (z.B. alle 15 Minuten)
   - Dateiänderungen (z.B. nach X geänderten Dateien)
   - Speicherereignisse in VS Code
   - Bestimmte Aktionen (z.B. Tests, Builds)

2. **Intelligente Commit-Nachrichten**: Automatische Generierung von Commit-Nachrichten basierend auf:
   - Art der Änderungen (neue Dateien, Änderungen, Löschungen)
   - Betroffene Komponenten/Module
   - Konventionelles Commit-Format (feat, fix, docs, etc.)

3. **Gruppierung von Änderungen**: Zusammenfassung ähnlicher Änderungen in logischen Gruppen

4. **Konfigurierbare Regeln**: Anpassbare Regeln für verschiedene Projekttypen und Workflows

## Git Commit Strategie

MINTYgit implementiert eine strukturierte Git Commit Strategie, die folgende Aspekte umfasst:

1. **Snapshot-Typen**: Definierte Arten von Snapshots für verschiedene Entwicklungsphasen:
   - **Pretest**: Vor Testläufen, Debugging oder riskanten Eingriffen
   - **Posttest**: Nach erfolgreichem Test und Optimierung
   - **Checkpoint**: Manueller Zwischenstand zur Absicherung
   - **Prerisk**: Vor potenziell destruktiven Änderungen
   - **Session**: Start oder Ende einer Coding-Session
   - **Stable**: Getestetes, dokumentiertes und abgeschlossenes Feature

2. **Branch-Typen**: Standardisierte Branch-Typen mit definierten Namenskonventionen:
   - **Main**: Produktionsstand
   - **Dev**: Laufende Entwicklung
   - **Agent**: Temporäre Agent-Branches
   - **Review**: Review-Branches
   - **Fallback**: Rücksprungpunkte
   - **Stable**: Getestete Features
   - **Archive**: Langzeitarchiv

3. **Change-Dokumentation**: Standardisiertes Format für die Dokumentation von Änderungen

4. **Entwicklungs-Workflow**: Definierter Workflow für die Entwicklung und Bereitstellung

5. **Umgebungsvariablen-Handling**: Regeln für den Umgang mit Umgebungsvariablen

Weitere Details zur Git Commit Strategie finden Sie in der Datei `docs/GitCommitStrategy.md`.

## Konfiguration

Die Konfiguration erfolgt über die Dateien `config/git_config.json` und `config/git_commit_strategy.json`. Folgende Einstellungen können angepasst werden:

### git_config.json

- **RepositorySettings**: Konfiguration des Repositories
  - `DefaultBranch`: Standard-Branch (z.B. "main")
  - `RemoteUrl`: URL des Remote-Repositories
  - `LocalPath`: Lokaler Pfad des Repositories
  - `AutoCommit`: Aktivierung automatischer Commits
  - `AutoPush`: Aktivierung automatischer Pushes

- **BranchSettings**: Konfiguration der Branches
  - `NamingConvention`: Namenskonvention für Branches
  - `RequireDescription`: Erfordert eine Beschreibung für neue Branches
  - `RequireIssueReference`: Erfordert eine Issue-Referenz für neue Branches

- **CommitSettings**: Konfiguration der Commits
  - `MessageTemplate`: Template für Commit-Nachrichten
  - `CommitTypes`: Gültige Commit-Typen (feat, fix, docs, etc.)
  - `AutoCommitInterval`: Intervall für automatische Commits
  - `MinChangesForCommit`: Minimale Anzahl an Änderungen für einen Commit
  - `GroupSimilarChanges`: Gruppierung ähnlicher Änderungen

- **MergeSettings**: Konfiguration der Merges
  - `RequireReview`: Erfordert ein Review vor dem Merge
  - `AutoResolveConflicts`: Automatische Konfliktlösung
  - `PreferSource`: Bevorzugt Quell-Änderungen bei Konflikten
  - `PreferTarget`: Bevorzugt Ziel-Änderungen bei Konflikten

- **HistorySettings**: Konfiguration der Historienanalyse
  - `MaxHistoryDepth`: Maximale Tiefe der Historienanalyse
  - `IncludeCommitMessages`: Einbeziehung von Commit-Nachrichten
  - `IncludeFileChanges`: Einbeziehung von Dateiänderungen
  - `IncludeAuthors`: Einbeziehung von Autoren

- **VSCodeSettings**: Konfiguration der VS Code-Integration
  - `EnableExtension`: Aktivierung der VS Code-Erweiterung
  - `CommitOnSave`: Commit bei Speichern
  - `ShowNotifications`: Anzeige von Benachrichtigungen
  - `StatusBarIntegration`: Integration in die Statusleiste

### git_commit_strategy.json

- **snapshot_types**: Konfiguration der Snapshot-Typen
- **branch_types**: Konfiguration der Branch-Typen
- **change_doc_format**: Konfiguration des Change-Dokument-Formats
- **commit_rules**: Konfiguration der Commit-Regeln
- **cleanup_rules**: Konfiguration der Cleanup-Regeln
- **dev_prod_flow**: Konfiguration des Entwicklungs-Workflows
- **env_handling**: Konfiguration des Umgebungsvariablen-Handlings

## Verwendung

### Automatische Commit-Strategie

```powershell
# Importieren des Moduls
Import-Module .\src\MINTYgit.ps1

# Initialisieren des Versionierungsagenten
Initialize-VersionControl

# Konfigurieren der automatischen Commit-Strategie
Set-AutoCommitStrategy -Interval "15m" -MinChanges 5 -GroupChanges $true

# Aktivieren der VS Code-Integration
Enable-VSCodeIntegration

# Manuelles Erstellen eines neuen Branches
New-Branch -Name "feature/new-feature" -Description "Eine neue Funktion" -IssueReference "ISSUE-123"

# Wechseln zu einem Branch
Switch-Branch -Name "feature/new-feature"

# Manuelles Erstellen eines Commits
New-GitCommit -Path $PWD -Message "Neue Funktion implementiert" -Type "feat"

# Zusammenführen von Branches
Merge-Branch -Source "feature/new-feature" -Target "main" -Message "Implementiere neue Funktion"
```

Weitere Beispiele finden Sie in der Datei `examples/git_usage.ps1`.

### Git Commit Strategie

```powershell
# Importieren des Moduls
Import-Module .\src\MINTYgit.ps1

# Initialisieren des Versionierungsagenten
Initialize-VersionControl

# Erstellen eines Pretest-Snapshots
New-GitSnapshot -Type "pretest" -Context "initial-test"

# Erstellen eines Branches
New-GitBranch -Type "feature" -Context "new-feature"

# Erstellen eines Change-Dokuments
New-ChangeDoc -Type "feature" -Scope "example" -Reason "Beispiel für die Git Commit Strategie"

# Überprüfen der Commit-Regeln
Test-CommitRules

# Zusammenführen von Branches
Merge-GitBranch -Source "feature/new-feature" -Target "main"
```

Weitere Beispiele finden Sie in der Datei `examples/git_commit_strategy_usage.ps1`.

## VS Code-Integration

Die VS Code-Integration bietet folgende Funktionen:

1. **Statusleiste**: Anzeige des aktuellen Branches und Status
2. **Automatische Commits**: Konfigurierbare automatische Commits
3. **Commit-Vorschläge**: Intelligente Vorschläge für Commit-Nachrichten
4. **Branch-Verwaltung**: Einfache Erstellung und Verwaltung von Branches
5. **Konfliktlösung**: Unterstützung bei der Lösung von Merge-Konflikten

## Integration mit anderen Agenten

MINTYgit integriert sich mit anderen Agenten des MINTYhive-Systems:

- **MINTYcoder**: Automatische Commits bei Codeänderungen
- **MINTYtester**: Automatische Commits bei erfolgreichen Tests
- **MINTYupdater**: Versionsverwaltung bei Updates
- **MINTYhive**: Zentrale Steuerung und Überwachung
- **MINTYlogger**: Protokollierung von Git-Aktivitäten

## Dokumentation

- **README.md**: Allgemeine Dokumentation
- **docs/GitCommitAutoStrategy.md**: Dokumentation der automatischen Commit-Strategie
- **docs/GitCommitStrategy.md**: Dokumentation der Git Commit Strategie
- **docs/Installation.md**: Installationsanleitung
- **examples/git_usage.ps1**: Beispiel für die Verwendung der automatischen Commit-Strategie
- **examples/git_commit_strategy_usage.ps1**: Beispiel für die Verwendung der Git Commit Strategie

## Roadmap

1. **MVP-Phase (Aktuell)**: Grundlegende Git-Funktionen, VS Code-Integration und Git Commit Strategie
2. **Erweiterungsphase**: Erweiterte automatische Commit-Strategien und Konfliktlösung
3. **Integrationsphase**: Tiefere Integration mit anderen MINTYhive-Agenten
4. **KI-Phase**: KI-gestützte Commit-Nachrichten und Konfliktlösung
