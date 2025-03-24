# Git Commit Strategie

Diese Dokumentation beschreibt die Git Commit Strategie, die vom MINTYgit-Agent implementiert wird. Die Strategie definiert Regeln und Workflows für die Versionskontrolle und stellt sicher, dass alle Änderungen ordnungsgemäß dokumentiert und nachvollziehbar sind.

## Übersicht

Die Git Commit Strategie umfasst folgende Hauptkomponenten:

1. **Snapshot-Typen**: Definierte Arten von Snapshots für verschiedene Entwicklungsphasen
2. **Branch-Typen**: Standardisierte Branch-Typen mit definierten Namenskonventionen
3. **Change-Dokumentation**: Format für die Dokumentation von Änderungen
4. **Commit-Regeln**: Regeln für die Erstellung von Commits
5. **Cleanup-Regeln**: Regeln für die Bereinigung von temporären Branches und Snapshots
6. **Entwicklungs-Workflow**: Definierter Workflow für die Entwicklung und Bereitstellung
7. **Umgebungsvariablen-Handling**: Regeln für den Umgang mit Umgebungsvariablen

## Snapshot-Typen

Snapshots sind Momentaufnahmen des Repositories zu bestimmten Zeitpunkten. Sie werden als Tags oder Branches gespeichert und dienen der Dokumentation und Nachvollziehbarkeit.

### Pretest

- **Beschreibung**: Sichert den aktuellen Zustand vor Testläufen, Debugging oder riskanten Eingriffen.
- **Namenskonvention**: `pretest-<yyyyMMdd>-<context>`
- **Branch**: Nein
- **Erforderlich**: Ja

### Posttest

- **Beschreibung**: Markiert den Zustand nach erfolgreichem Test und Optimierung. Commit-pflichtig.
- **Namenskonvention**: `posttest-<yyyyMMdd>-<context>`
- **Branch**: Nein
- **Erforderlich**: Ja
- **Erfordert README.md und .gitignore**: Ja

### Checkpoint

- **Beschreibung**: Manueller Zwischenstand zur Absicherung.
- **Namenskonvention**: `checkpoint-<yyyyMMdd>-<context>`
- **Branch**: Nein
- **Erforderlich**: Nein

### Prerisk

- **Beschreibung**: Snapshot vor potenziell destruktiven oder großflächigen Änderungen.
- **Namenskonvention**: `prerisk-<yyyyMMdd>-<context>`
- **Branch**: Ja
- **Erforderlich**: Ja

### Session

- **Beschreibung**: Start oder Ende einer Coding-Session.
- **Namenskonvention**: `session-<yyyyMMdd>-<start|end>`
- **Branch**: Ja
- **Erforderlich**: Ja

### Stable

- **Beschreibung**: Snapshot eines getesteten, dokumentierten und abgeschlossenen Features.
- **Namenskonvention**: `stable-<yyyyMMdd>-<feature>`
- **Branch**: Ja
- **Erforderlich**: Nein

## Branch-Typen

Branches sind parallele Entwicklungslinien, die für verschiedene Zwecke verwendet werden. Die Strategie definiert standardisierte Branch-Typen mit definierten Namenskonventionen.

### Main

- **Beschreibung**: Produktionsstand. Nur getestete, reviewte und dokumentierte Änderungen.
- **Schreibgeschützt**: Ja

### Dev

- **Beschreibung**: Laufende Entwicklung und Agenten-Eingriffe.
- **Schreibgeschützt**: Nein

### Agent

- **Beschreibung**: Temporäre Agent-Branches pro Session oder Task.
- **Namenskonvention**: `agent/<yyyyMMdd>-<session>`
- **Schreibgeschützt**: Nein

### Review

- **Beschreibung**: Manuelle Review-Branches mit Snapshots zur Abnahme.
- **Namenskonvention**: `review/<yyyyMMdd>-<topic>`
- **Schreibgeschützt**: Nein

### Fallback

- **Beschreibung**: Rücksprungpunkte bei risikobehafteten Eingriffen.
- **Namenskonvention**: `fallback/<yyyyMMdd>-<reason>`
- **Schreibgeschützt**: Nein

### Stable

- **Beschreibung**: Branch für getestete Features vor Merge nach main.
- **Namenskonvention**: `stable/<yyyyMMdd>-<feature>`
- **Schreibgeschützt**: Nein

### Archive

