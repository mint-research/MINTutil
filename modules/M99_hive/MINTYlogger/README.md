# MINTYlogger

MINTYlogger ist der Logging-Agent des MINTYhive-Systems. Er ist verantwortlich für die zentrale Protokollierung, Metrikerfassung und Optimierung der Systemressourcen.

## Funktionen

- **Zentrales Logging**: Sammelt und speichert Protokolldaten von allen Agenten
- **Metrikerfassung**: Erfasst Leistungs- und Nutzungsmetriken
- **Kontextüberwachung**: Überwacht den Kontext und optimiert die Ressourcennutzung
- **Optimierung**: Optimiert die Systemleistung basierend auf gesammelten Metriken
- **MCP-Integration**: Stellt Logging-Funktionen über das Model Context Protocol bereit

## Komponenten

- **Logger**: Hauptkomponente für die Protokollierung
- **MetricsCollector**: Sammelt und analysiert Systemmetriken
- **ContextMonitor**: Überwacht den Kontext und optimiert die Ressourcennutzung
- **Optimizer**: Optimiert die Systemleistung

## Konfiguration

Die Konfiguration erfolgt über die Datei `config/logger_config.json`. Folgende Einstellungen können angepasst werden:

- **LoggingSettings**: Konfiguration der Protokollierung
- **MetricsSettings**: Konfiguration der Metrikerfassung
- **OptimizationSettings**: Konfiguration der Optimierung
- **ContextMonitorSettings**: Konfiguration der Kontextüberwachung
- **IntegrationSettings**: Konfiguration der MCP-Integration

## Verwendung

```powershell
# Importieren des Moduls
Import-Module .\src\MINTYLoggingAgent.psm1

# Initialisieren des Loggers
Initialize-Logger

# Protokollieren einer Nachricht
Write-Log -Level "Info" -Message "Dies ist eine Testmeldung"

# Erfassen von Metriken
Collect-Metrics

# Optimieren der Systemleistung
Optimize-System
```

Weitere Beispiele finden Sie in der Datei `examples/Example-Usage.ps1`.

## Integration mit anderen Agenten

MINTYlogger integriert sich mit anderen Agenten des MINTYhive-Systems, um eine zentrale Protokollierung und Metrikerfassung zu ermöglichen. Andere Agenten können die Logging-Funktionen über das MCP-Protokoll nutzen.
