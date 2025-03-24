# Kapitel 4: Überblick über die Funktionalitäten des Systeminfo-Moduls (M02_systeminfo)

## 4.1 Funktionale Kernmerkmale
### 4.1.1 Hardware-Informationssammlung
Das Systeminfo-Modul bietet umfassende Hardware-Informationssammlung:
- **CPU-Informationen**: Detaillierte Daten zu Prozessor(en) inkl. Modell, Geschwindigkeit, Kerne, Cache
- **Arbeitsspeicher**: Kapazität, Typ, Geschwindigkeit, Belegung und verfügbarer Speicher
- **Speichergeräte**: Festplatten, SSDs, optische Laufwerke mit Kapazität, Belegung, Gesundheitszustand
- **Grafikkarten**: Modell, Treiber, VRAM, Unterstützung für DirectX/OpenGL
- **Netzwerkadapter**: Typ, MAC-Adresse, IP-Konfiguration, Verbindungsstatus
- **Peripheriegeräte**: Angeschlossene USB-Geräte, Drucker, Eingabegeräte
- **Mainboard**: Hersteller, Modell, BIOS/UEFI-Version, Chipsatz
- **Sensordaten**: Temperaturen, Lüftergeschwindigkeiten, Spannungen (falls verfügbar)

Die Hardware-Informationen werden über WMI (Windows Management Instrumentation), PowerShell-Cmdlets und native Windows-APIs gesammelt.

### 4.1.2 Software-Inventarisierung
Die Software-Inventarisierung umfasst:
- **Betriebssystem**: Version, Build, Installationsdatum, Update-Status
- **Installierte Software**: Liste aller installierten Programme mit Version und Installationsdatum
- **Windows-Updates**: Installierte Updates, ausstehende Updates, Update-Historie
- **Treiber**: Installierte Gerätetreiber mit Version und Status
- **Dienste**: Laufende und konfigurierte Windows-Dienste mit Status
- **Startprogramme**: Bei Systemstart automatisch gestartete Programme
- **Geplante Aufgaben**: Konfigurierte Aufgaben im Windows Task Scheduler
- **Hotfixes und Patches**: Installierte Systempatches und deren Status

### 4.1.3 Leistungsüberwachung
Die Leistungsüberwachung bietet Echtzeit- und historische Daten zu:
- **CPU-Auslastung**: Gesamtauslastung und Auslastung pro Kern/Prozess
- **Arbeitsspeichernutzung**: Belegung, verfügbarer Speicher, Auslagerungsdateinutzung
- **Festplattenaktivität**: Lese-/Schreiboperationen, Durchsatz, Zugriffszeiten
- **Netzwerkverkehr**: Datenübertragungsraten, Pakete, Latenz
- **Prozesse**: Ressourcenverbrauch einzelner Prozesse (CPU, RAM, I/O)
- **Systemlast**: Gesamtsystemauslastung und Reaktionsfähigkeit
- **Energieverbrauch**: Stromverbrauch und Batteriezustand (bei Laptops)
- **Thermische Daten**: Temperaturentwicklung kritischer Komponenten

Die Leistungsdaten werden in konfigurierbaren Intervallen erfasst und können für Trendanalysen gespeichert werden.

### 4.1.4 Systemdiagnose
Die Systemdiagnose umfasst:
- **Problemerkennung**: Automatische Identifikation von Systemanomalien
- **Fehlerprotokolle**: Analyse von Windows-Ereignisprotokollen
- **Ressourcenengpässe**: Erkennung von Leistungsengpässen
- **Stabilitätsanalyse**: Bewertung der Systemstabilität basierend auf Abstürzen und Fehlern
- **Kompatibilitätsprüfung**: Überprüfung auf bekannte Kompatibilitätsprobleme
- **Sicherheitsanalyse**: Grundlegende Überprüfung von Sicherheitseinstellungen
- **Optimierungsvorschläge**: Empfehlungen zur Verbesserung der Systemleistung
- **Gesundheitsbewertung**: Gesamtbewertung des Systemzustands