- **Beschreibung**: Langzeitarchiv für verwaiste oder veraltete Änderungen.
- **Namenskonvention**: `archive/<yyyyMMdd>-<context>`
- **Schreibgeschützt**: Ja

## Change-Dokumentation

Änderungen werden in Change-Dokumenten dokumentiert, die in einem standardisierten Format erstellt werden. Diese Dokumente werden im Verzeichnis `changes/` gespeichert und dienen der Nachvollziehbarkeit von Änderungen.

### Struktur

Die Change-Dokumente haben folgende Struktur:

- **@type**: Der Typ der Änderung
- **@scope**: Der Umfang der Änderung
- **@status**: Der Status der Änderung
- **@reason**: Der Grund für die Änderung
- **@result**: Das Ergebnis der Änderung
- **@review**: Die Review-Informationen
- **@linked**: Verknüpfte Informationen
- **@branch**: Der Branch, auf dem die Änderung durchgeführt wurde
- **@readme**: Informationen zur README.md
- **@gitignore**: Informationen zur .gitignore
- **@env**: Informationen zur Umgebungskonfiguration

### Erforderliche Felder

Folgende Felder sind für alle Change-Dokumente erforderlich:

- **@type**: Der Typ der Änderung
- **@scope**: Der Umfang der Änderung
- **@reason**: Der Grund für die Änderung

### Erforderliche Felder für Posttest

Folgende zusätzliche Felder sind für Posttest-Change-Dokumente erforderlich:

- **@status**: Der Status der Änderung
- **@review**: Die Review-Informationen
- **@result**: Das Ergebnis der Änderung
- **@readme**: Informationen zur README.md
- **@gitignore**: Informationen zur .gitignore

## Commit-Regeln

Commits müssen bestimmte Regeln erfüllen, um sicherzustellen, dass alle Änderungen ordnungsgemäß dokumentiert und nachvollziehbar sind.

### Vorbedingungen

