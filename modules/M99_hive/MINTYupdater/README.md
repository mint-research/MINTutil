# MINTYupdater

MINTYupdater ist ein Agent im Hive-System, der für die rekursive Qualitätsvereinheitlichung und Synchronisierung von Artefakten, Formaten und Konventionen zuständig ist.

## Verantwortlichkeiten

- Führt rekursive Qualitätsvereinheitlichung durch
- Synchronisiert Artefakte, Formate und Konventionen systemweit
- Erkennt veraltete oder abweichende Komponenten
- Validiert gegen aktuelle Standards und Konventionen
- Unterscheidet zwei Betriebsmodi: Routine-Mode (geplant, zyklisch) und Trigger-Mode (reaktiv bei Änderung, Fehler oder Bedarf)
- Leitet bei Bedarf Korrekturaufträge an MINTYcleaner, Archivar oder Coder weiter

## Betriebsmodi

- **Routine**: Zyklische Überprüfung und Vereinheitlichung aller Komponenten gemäß festgelegtem Zeitplan
- **Trigger**: Sofortiger Abgleich und Update bei detektierten Änderungen, Konflikten oder neuen Standards

## Zeitplan

- **Routine**: Täglich 02:00 UTC
- **Trigger-Latenz**: Maximal 3s nach Erkennung
- **Cooldown**: 5min

## Schnittstellen

- **Archivar**: Empfängt aktuelle Standards und Templates
- **Coder**: Meldet Update-Bedarf an Artefakten
- **MINTYcleaner**: Delegiert bereinigungsnahe Aufgaben bei massiven Inkonsistenzen
- **Log**: Sendet durchgeführte Updates, empfängt Änderungsverläufe
- **Hive**: Meldet Systemstatus, erhält Prioritäts- und Routinghinweise

## Komponenten

### UpdaterManager.ps1

Die Hauptkomponente des MINTYupdater-Agents, die folgende Funktionen bereitstellt:

- `Initialize-UpdaterManager`: Initialisiert den MINTYupdater Manager
- `Invoke-QualityUnification`: Führt eine rekursive Qualitätsvereinheitlichung durch
- `Update-FileQuality`: Aktualisiert die Qualität einer Datei
- `Find-OutdatedComponents`: Erkennt veraltete oder abweichende Komponenten
- `Test-ComponentOutdated`: Überprüft, ob eine Komponente veraltet ist
- `Test-ComponentStandards`: Validiert eine Komponente gegen aktuelle Standards

## Konfiguration

Die Konfiguration des MINTYupdater-Agents erfolgt über die Datei `config/updater_config.json`. Diese enthält:

- **UpdateRules**: Regeln für die Aktualisierung (z.B. Synchronisierung von Formaten, Konventionen)
- **Modes**: Konfiguration der Betriebsmodi (Routine und Trigger)
- **Interfaces**: Konfiguration der Schnittstellen zu anderen Agenten

## MCP-Integration

MINTYupdater ist als MCP-Server implementiert und stellt folgende Tools und Ressourcen bereit:

### Tools

- `unify_quality`: Führt eine rekursive Qualitätsvereinheitlichung durch
- `find_outdated`: Erkennt veraltete oder abweichende Komponenten
- `validate_standards`: Validiert gegen aktuelle Standards
- `synchronize_artifacts`: Synchronisiert Artefakte, Formate und Konventionen

### Ressourcen

- `updater://modes`: Verfügbare Update-Modi (Routine/Trigger)
- `updater://standards`: Aktuelle Standards und Konventionen
- `updater://reports`: Update-Berichte und Statistiken
- `updater://outdated`: Liste veralteter Komponenten
