# MINTutil

MINTutil ist ein modulares PowerShell-Tool für die Windows-Systemverwaltung mit grafischer Oberfläche zur Automatisierung von Softwareinstallation, Systemanpassung und Wartung.

## Funktionen

- **Modulare Architektur**: Jedes Modul ist als separater Tab im Frontend dargestellt
- **Automatisierte Software-Installation**: Verwalten Sie Software über Winget
- **Systemdiagnose**: Umfassende Systemanalysefunktionen 
- **Erweiterbarkeit**: Einfache Integration eigener Module

## Projektstruktur

```
MINTutil/
├── run_MINTutil.ps1          # Hauptskript zum Starten der Anwendung
├── README.md                 # Diese Datei
├── config/                   # Konfigurationsdateien
│   ├── global/               # Systemweite Konfigurationen
│   ├── M01_install/          # Installer-Konfiguration 
│   ├── M02_systeminfo/       # Systeminfo-Konfiguration
│   └── M03_dummy/            # Dummy-Modul-Konfiguration
├── data/                     # Datendateien
│   ├── global/               # Globale Daten
│   ├── M01_install/          # Installer-Daten
│   ├── M02_systeminfo/       # Systeminfo-Daten
│   └── M03_dummy/            # Dummy-Modul-Daten
├── docs/                     # Dokumentation
│   ├── global/               # Allgemeine Dokumentation
│   ├── M01_install/          # Installer-Dokumentation
│   ├── M02_systeminfo/       # Systeminfo-Dokumentation
│   └── M03_dummy/            # Dummy-Modul-Dokumentation
├── meta/                     # Metadaten
│   ├── global/               # Globale Metadaten
│   ├── M01_install/          # Installer-Metadaten
│   ├── M02_systeminfo/       # Systeminfo-Metadaten
│   └── M03_dummy/            # Dummy-Modul-Metadaten
├── modules/                  # PowerShell-Module
│   ├── global/               # Kernlogik des Gesamtsystems
│   ├── M01_install/          # Installer-Kernlogik
│   ├── M02_systeminfo/       # Systeminfo-Kernlogik
│   └── M03_dummy/            # Dummy-Modul-Kernlogik
└── themes/                   # Designthemen
    ├── light.xaml            # Helles Design
    └── dark.xaml             # Dunkles Design
```

## Verwendung

1. Führen Sie `run_MINTutil.ps1` aus, um die Anwendung zu starten
2. Wählen Sie das gewünschte Modul über die Tabs in der Benutzeroberfläche
3. Folgen Sie den modulspezifischen Anweisungen

## Modularität

Jedes Modul in MINTutil stellt einen eigenen, unabhängigen Funktionsbereich dar und ist als separater Tab in der Benutzeroberfläche zugänglich. Die Module folgen einer einheitlichen Struktur für maximale Wartbarkeit und Erweiterbarkeit:

- **M01_install**: Modul zur Softwareinstallation, Deinstallation und Konfiguration über Winget
- **M02_systeminfo**: Modul zur Anzeige und Analyse von Systeminformationen
- **M03_dummy**: Platzhaltermodul für zukünftige Funktionalität

## Weiterentwicklung

Neue Module können einfach zur bestehenden Struktur hinzugefügt werden. Folgen Sie der Anleitung in der Dokumentation unter `docs/global/neues_modul_erstellen.md`.

## Standardisierte Ordnerstruktur

MINTutil verwendet eine standardisierte Ordnerstruktur für alle Module:

- `/data/global/` - Für globale Daten und Einstellungen
- `/data/M01_install/` - Für Installationsdaten
- `/data/M02_systeminfo/` - Für Systeminformationsdaten
- `/data/M03_dummy/` - Für das Dummy-Modul

Diese konsistente Struktur erleichtert die Wartung und Erweiterung des Systems.