# MINTYtester

MINTYtester ist der Test-Agent des MINTYhive-Systems. Er ist verantwortlich für die Durchführung von Tests, die Validierung von Codeänderungen und die Qualitätssicherung.

## Funktionen

- **Automatisierte Tests**: Führt automatisierte Tests für verschiedene Komponenten durch
- **Testabdeckung**: Analysiert die Testabdeckung und identifiziert Lücken
- **Validierung**: Validiert Codeänderungen gegen definierte Regeln und Standards
- **Fehleranalyse**: Analysiert Fehler und schlägt Lösungen vor
- **Berichterstattung**: Erstellt Berichte über Testergebnisse

## Komponenten

- **TestRunner**: Führt Tests aus und sammelt Ergebnisse
- **CoverageAnalyzer**: Analysiert die Testabdeckung
- **Validator**: Validiert Code gegen Regeln und Standards
- **ErrorAnalyzer**: Analysiert Fehler und schlägt Lösungen vor
- **ReportGenerator**: Erstellt Berichte über Testergebnisse

## Konfiguration

Die Konfiguration erfolgt über die Datei `config/tester_config.json`. Folgende Einstellungen können angepasst werden:

- **TestSettings**: Konfiguration der Tests
- **CoverageSettings**: Konfiguration der Testabdeckungsanalyse
- **ValidationSettings**: Konfiguration der Validierung
- **ErrorAnalysisSettings**: Konfiguration der Fehleranalyse
- **ReportSettings**: Konfiguration der Berichterstattung

## Verwendung

```powershell
# Importieren des Moduls
Import-Module .\src\MINTYtester.ps1

# Initialisieren des Test-Agents
Initialize-Tester

# Ausführen von Tests
Run-Tests -Path "path/to/tests" -Filter "*.Tests.ps1"

# Analysieren der Testabdeckung
Get-TestCoverage -Path "path/to/code"

# Validieren von Code
Validate-Code -Path "path/to/code" -Rules "PSScriptAnalyzer"

# Generieren eines Berichts
New-TestReport -OutputPath "path/to/report.html"
```

Weitere Beispiele finden Sie in der Datei `examples/tester_usage.ps1`.

## Integration mit anderen Agenten

MINTYtester integriert sich mit anderen Agenten des MINTYhive-Systems, um eine nahtlose Qualitätssicherung zu ermöglichen. Andere Agenten können die Testfunktionen nutzen, um ihre Änderungen zu validieren und zu testen.
