# MINTutil Architektur – Version 10

## Überblick

MINTutil ist ein modulares PowerShell-Tool mit grafischer Oberfläche (WPF/XAML), das die Verwaltung und Automatisierung von Software- und Systemaufgaben erleichtert. Version 10 bringt Fortschrittsanzeige, Statusleiste und strukturierte Modulregistrierung.

---

## Verzeichnisstruktur

```
mintutil/
├── main.ps1
├── config/
│   ├── global.config.json
│   └── Installer/
│       ├── ui.xaml
│       └── output.json
├── data/
│   └── Installer/
│       └── apps.json
├── meta/
│   └── Installer/
│       ├── meta.json
│       └── modulinfo.json
├── modules/
│   └── Installer/
│       └── install.ps1
├── themes/
│   ├── light.xaml
│   └── dark.xaml
├── docs/
│   └── architektur.md
├── validate_mintutil.ps1
└── README.md
```

---

## Module

Ein Modul entspricht einem Tab im UI. Alle Konfigurations-, Daten- und Logikdateien sind im jeweiligen Modulordner untergebracht. Module werden dynamisch über ihre `meta.json` und `modulinfo.json` erkannt.

---

## UI-Bestandteile

- **Actions-Leiste** links neben der App-Liste
- **App-Liste** dynamisch aus `apps.json`
- **Fortschrittsanzeige** pro App-Ausführung
- **Statusleiste** für globale Meldungen

---

## Schutzmechanismen

- `modulinfo.json` mit `"preserve": true`
- Validierung über `validate_mintutil.ps1`
- `apps.json` bildet die Struktur der Oberfläche – niemals automatisch verändern

---

## Konfiguration

- `global.config.json`: Theme, Logging, Standardpfade
- `output.json`: Erzeugt durch Modulaktionen (z. B. Installation)