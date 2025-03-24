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
│   ├── modul1/               # Installer-Konfiguration 
│   └── modul2/               # Modul2-Konfiguration
├── data/                     # Datendateien
│   ├── global/               # Globale Daten
│   ├── modul1/               # Installer-Daten
│   └── modul2/               # Modul2-Daten
├── docs/                     # Dokumentation
│   ├── global/               # Allgemeine Dokumentation
│   ├── modul1/               # Installer-Dokumentation
│   └── modul2/               # Modul2-Dokumentation
├── meta/                     # Metadaten
│   ├── global/               # Globale Metadaten
│   ├── modul1/               # Installer-Metadaten
│   └── modul2/               # Modul2-Metadaten
├── modules/                  # PowerShell-Module
│   ├── global/               # Kernlogik des Gesamtsystems
│   ├── modul1/               # Installer-Kernlogik
│   └── modul2/               # Modul2-Kernlogik
└── themes/                   # Designthemen
    ├── light.xaml            # Helles Design
    └── dark.xaml             # Dunkles Design
```

## Verwendung

1. Führen Sie `run_MINTutil.ps1` aus, um die Anwendung zu starten
2. Wählen Sie das gewünschte Modul über die Tabs in der Benutzeroberfläche
3. Folgen Sie den modulspezifischen Anweisungen

## Modularität

Jedes Modul in MINTutil stellt einen eigenen, unabhängigen Funktionsbereich dar und ist als separater Tab in der Benutzeroberfläche zugänglich. Die Module folgen einer einheitlichen Struktur für maximale Wartbarkeit und Erweiterbarkeit.

## Weiterentwicklung

Neue Module können einfach zur bestehenden Struktur hinzugefügt werden. Folgen Sie der Anleitung in der Dokumentation unter `docs/global/neues_modul_erstellen.md`.