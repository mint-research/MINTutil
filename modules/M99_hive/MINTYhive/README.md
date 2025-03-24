# MINTYhive

MINTYhive ist der zentrale Orchestrierungs-Agent im Hive-System, der alle anderen Agenten und ihre Interaktionen koordiniert.

## Verantwortlichkeiten

- Orchestriert alle Agenten und ihre Interaktionen
- Optimiert Koordination, Timing, Zuständigkeiten und Datenfluss
- Sorgt für minimale Latenz bei maximaler Relevanz der Kommunikation
- Implementiert Prinzip: 'Real-Time Information in exakt der richtigen Tiefe mit dem absoluten Minimum an Interaktionen'
- Überwacht den Systemzustand und passt Kommunikationspfade dynamisch an
- Erkennt, verhindert oder löst Redundanzen, Konflikte und Blockaden
- Stellt sicher, dass alle Aufgaben, Rollen und Agentenzuständigkeiten MECE sind (Mutually Exclusive, Collectively Exhaustive)
- Verwaltet Fähigkeiten aller Agenten und entwickelt proaktiv neue Fähigkeiten bei Bedarf

## Zeitplan

- **Continuous**: Ja
- **Reevaluierungs-Intervall**: 5s
- **Koordinations-Fenster**: 100ms
- **Passt andere Zeitpläne an**: Ja

## Schnittstellen

- **Alle Agents**: Empfängt Zustandsdaten, Timing-Informationen, Kontextwechsel
- **MINTYlogger**: Sendet Meta-Daten zur Koordination, empfängt Verlaufsinformationen
- **MINTYmanager**: Optionaler Kontroll- oder Feedbackkanal
- **Externe Systeme**: Optional: synchronisiert mit weiteren Hives oder Supervisors
## Komponenten

### HiveManager.ps1

Die Hauptkomponente des MINTYhive-Agents, die folgende Funktionen bereitstellt:

- `Initialize-HiveManager`: Initialisiert den Hive Manager
- `Invoke-AgentOrchestration`: Orchestriert alle Agenten und ihre Interaktionen
- `Orchestrate-SingleCycle`: Führt einen einzelnen Orchestrierungszyklus aus
- `Update-AgentStatus`: Aktualisiert den Status aller Agenten
- `Optimize-CommunicationPaths`: Optimiert die Kommunikationspfade zwischen Agenten
- `Resolve-AgentConflicts`: Erkennt und löst Konflikte zwischen Agenten
- `Distribute-AgentTasks`: Verteilt Aufgaben an Agenten
- `Monitor-SystemState`: Überwacht den Systemzustand
- `Test-CapabilityAvailability`: Prüft die Verfügbarkeit einer Fähigkeit im System
- `Find-BestAgentForCapability`: Findet den am besten geeigneten Agenten für eine neue Fähigkeit
- `Add-AgentCapability`: Fügt eine neue Fähigkeit zu einem Agenten hinzu
- `New-AgentForCapability`: Erstellt einen neuen Agenten für eine Fähigkeit
- `Develop-Capability`: Entwickelt eine neue Fähigkeit im System
- `Update-Capability`: Aktualisiert eine bestehende Fähigkeit
- `Process-CapabilityRequest`: Verarbeitet eine Anfrage zur Fähigkeitsprüfung von MINTYmanager
- `Monitor-SystemState`: Überwacht den Systemzustand

## Konfiguration

Die Konfiguration des MINTYhive-Agents erfolgt über die Datei `config/hive_config.json`. Diese enthält:

- **Agents**: Liste aller Agenten im System
- **Schedule**: Zeitplan für die Orchestrierung
- **Interfaces**: Konfiguration der Schnittstellen zu anderen Agenten
- **CommunicationPriorities**: Prioritäten für die Kommunikation zwischen Agenten
- **CapabilityManagement**: Konfiguration für die proaktive Fähigkeitsentwicklung

## Kommunikationspfade

MINTYhive verwaltet die Kommunikationspfade zwischen allen Agenten im System. Diese werden dynamisch basierend auf dem aktuellen Systemzustand optimiert, um eine effiziente und effektive Kommunikation zu gewährleisten.

Die Kommunikationspfade werden in einer Graphstruktur gespeichert, wobei jeder Agent sowohl Eingabe- als auch Ausgabepfade zu anderen Agenten haben kann. Die Prioritäten der Kommunikation werden basierend auf der Wichtigkeit der Agenten und ihrer aktuellen Aktivität festgelegt.

## Fähigkeitsmanagement

MINTYhive implementiert ein proaktives Fähigkeitsmanagement, das sicherstellt, dass alle für das Gesamtsystem benötigten Funktionen und Fähigkeiten rechtzeitig entwickelt werden:

1. **Fähigkeitsprüfung**: MINTYhive kann auf Anfrage von MINTYmanager prüfen, ob eine bestimmte Fähigkeit im System verfügbar ist
2. **Proaktive Entwicklung**: Wenn eine benötigte Fähigkeit nicht verfügbar ist, kann MINTYhive diese proaktiv entwickeln
3. **Agentenzuordnung**: MINTYhive analysiert, welcher bestehende Agent am besten für eine neue Fähigkeit geeignet ist oder ob ein neuer Agent erstellt werden sollte
4. **Benutzerabstimmung**: Bei Bedarf stimmt MINTYhive mit dem Benutzer ab, ob ein bestehendes Agentenprofil erweitert oder ein neuer Agent entwickelt werden soll
5. **Fähigkeitsaktualisierung**: MINTYhive kann bestehende Fähigkeiten auf den neuesten Stand bringen

Die Fähigkeiten aller Agenten werden in der Datei `data/capabilities.json` gespeichert und verwaltet. Diese enthält sowohl globale Fähigkeiten, die allen Agenten zur Verfügung stehen, als auch agenten-spezifische Fähigkeiten.

## MCP-Integration

MINTYhive ist als MCP-Server implementiert und stellt folgende Tools und Ressourcen bereit:

### Tools

- `orchestrate_agents`: Orchestriert alle Agenten und ihre Interaktionen
- `optimize_coordination`: Optimiert Koordination, Timing und Zuständigkeiten
- `monitor_system`: Überwacht den Systemzustand und passt Kommunikationspfade an
- `resolve_conflicts`: Erkennt und löst Redundanzen, Konflikte und Blockaden
- `check_capability`: Prüft die Verfügbarkeit einer Fähigkeit im System
- `develop_capability`: Entwickelt eine neue Fähigkeit proaktiv
- `update_capability`: Aktualisiert eine bestehende Fähigkeit

### Ressourcen

- `hive://agents`: Liste aller Agenten und ihr Status
- `hive://communication`: Kommunikationspfade zwischen Agenten
- `hive://metrics`: Systemweite Metriken und Leistungsdaten
- `hive://conflicts`: Aktuelle Konflikte und Lösungsstatus
- `hive://capabilities`: Liste aller verfügbaren Fähigkeiten im System
- `hive://capabilities/{agent}`: Liste der Fähigkeiten eines bestimmten Agenten