### 4.1.5 Berichterstellung
Die Berichterstellung bietet:
- **Vordefinierte Berichte**: Standardberichte für verschiedene Anwendungsfälle
- **Benutzerdefinierte Berichte**: Anpassbare Berichtsvorlagen
- **Exportformate**: Export in PDF, HTML, CSV, XML und JSON
- **Berichtsplanung**: Automatische Generierung von Berichten nach Zeitplan
- **Vergleichsberichte**: Gegenüberstellung von Systemzuständen über Zeit
- **Zusammenfassungen**: Kompakte Übersichten für Management-Zwecke
- **Detailberichte**: Ausführliche technische Dokumentation
- **Visuelle Elemente**: Diagramme und Grafiken zur Visualisierung von Daten

## 4.2 Prozessübersicht
### 4.2.1 Überblick des Gesamtprozesses
Der typische Arbeitsablauf im Systeminfo-Modul umfasst folgende Phasen:
1. **Initialisierung**: Laden der Konfiguration und Vorbereitung der Datenerfassung
2. **Datensammlung**: Erfassung von Hardware-, Software- und Leistungsdaten
3. **Analyse**: Verarbeitung und Interpretation der gesammelten Daten
4. **Visualisierung**: Aufbereitung der Daten für die Anzeige in der Benutzeroberfläche
5. **Berichterstellung**: Generierung von Berichten basierend auf den analysierten Daten
6. **Speicherung**: Archivierung von Daten für historische Vergleiche
7. **Benachrichtigung**: Alarmierung bei kritischen Zuständen oder Schwellenwertüberschreitungen

### 4.2.2 Entscheidungslogik
Die Entscheidungslogik im Systeminfo-Modul basiert auf folgenden Prinzipien:
- **Schwellenwertbasierte Bewertung**: Vergleich von Messwerten mit definierten Schwellenwerten
- **Trendanalyse**: Erkennung von Mustern und Trends in historischen Daten
- **Kontextbewertung**: Berücksichtigung des Systemkontexts bei der Interpretation von Daten
- **Priorisierung**: Gewichtung von Problemen nach Schweregrad und Auswirkung
- **Adaptivität**: Anpassung von Bewertungskriterien basierend auf Systemtyp und -nutzung

Beispiel für die Entscheidungslogik bei der Festplattenbewertung:
1. Erfassung von Kapazität, Belegung, Fragmentierung, SMART-Daten und Zugriffszeiten
2. Vergleich mit definierten Schwellenwerten (z.B. kritisch bei <10% freiem Speicher)
3. Analyse historischer Trends (z.B. schnelle Abnahme des freien Speicherplatzes)
4. Berücksichtigung des Festplattentyps (SSD vs. HDD) bei der Bewertung
5. Priorisierung basierend auf Systemrelevanz der Festplatte
6. Generierung entsprechender Warnungen und Empfehlungen

## 4.3 Technische Implementierung
### 4.3.1 Kernkomponenten
Das Systeminfo-Modul besteht aus folgenden Kernkomponenten:
- **systeminfo.ps1**: Hauptskript mit der Kernlogik des Moduls
- **display.json**: Konfiguration der Anzeigeoptionen
- **ui.xaml**: Definition der Benutzeroberfläche
- **cache.json**: Zwischenspeicherung von Systemdaten
- **history.json**: Speicherung historischer Daten
- **reports/**: Verzeichnis für generierte Berichte
- **meta.json/modulinfo.json**: Metadaten und Modulinformationen

### 4.3.2 Datenerfassungsmethoden
Die Datenerfassung erfolgt über verschiedene Methoden:
```powershell
# WMI-Abfragen für Hardwareinformationen
Get-WmiObject -Class Win32_Processor
Get-WmiObject -Class Win32_PhysicalMemory
Get-WmiObject -Class Win32_DiskDrive

# PowerShell-Cmdlets für Systemdaten
Get-ComputerInfo
Get-Process
Get-Service
Get-EventLog

# Performance Counter für Leistungsdaten
Get-Counter -Counter "\Processor(_Total)\% Processor Time"
Get-Counter -Counter "\Memory\Available MBytes"
Get-Counter -Counter "\PhysicalDisk(_Total)\Disk Reads/sec"

# Registry-Zugriff für Konfigurationsdaten
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
```

Diese Methoden werden in modularen Funktionen gekapselt, die je nach Bedarf aufgerufen werden können.
