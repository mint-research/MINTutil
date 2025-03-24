# MINTYmanager

MINTYmanager ist der zentrale Management-Agent im Hive-System, der für die Verwaltung von Roadmap, Backlog und Task-Listen verantwortlich ist.

## Verantwortlichkeiten

- Verwaltet Roadmap, Backlog und Task-Listen
- Koordiniert die Planung und Priorisierung von Aufgaben
- Überwacht den Fortschritt und Status von Aufgaben
- Prüft proaktiv die Verfügbarkeit benötigter Fähigkeiten im System
- Initiiert die Entwicklung neuer Fähigkeiten oder die Erweiterung bestehender Agenten
- Stimmt mit dem Benutzer ab, ob ein bestehendes Agentenprofil erweitert oder ein neuer Agent entwickelt werden soll

## Zeitplan

- **Continuous**: Ja
- **Reevaluierungs-Intervall**: 10s
- **Koordinations-Fenster**: 200ms
- **Passt andere Zeitpläne an**: Nein

## Schnittstellen

- **MINTYhive**: Sendet Anfragen zur Verfügbarkeit von Fähigkeiten, empfängt Status-Updates
- **Alle Agents**: Sendet Aufgaben, empfängt Status-Updates
- **MINTYlogger**: Sendet Management-Daten, empfängt Verlaufsinformationen
- **Externe Systeme**: Optional: synchronisiert mit externen Projektmanagement-Tools

## Komponenten

### ManagerManager.ps1

Die Hauptkomponente des MINTYmanager-Agents, die folgende Funktionen bereitstellt:

- `Initialize-ManagerManager`: Initialisiert den Manager Manager
- `Get-Roadmap`: Ruft die aktuelle Roadmap ab
- `Get-Backlog`: Ruft das aktuelle Backlog ab
- `Get-TaskList`: Ruft die aktuelle Task-Liste ab
- `Add-RoadmapItem`: Fügt ein neues Item zur Roadmap hinzu
- `Add-BacklogItem`: Fügt ein neues Item zum Backlog hinzu
- `Add-TaskItem`: Fügt eine neue Aufgabe zur Task-Liste hinzu
- `Update-ItemStatus`: Aktualisiert den Status eines Items
- `Check-CapabilityAvailability`: Prüft die Verfügbarkeit einer Fähigkeit im System
- `Request-CapabilityDevelopment`: Fordert die Entwicklung einer neuen Fähigkeit an
- `Coordinate-AgentExtension`: Koordiniert die Erweiterung eines bestehenden Agenten
- `Coordinate-NewAgentDevelopment`: Koordiniert die Entwicklung eines neuen Agenten

## Konfiguration

Die Konfiguration des MINTYmanager-Agents erfolgt über die Datei `config/manager_config.json`. Diese enthält:

- **Roadmap**: Konfiguration der Roadmap
- **Backlog**: Konfiguration des Backlogs
- **TaskList**: Konfiguration der Task-Liste
- **CapabilityChecking**: Konfiguration der Fähigkeitsprüfung
- **Interfaces**: Konfiguration der Schnittstellen zu anderen Agenten

## Proaktive Fähigkeitsentwicklung

MINTYmanager implementiert einen proaktiven Ansatz zur Fähigkeitsentwicklung:

1. Bei der Planung neuer Features oder Aufgaben prüft MINTYmanager frühzeitig, ob alle benötigten Fähigkeiten im System verfügbar sind
2. Wenn eine Fähigkeit fehlt, wird geprüft, ob sie in das Portfolio eines bestehenden Agenten passt
3. In Abstimmung mit dem Benutzer wird entschieden, ob das Profil eines bestehenden Agenten erweitert oder ein neuer Agent entwickelt wird
4. MINTYmanager koordiniert dann die Entwicklung oder Erweiterung der Fähigkeit mit MINTYhive

Dieser Ansatz stellt sicher, dass das System immer über alle benötigten Fähigkeiten verfügt, bevor sie tatsächlich benötigt werden, und reduziert so Verzögerungen und Engpässe im Entwicklungsprozess.
