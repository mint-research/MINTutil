# MINTutil – Projekt-Roadmap

Diese Datei enthält geplante Features, Verbesserungen und Erweiterungen für kommende Versionen von MINTutil. Sie dient als strategische Übersicht für die Entwicklung und Priorisierung.

---

## ✅ In Umsetzung
- **Fortschrittsanzeige bei Installationen**
  - Anzeige des aktuellen Installationsstatus (z. B. ProgressBar)
  - Echtzeit-Feedback für `winget`-Installationen
  - Optional: Statusleiste mit letztem Event

---

## 🧩 Geplante Module

### **Tweaks-Modul**
- UI für Systemanpassungen (Registry, Explorer, Windows Settings)
- Kategorien: Sicherheit, Optik, Leistung
- Datenquelle: `data/Tweaks/tweaks.json`
- Ergebnis: Registry-/PowerShell-Modifikationen

### **Cleanup-Modul**
- Temporäre Dateien löschen
- Komponenten wie `cleanmgr`, UpdateCache, Explorer MRUs etc.
- Oberfläche mit Schnellaktionen und optionalem Protokoll

---

## ⚙️ Technische Erweiterungen

### **Logging-Modul**
- Tab zur Anzeige von:
  - Installationsverlauf
  - Fehlerprotokoll
  - Ereignissen
- Log-Dateien: `logs/install.log`, `logs/errors.log`

### **Modulverwaltung**
- Übersicht aktiver/deaktivierter Module
- Umschaltbar über die UI
- Basis: `meta/<Modul>/meta.json -> enabled`

---

## 🧪 Erweiterte Architektur

### **Modulübergreifende Settings-Funktion**
- Zentrale Komponente für globales Config-Management
- Zugriff aus Tabs oder Navigationsleiste

### **Automatisierte Tests & Linting**
- Prüfung von `apps.json`, `modulinfo.json` und Tab-UI
- Integration von PSScriptAnalyzer
- GitHub Action oder lokaler Preflight-Check

---

## Zukunftsideen
- Portable Distribution (One-Click Script-Bundler)
- Mehrsprachige Oberfläche
- Plugin-Schnittstelle







Durch Refaktoring gibt es viele Redundanzen in der Ordnerstruktur. 

Refaktoriere und konsolidiere das gesamte Projekt, jeden Ordner und jedes Script iterativ  so, dass jeder Ordner die unten definierten Unterordner hat und darunter die scriptstruktur und deren inhalt konsistent, robust und performant ist. 

beginne mit \module\ und untergepordnete Ordner und Dateien. Dann sichere Das Ergebnis.

fahre fort mit \data\ und untergepordnete Ordner und Dateien. Dann sichere Das Ergebnis.

fahre fort mit \config\ und untergepordnete Ordner und Dateien. Dann sichere Das Ergebnis.

fahre fort mit \meta\ und untergepordnete Ordner und Dateien. Dann sichere Das Ergebnis.

Ende mit themes.


Die Ordner Struktur umfasst Genau die Ordnerstruktur unten, NICHT MEHR, NICHT WENIGER.  so, dass alle inhalte unter den folgenden ordnern konsolidiert sind:

\data\global\
\data\M01_install\
\data\M02_systeminfo\
\data\M03_dummy\
\config\global\
\config\M01_install\
\config\M02_systeminfo\
\config\M03_dummy\
\meta\global\
\meta\M01_install\
\meta\M02_systeminfo\
\meta\M03_dummy\
\module\global\
\module\M01_install\
\module\M02_systeminfo\
\module\M03_dummy\
\themes\