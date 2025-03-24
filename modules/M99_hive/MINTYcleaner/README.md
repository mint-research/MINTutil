# MINTYcleaner

MINTYcleaner ist ein Agent im Hive-System, der für die Bereinigung von Dokumenten, Skripten, Repositories und Dateisystemen zuständig ist.

## Verantwortlichkeiten

- Bereinigt Dokumente, Skripte, Repositories und Dateisysteme
- Reduziert Redundanz, entfernt veraltete, irrelevante oder schädliche Elemente
- Handelt nach dem Prinzip: 'So viel wie nötig, aber so wenig wie möglich'
- Validiert Konsistenz, Lesbarkeit und Struktur nach Konventionen des Archivars

## Zeitplan

- **Modus**: OnChange + WeeklySweep
- **Wöchentliche Bereinigung**: Sonntag 03:00 UTC
- **Trigger-Fenster**: sofort (0s Verzögerung)
- **Debounce**: 60s

## Schnittstellen

- **Coder**: Empfängt Skripte und Projektartefakte zur Bereinigung
- **Archivar**: Erhält Konventionen und Regeln
- **Log**: Sendet Bereinigungsprotokolle und Änderungsberichte
- **Tester**: Leitet bereinigte Artefakte zur Verifikation weiter
- **Manager**: Erhält Freigabeanforderung für kritische Bereinigungen

## Komponenten

### CleanerManager.ps1

Die Hauptkomponente des MINTYcleaner-Agents, die folgende Funktionen bereitstellt:

- `Initialize-CleanerManager`: Initialisiert den MINTYcleaner Manager
- `Invoke-DocumentCleaning`: Bereinigt ein Dokument oder eine Datei
- `Invoke-RepositoryCleaning`: Bereinigt ein Repository oder Verzeichnis
- `Test-DocumentConsistency`: Validiert die Konsistenz eines Dokuments oder einer Datei

## Konfiguration

Die Konfiguration des MINTYcleaner-Agents erfolgt über die Datei `config/cleaner_config.json`. Diese enthält:

- **CleanupRules**: Regeln für die Bereinigung (z.B. Entfernen leerer Zeilen, Kommentare, Whitespace)
- **Schedule**: Zeitplan für die Bereinigung
- **Interfaces**: Konfiguration der Schnittstellen zu anderen Agenten

## MCP-Integration

MINTYcleaner ist als MCP-Server implementiert und stellt folgende Tools und Ressourcen bereit:

### Tools

- `clean_document`: Bereinigt ein Dokument oder eine Datei
- `clean_repository`: Bereinigt ein Repository oder Verzeichnis
- `validate_consistency`: Validiert die Konsistenz eines Dokuments oder einer Datei
- `remove_redundancy`: Entfernt redundante Elemente aus Dateien oder Verzeichnissen

### Ressourcen

- `cleaner://rules`: Bereinigungsregeln und Konfigurationen
- `cleaner://reports`: Bereinigungsberichte und Statistiken
- `cleaner://history`: Verlauf der Bereinigungsoperationen
