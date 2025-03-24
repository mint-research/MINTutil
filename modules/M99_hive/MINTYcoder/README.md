# MINTYcoder

MINTYcoder ist der Code-Agent des MINTYhive-Systems. Er ist verantwortlich für die Codegenerierung, Codeanalyse und Codeoptimierung.

## Funktionen

- **Codegenerierung**: Generiert Code basierend auf Anforderungen und Vorlagen
- **Codeanalyse**: Analysiert Code und identifiziert Probleme und Verbesserungsmöglichkeiten
- **Codeoptimierung**: Optimiert Code für bessere Leistung und Lesbarkeit
- **Refactoring**: Führt Refactoring-Operationen durch, um die Codequalität zu verbessern
- **Dokumentation**: Generiert Dokumentation für Code

## Komponenten

- **CodeGenerator**: Generiert Code basierend auf Anforderungen und Vorlagen
- **CodeAnalyzer**: Analysiert Code und identifiziert Probleme und Verbesserungsmöglichkeiten
- **CodeOptimizer**: Optimiert Code für bessere Leistung und Lesbarkeit
- **Refactorer**: Führt Refactoring-Operationen durch
- **DocumentationGenerator**: Generiert Dokumentation für Code

## Konfiguration

Die Konfiguration erfolgt über die Datei `config/coder_config.json`. Folgende Einstellungen können angepasst werden:

- **GenerationSettings**: Konfiguration der Codegenerierung
- **AnalysisSettings**: Konfiguration der Codeanalyse
- **OptimizationSettings**: Konfiguration der Codeoptimierung
- **RefactoringSettings**: Konfiguration des Refactorings
- **DocumentationSettings**: Konfiguration der Dokumentationsgenerierung

## Verwendung

```powershell
# Importieren des Moduls
Import-Module .\src\MINTYcoder.ps1

# Initialisieren des Code-Agents
Initialize-Coder

# Generieren von Code
New-Code -Template "Function" -Name "Get-Data" -Parameters @("Path", "Filter") -OutputPath "path/to/output.ps1"

# Analysieren von Code
Get-CodeAnalysis -Path "path/to/code.ps1" -Rules "All"

# Optimieren von Code
Optimize-Code -Path "path/to/code.ps1" -OutputPath "path/to/optimized.ps1"

# Refactoring durchführen
Invoke-Refactoring -Path "path/to/code.ps1" -Operation "ExtractMethod" -OutputPath "path/to/refactored.ps1"

# Dokumentation generieren
New-Documentation -Path "path/to/code.ps1" -OutputPath "path/to/docs.md"
```

Weitere Beispiele finden Sie in der Datei `examples/coder_usage.ps1`.

## Integration mit anderen Agenten

MINTYcoder integriert sich mit anderen Agenten des MINTYhive-Systems, um eine nahtlose Codegenerierung und -analyse zu ermöglichen. Andere Agenten können die Codefunktionen nutzen, um ihre Aufgaben zu erfüllen.
