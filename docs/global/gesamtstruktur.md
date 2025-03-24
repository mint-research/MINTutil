# MINTutil Gesamtstruktur

## Übersicht

MINTutil ist eine modulare PowerShell-Anwendung mit einer grafischen Benutzeroberfläche (GUI), die für die Windows-Systemverwaltung entwickelt wurde. Die Anwendung basiert auf einem modularen Konzept, bei dem jedes Modul als eigenständiger Tab in der Benutzeroberfläche dargestellt wird.

## Hauptverzeichnisstruktur

Die Anwendung ist in folgenden Hauptverzeichnissen organisiert:

```
MINTutil/
├── main.ps1                    # Hauptskript und Einstiegspunkt
├── validate_mintutil.ps1       # Validierungsskript für die Modulstruktur
├── README.md                   # Allgemeine Dokumentation
├── config/                     # Konfigurationsverzeichnis
│   ├── global.config.json      # Globale Konfiguration
│   ├── Installer/              # Konfiguration für Installer-Modul
│   ├── SystemInfo/             # Konfiguration für SystemInfo-Modul
│   └── ...                     # Konfiguration für weitere Module
├── data/                       # Datenverzeichnis
│   ├── Globale Daten/          # Globale, modulübergreifende Daten
│   ├── Installer/              # Daten für Installer-Modul
│   ├── SystemInfo/             # Daten für SystemInfo-Modul
│   └── ...                     # Daten für weitere Module
├── docs/                       # Dokumentationsverzeichnis
│   ├── architektur.md          # Architekturdokumentation
│   ├── modulstruktur.md        # Erklärung der Modulstruktur
│   ├── daten_architektur.md    # Erklärung der Datenarchitektur
│   ├── neues_modul_erstellen.md # Anleitung zum Erstellen neuer Module
│   ├── Installer/              # Dokumentation für Installer-Modul
│   ├── SystemInfo/             # Dokumentation für SystemInfo-Modul
│   └── ...                     # Dokumentation für weitere Module
├── meta/                       # Metadaten-Verzeichnis
│   ├── Installer/              # Metadaten für Installer-Modul
│   ├── SystemInfo/             # Metadaten für SystemInfo-Modul
│   └── ...                     # Metadaten für weitere Module
├── modules/                    # Modulverzeichnis (PowerShell-Code)
│   ├── Installer/              # Code für Installer-Modul
│   ├── SystemInfo/             # Code für SystemInfo-Modul
│   └── ...                     # Code für weitere Module
└── themes/                     # Designthemen
    ├── light.xaml              # Helles Design
    └── dark.xaml               # Dunkles Design
```

## Module

### Installer-Modul

Das Installer-Modul ermöglicht die Installation, Deinstallation und Konfiguration von Software über Winget. Es bietet eine übersichtliche Benutzeroberfläche zum Verwalten von Softwarepaketen.

Struktur:
- **Modulcode**: `modules/Installer/install.ps1`
- **UI-Definition**: `config/Installer/ui.xaml`
- **Konfiguration**: `config/Installer/output.json`
- **Daten**: `data/Installer/apps.json`
- **Metadaten**: `meta/Installer/meta.json` und `meta/Installer/modulinfo.json`

### SystemInfo-Modul

Das SystemInfo-Modul sammelt und zeigt Systeminformationen wie Hardware, Software, Leistung und Netzwerkdaten an. Es bietet Funktionen zum Exportieren von Berichten und zur Anzeige historischer Daten.

Struktur:
- **Modulcode**: `modules/SystemInfo/systeminfo.ps1`
- **UI-Definition**: `config/SystemInfo/ui.xaml`
- **Konfiguration**: `config/SystemInfo/display.json`
- **Daten**: `data/SystemInfo/cache.json`
- **Metadaten**: `meta/SystemInfo/meta.json` und `meta/SystemInfo/modulinfo.json`

## Datenorganisation

### Globale Daten

Globale, modulübergreifende Daten werden im Verzeichnis `data/Globale Daten/` gespeichert. Diese Daten können von allen Modulen gelesen und verwendet werden, zum Beispiel:

- `common_settings.json`: Gemeinsame Einstellungen für alle Module
- `system_state.json`: Aktueller Systemzustand
- `user_preferences.json`: Benutzereinstellungen

### Modulspezifische Daten

Jedes Modul hat sein eigenes Verzeichnis unter `data/`, in dem modulspezifische Daten gespeichert werden:

- `data/Installer/apps.json`: Definiert verfügbare Anwendungen für den Installer
- `data/SystemInfo/cache.json`: Zwischenspeichert Systeminformationen
- `data/SystemInfo/history.json`: Speichert historische Systemzustände

## Konfiguration

### Globale Konfiguration

Die Datei `config/global.config.json` enthält anwendungsweite Einstellungen, die für alle Module gelten, wie:

- Theme-Einstellungen
- Sprache
- Allgemeine Programmkonfiguration

### Modulspezifische Konfiguration

Jedes Modul hat sein eigenes Verzeichnis unter `config/` für modulspezifische Einstellungen:

- `config/Installer/output.json`: Ausgabedatei für Installer-Aktionen
- `config/SystemInfo/display.json`: Konfiguriert die Anzeige von Systeminformationen

## Metadaten

Jedes Modul besitzt zwei wichtige Metadatendateien im Verzeichnis `meta/ModulName/`:

1. **meta.json**: Grundlegende Informationen wie Name, Icon und Reihenfolge
2. **modulinfo.json**: Detaillierte Informationen, Pfade zu Ressourcen und Abhängigkeiten

Diese Metadaten werden beim Start der Anwendung gelesen, um die Module zu laden und zu initialisieren.

## UI-Integration

Die Benutzeroberfläche von MINTutil besteht aus einem Hauptfenster mit Tab-Leiste. Jedes Modul wird als eigener Tab dargestellt, wobei die Reihenfolge durch die `order`-Eigenschaft in den Metadaten bestimmt wird.

## Erweitern der Anwendung

Um die Anwendung um ein neues Modul zu erweitern:

1. Erstellen Sie die notwendigen Verzeichnisse (siehe `docs/neues_modul_erstellen.md`)
2. Definieren Sie die Metadaten
3. Implementieren Sie die Modullogik
4. Erstellen Sie die UI-Definition
5. Fügen Sie nötige Konfigurationen und Daten hinzu

Die modulare Struktur ermöglicht eine einfache Erweiterung ohne Änderungen am Hauptcode der Anwendung.

## Fazit

Die modulare Architektur von MINTutil bietet mehrere Vorteile:

- Klare Trennung von Code, Konfiguration und Daten
- Einfache Erweiterbarkeit durch neue Module
- Übersichtliche Organisation in einer konsistenten Struktur
- Flexibilität durch modulbasierte Entwicklung
- Wiederverwendbare Grundstruktur für neue Funktionen