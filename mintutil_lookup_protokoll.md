# 📘 MINTutil – Lookup-Protokoll (Detailstufe 11/10)

Dieses Protokoll dokumentiert **alle Anforderungen, Entscheidungen, Umsetzungen, Details und Konventionen** rund um den aktuellen Projektstand von **MINTutil v10**. Es dient als strukturierte, referenzierbare Wissensbasis für Entwickler, Reviewer oder Automatisierungstools.

---

## 🔧 Allgemein

| Aspekt                 | Wert / Entscheidung |
|------------------------|---------------------|
| Projektname            | MINTutil            |
| Version                | v10 (PowerShell/XAML) |
| Architekturtyp         | Modulare Tab-UI mit dynamischem Daten-Backend |
| UI-Technologie         | PowerShell + WPF/XAML |
| Zielplattform          | Windows (ab Win10) |
| UI-Look                | Modern Flat UI mit klaren Abständen & Statusleiste |
| Lizenz                 | Noch nicht festgelegt |
| Autorenschaft          | Nutzerdefiniert, kollaborativ ausgebaut |

---

## 📂 Verzeichnisstruktur

```
mintutil/
├── main.ps1
├── config/
│   ├── global.config.json
│   └── Installer/ui.xaml
├── config/Installer/output.json
├── data/Installer/apps.json
├── meta/Installer/meta.json
├── meta/Installer/modulinfo.json
├── modules/Installer/install.ps1
├── themes/{light.xaml, dark.xaml}
├── docs/{architektur.md, roadmap.md}
├── validate_mintutil.ps1
├── README.md
```

---

## 📌 Kernkonzepte

### 🧩 Modularität

- Jedes **Modul** hat:
  - eigenen `Tab` im UI
  - eigenen Ordner in `modules/`, `config/`, `data/`, `meta/`
- Ein Modul besteht aus:
  - `install.ps1`: zentrale Ausführungslogik
  - `ui.xaml`: Benutzeroberfläche (wenn vorhanden)
  - `apps.json`: App-Datenstruktur (nur bei Installer-Modul)
  - `meta.json`: Anzeige & Aktivierung
  - `modulinfo.json`: deklarative Steuerung & Schutz
- Module werden dynamisch geladen.

---

## 🖥️ Benutzeroberfläche (UI)

| Komponente       | Beschreibung |
|------------------|--------------|
| TabView          | Ein Modul = ein Tab |
| Actions Panel    | Linke Spalte mit Aktionen (Install, Clear, etc.) |
| App-Liste        | Dynamisch generiert aus `apps.json` |
| Fortschrittsanzeige | `ProgressBar` mit prozentualem Gesamtstatus |
| Statusleiste     | Globale Meldungen am unteren Rand |

---

## 📄 Konfigurationsdateien

| Datei                          | Zweck |
|--------------------------------|-------|
| `global.config.json`           | Theme, Logging, Standardpfade |
| `output.json`                  | Installationsausgabe (zur Laufzeit beschrieben) |
| `apps.json`                    | App-Liste und Konfigfelder (pro Anwendung) |
| `meta.json`                    | Anzeige des Tabs (Name, Icon, Reihenfolge, Aktivierung) |
| `modulinfo.json`              | vollständige Modulbeschreibung, strukturierte Steuerung |

---

## 💡 Designentscheidungen

- UI-Komponenten basieren auf statischem XAML + dynamischem Inhalt
- JSON-basiertes App-Datenmodell für UI-Felder, App-IDs, Deinstallationslogik
- Klare Trennung von Daten (`data/`), Konfiguration (`config/`) und Logik (`modules/`)
- `preserve: true`-Funktion zum Schutz vor LLM- oder Tool-Überoptimierung
- Fortschrittslogik: linearer Fortschritt über alle Apps + innerer Fortschritt (100% pro App)
- Validierungsskript für CI-/LLM-Preflight-Prüfungen

---

## 🛠️ Entwickler-Tools

- **validate_mintutil.ps1** prüft Struktur, Pflichtdateien, Konsistenz
- Alle Felder in `modulinfo.json` maschinenlesbar
- Kein README pro Modul – stattdessen zentrale Metadaten
- Kein dynamisches Einlesen von PS-Skripten zur Laufzeit (alles deklarativ)

---

## 🔄 Eingeführte Standards

| Bereich         | Standard |
|----------------|----------|
| Icons           | `box-download` (Tab-Symbole) |
| Schriftart      | `Segoe UI`, 13px |
| Farben          | Grau, Weiß, Dunkelgrau (Flat-Kontrast) |
| Kontrollhöhe    | Button Padding: 6px |
| Barrierenfreiheit | hohe Lesbarkeit, große Klickflächen |

---

## 🔭 Nächste Schritte laut Roadmap

- `Tweaks`-Modul
- `Cleanup`-Modul
- Logging-Modul mit Logfiles
- modulübergreifendes Settings-Panel
- WPF-Migration langfristig (siehe migrationsplan)

---