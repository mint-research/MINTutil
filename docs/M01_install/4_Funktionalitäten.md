# Kapitel 4: Überblick über die Funktionalitäten des Installer-Moduls (M01_install)

## 4.1 Funktionale Kernmerkmale
### 4.1.1 Softwarekatalog-Management
Das Installer-Modul bietet ein umfassendes System zur Verwaltung des Softwarekatalogs:
- **Katalogdatenbank**: Strukturierte Speicherung von Softwareinformationen in `data/M01_install/apps.json`
- **Kategorisierung**: Gruppierung von Software nach Anwendungsbereichen
- **Metadaten**: Speicherung von Informationen wie Versionsnummern, Herstellern und Beschreibungen
- **Benutzerdefinierte Einträge**: Möglichkeit, eigene Softwareeinträge hinzuzufügen
- **Katalog-Updates**: Mechanismen zur Aktualisierung des Katalogs mit neuen Anwendungen

Der Softwarekatalog dient als zentrale Datenquelle für alle Installationsfunktionen und kann an organisationsspezifische Anforderungen angepasst werden.

### 4.1.2 Winget-Integration
Die Integration mit dem Windows Package Manager (Winget) ermöglicht:
- **Automatisierte Installation**: Nutzung von Winget für die automatisierte Softwareinstallation
- **Paketsuche**: Abfrage der Winget-Paketquellen nach verfügbarer Software
- **Versionsverwaltung**: Installation spezifischer Softwareversionen
- **Update-Management**: Identifikation und Installation verfügbarer Updates
- **Stille Installation**: Installation ohne Benutzerinteraktion für Automatisierungszwecke

Die Winget-Integration bildet das Herzstück der Installationsfunktionalität und ermöglicht eine zuverlässige und standardisierte Softwarebereitstellung.

### 4.1.3 Batch-Installation
Die Batch-Installation ermöglicht die effiziente Installation mehrerer Anwendungen:
- **Mehrfachauswahl**: Auswahl mehrerer Anwendungen für die gleichzeitige Installation
- **Installationsreihenfolge**: Intelligente Sortierung basierend auf Abhängigkeiten
- **Parallele Installation**: Wenn möglich, parallele Installation mehrerer Anwendungen
- **Fehlerbehandlung**: Fortsetzung des Batch-Prozesses trotz einzelner Fehler
- **Zusammenfassungsberichte**: Übersichtliche Darstellung der Installationsergebnisse

Die Batch-Installation spart erheblich Zeit bei der Einrichtung neuer Systeme oder bei umfangreichen Software-Updates.

### 4.1.4 Installationsprofile
Installationsprofile ermöglichen die Wiederverwendung von Softwarekonfigurationen:
- **Profilspeicherung**: Speicherung von Anwendungsauswahlen als benannte Profile
- **Profilkategorien**: Gruppierung von Profilen nach Anwendungsfällen (z.B. Entwicklung, Office)
- **Profilimport/-export**: Austausch von Profilen zwischen Systemen
- **Profilaktualisierung**: Aktualisierung bestehender Profile mit neuen Anwendungen
- **Profilverwendung**: Schnelle Anwendung gespeicherter Profile auf neue Systeme

Installationsprofile sind besonders nützlich für Organisationen mit standardisierten Softwareumgebungen.

### 4.1.5 Installationsprotokollierung
Die Installationsprotokollierung bietet umfassende Dokumentation aller Aktivitäten:
- **Detaillierte Logs**: Aufzeichnung aller Installationsschritte und -ergebnisse
- **Fehlerdiagnose**: Ausführliche Informationen zu Installationsproblemen
- **Erfolgsberichte**: Zusammenfassung erfolgreicher Installationen
- **Exportfunktionen**: Export von Protokollen in verschiedene Formate
- **Historische Daten**: Langzeitaufbewahrung von Installationshistorien

Die Protokollierung ist essentiell für Troubleshooting, Compliance und Systemdokumentation.

## 4.2 Prozessübersicht
### 4.2.1 Überblick des Gesamtprozesses
Der typische Installationsprozess umfasst folgende Phasen:
1. **Initialisierung**: Laden des Softwarekatalogs und der Benutzeroberfläche
2. **Softwareauswahl**: Auswahl der zu installierenden Anwendungen durch den Benutzer
3. **Vorinstallationsprüfung**: Überprüfung von Systemanforderungen und Abhängigkeiten
4. **Installation**: Ausführung der Installationsbefehle über Winget
5. **Überwachung**: Tracking des Installationsfortschritts und Statusaktualisierung
6. **Nachinstallationsprüfung**: Verifizierung der erfolgreichen Installation
7. **Berichterstattung**: Generierung von Installationsberichten und -protokollen

### 4.2.2 Entscheidungslogik
Die Entscheidungslogik im Installer-Modul basiert auf folgenden Prinzipien:
- **Abhängigkeitsbasierte Reihenfolge**: Installation von Anwendungen in der richtigen Reihenfolge
- **Fehlertoleranz**: Fortsetzung des Prozesses trotz einzelner Fehler, wenn möglich
- **Ressourcenoptimierung**: Anpassung der Installationsparallellität basierend auf Systemressourcen
- **Benutzereinstellungen**: Berücksichtigung von benutzerdefinierten Installationsparametern
- **Sicherheitsüberprüfungen**: Validierung von Softwarequellen und Installationspaketen

Beispiel für die Entscheidungslogik bei der Installation:
1. Prüfung, ob die Anwendung bereits installiert ist
2. Überprüfung der Systemanforderungen und des verfügbaren Speicherplatzes
3. Identifikation der korrekten Installationsquelle (Winget-ID)
4. Auswahl der geeigneten Installationsparameter (still, interaktiv)
5. Ausführung des Installationsbefehls mit Fortschrittsüberwachung
6. Verifizierung der erfolgreichen Installation
7. Protokollierung des Ergebnisses

## 4.3 Technische Implementierung
### 4.3.1 Kernkomponenten
Das Installer-Modul besteht aus folgenden Kernkomponenten:
- **install.ps1**: Hauptskript mit der Kernlogik des Moduls
- **apps.json**: Datenbank der verfügbaren Software
- **ui.xaml**: Definition der Benutzeroberfläche
- **output.json**: Speicherung von Installationsergebnissen
- **meta.json/modulinfo.json**: Metadaten und Modulinformationen

### 4.3.2 Winget-Kommandostruktur
Die Winget-Befehle werden nach folgendem Muster strukturiert:
```powershell
# Installation
winget install --id [PackageID] --silent --accept-source-agreements --accept-package-agreements

# Update-Prüfung
winget upgrade --id [PackageID]

# Update-Installation
winget upgrade --id [PackageID] --silent --accept-source-agreements --accept-package-agreements

# Deinstallation
winget uninstall --id [PackageID] --silent
```

Diese Befehle werden dynamisch basierend auf Benutzerauswahl und Konfigurationsparametern generiert.
