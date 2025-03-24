# MINTutil Modulstruktur

## Grundlegende Architektur

MINTutil ist modular aufgebaut, wobei jedes Modul als ein separater Tab in der Benutzeroberfläche dargestellt wird. Die gesamte Anwendung basiert auf einem einheitlichen Muster zur Organisation von Code, Konfiguration und Daten.

## Verzeichnisstruktur

Jedes Modul hat seine eigenen Unterordner in folgenden Hauptverzeichnissen:

```
MINTutil/
├── config/                  # Konfigurationsdateien
│   ├── global.config.json   # Globale Konfiguration
│   ├── Modul1/              # Modulspezifische Konfiguration
│   ├── Modul2/
│   └── ...
├── data/                    # Datendateien
│   ├── Globale Daten/       # Globale Daten
│   ├── Modul1/              # Modulspezifische Daten
│   ├── Modul2/
│   └── ...
├── docs/                    # Dokumentation
│   ├── allgemein/           # Allgemeine Dokumentation
│   ├── Modul1/              # Modulspezifische Dokumentation
│   ├── Modul2/
│   └── ...
├── meta/                    # Metadaten
│   ├── Modul1/              # Metadaten für Modul1
│   ├── Modul2/
│   └── ...
├── modules/                 # PowerShell-Module
│   ├── Modul1/              # PowerShell-Code für Modul1
│   ├── Modul2/
│   └── ...
└── themes/                  # Designthemen
    ├── light.xaml
    └── dark.xaml
```

## Modulbestandteile

Jedes Modul besteht aus:

1. **Metadaten** (`meta/ModulName/`):
   - `meta.json`: Grundlegende Moduldaten wie Name, Icon, Reihenfolge
   - `modulinfo.json`: Detaillierte Beschreibung, Pfade zu Ressourcen

2. **PowerShell-Code** (`modules/ModulName/`):
   - Hauptdatei (in der Regel `modulname.ps1`): Enthält die Kernlogik

3. **UI-Konfiguration** (`config/ModulName/`):
   - `ui.xaml`: Definition der Benutzeroberfläche
   - Andere Konfigurationsdateien

4. **Daten** (`data/ModulName/`):
   - Datendateien wie z.B. JSON, CSV, etc.

5. **Dokumentation** (`docs/ModulName/`):
   - Dokumentation zur Verwendung und Funktionalität des Moduls

## Modul-Interaktion

Module können durch gemeinsame Datendateien oder durch festgelegte Schnittstellen miteinander interagieren. Die globale Konfiguration `config/global.config.json` enthält anwendungsweite Einstellungen.

## Hinzufügen eines neuen Moduls

Um ein neues Modul hinzuzufügen, sollten folgende Schritte durchgeführt werden:

1. Erstellen der entsprechenden Verzeichnisstruktur
2. Erstellen der Metadatendateien (`meta.json` und `modulinfo.json`)
3. Implementieren der Kernlogik im Modulverzeichnis
4. Erstellen der UI-Konfiguration
5. Hinzufügen etwaiger Datendateien
6. Dokumentieren des Moduls