- README.md muss aktualisiert und korrekt sein
- .gitignore muss neue oder ignorierte Dateien enthalten
- TEMP-Ordner muss in .gitignore ausgeschlossen sein
- Änderungen müssen in CHANGELOG oder changes/*.md dokumentiert sein
- Nur posttest-verifizierte Änderungen dürfen in dev committed oder nach main gemerged werden

## Cleanup-Regeln

Temporäre Branches und Snapshots werden nach bestimmten Regeln bereinigt, um das Repository übersichtlich zu halten.

### Micro

- **Aufbewahrungsdauer**: 1 Tag
- **Automatisches Löschen**: Ja

### Checkpoint

- **Aufbewahrungsdauer**: 3 Tage
- **Automatisches Löschen**: Ja

### Session

- **Aufbewahrungsdauer**: 7 Tage
- **Automatisches Löschen**: Ja

### Prerisk

- **Aufbewahrung bis Merge**: Ja
- **Automatisches Löschen nach**: 14 Tage

### Review

- **Löschen nach Merge**: Ja

### Agent

- **Aufbewahrungsdauer**: 3 Tage
- **Automatisches Löschen**: Ja

### Stable

- **Aufbewahrung für immer**: Ja

### Archive

- **Aufbewahrung für immer**: Ja

## Entwicklungs-Workflow

Der Entwicklungs-Workflow definiert, wie Änderungen von der Entwicklung in die Produktion gelangen.

### Workflow

1. `agent/*` → `dev`
2. `dev` → `stable/<feature>`
3. `stable/<feature>` → `main` (post-review, post-test, post-doc)

### Hauptschutz

- **Main-Branch-Schutz**: Ja
- **Dev-Isolation**: Ja

### Merge-Regeln

Folgende Regeln müssen für Merges nach `main` erfüllt sein:

- Änderung muss posttest-verifiziert sein
- README.md und .gitignore müssen aktualisiert sein
- TEMP-Ordner muss ausgeschlossen sein
- ChangeDoc muss vollständig sein
- Stable-Snapshot muss existieren

## Umgebungsvariablen-Handling

Umgebungsvariablen werden nach bestimmten Regeln behandelt, um sicherzustellen, dass keine sensiblen Informationen in das Repository gelangen.

### Regeln

- .env-Dateien müssen in .gitignore enthalten sein
- .env darf niemals committed, gesnapshotet oder in Branches übernommen werden
- Falls Konfiguration dokumentiert werden muss → Beispieldatei nutzen
- Beispiel-Dateiname: .env.example (keine sensitiven Inhalte)
- Pfad/Struktur von .env-Dateien wird im README.md erklärt
- Der Ordner \TEMP\ im Root muss ebenfalls ausgeschlossen werden

### Erforderliche .gitignore-Einträge

- .env
- .env.local
- .env.*
- *.env
- /TEMP/
- TEMP/

### README.md-Hinweis

"Bitte eigene Umgebungsvariablen in .env eintragen. Beispiel siehe .env.example. Diese Datei darf nicht committed werden. Der Ordner TEMP dient nur der temporären Laufzeitnutzung und darf nicht versioniert werden."

## Implementierung

Die Git Commit Strategie ist als PowerShell-Module implementiert und bietet folgende Funktionen:

### Initialize-GitCommitStrategy

Initialisiert die Git Commit Strategie und lädt die Konfiguration.

```powershell
Initialize-GitCommitStrategy
```

### New-GitSnapshot

Erstellt einen Snapshot des aktuellen Zustands.

```powershell
New-GitSnapshot -Type "pretest" -Context "initial-test"
New-GitSnapshot -Type "posttest" -Context "feature-complete"
```

### New-GitBranch

Erstellt einen Branch des angegebenen Typs.

```powershell
New-GitBranch -Type "feature" -Context "new-feature"
```

### New-ChangeDoc

Erstellt ein Change-Dokument für einen Commit.

```powershell
New-ChangeDoc -Type "feature" -Scope "example" -Reason "Beispiel für die Git Commit Strategie"
```

### Test-CommitRules

Überprüft, ob ein Commit die definierten Regeln erfüllt.

```powershell
Test-CommitRules
```

### Merge-GitBranch

Führt einen Merge von einem Branch in einen anderen durch.

```powershell
Merge-GitBranch -Source "feature/new-feature" -Target "main"
```

### New-GitCommit

Erstellt einen Commit mit der angegebenen Nachricht.

```powershell
New-GitCommit -Path $PWD -Message "Neue Funktion implementiert" -Type "feat"
New-GitCommit -Message "Silent commit" -Type "chore" -Silent
```

Der Parameter `-Silent` sorgt dafür, dass der Commit ohne Ausgabe erstellt wird. Dies ist besonders nützlich für automatische Commits im Dev-Branch.

Vor jedem Commit werden folgende Prüfungen durchgeführt:
- Existenz eines Git-Benutzers
- Existenz des angegebenen Pfades
- Gültigkeit des Git-Repositories
- Schreibzugriff auf das Repository

Im Silent-Modus werden diese Prüfungen ohne Ausgabe durchgeführt und bei Fehlern wird `$false` zurückgegeben. Im normalen Modus werden Fehlermeldungen ausgegeben und Ausnahmen ausgelöst.

### New-AutoCommit

Erstellt einen automatischen Commit basierend auf dem aktuellen Branch.

```powershell
New-AutoCommit -Message "Automatischer Commit"
```

Diese Funktion prüft, ob der aktuelle Branch automatische Commits unterstützt (über die Eigenschaft `auto_commit` in der Konfiguration) und erstellt einen Commit entsprechend. Wenn der Branch zusätzlich die Eigenschaft `silent_commits` auf `true` gesetzt hat, wird der Commit ohne Ausgabe erstellt.

Vor jedem automatischen Commit werden folgende Prüfungen durchgeführt:
- Existenz eines Git-Benutzers (mit Möglichkeit zur interaktiven Konfiguration)
- Existenz des angegebenen Pfades (mit Möglichkeit zur interaktiven Eingabe)
- Gültigkeit des Git-Repositories (mit Möglichkeit zur interaktiven Initialisierung)
- Schreibzugriff auf das Repository

Wenn der aktuelle Branch keine automatischen Commits unterstützt, wird der Benutzer gefragt, ob er trotzdem einen Commit erstellen möchte.

## Beispiel

Ein vollständiges Beispiel für die Verwendung der Git Commit Strategie finden Sie in der Datei `examples/git_commit_strategy_usage.ps1`.

## Fazit

Die Git Commit Strategie bietet einen strukturierten Ansatz für die Versionskontrolle und stellt sicher, dass alle Änderungen ordnungsgemäß dokumentiert und nachvollziehbar sind. Durch die Verwendung von standardisierten Snapshot- und Branch-Typen, Change-Dokumentation und definierten Workflows wird die Qualität und Nachvollziehbarkeit der Entwicklung verbessert.
