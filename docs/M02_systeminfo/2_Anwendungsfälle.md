# Kapitel 2: Anwendungsfälle des Systeminfo-Moduls (M02_systeminfo)

## 2.1 Typische Szenarien
### 2.1.1 Szenario 1: Systemdiagnose bei Leistungsproblemen
Ein Helpdesk-Mitarbeiter erhält eine Anfrage bezüglich eines langsamen Computers. Mit dem Systeminfo-Modul kann er:
- Einen umfassenden Systemscan durchführen, um Ressourcenengpässe zu identifizieren
- CPU-, RAM- und Festplattenauslastung in Echtzeit überwachen
- Laufende Prozesse und deren Ressourcenverbrauch analysieren
- Startup-Programme identifizieren, die das System verlangsamen könnten
- Einen detaillierten Diagnosebericht erstellen, der Optimierungsempfehlungen enthält
- Die Ergebnisse vor und nach Optimierungsmaßnahmen vergleichen

### 2.1.2 Szenario 2: Hardware-Inventarisierung
Ein IT-Administrator muss eine Bestandsaufnahme der Hardware in seiner Organisation durchführen. Mit dem Systeminfo-Modul kann er:
- Detaillierte Hardware-Informationen von mehreren Systemen sammeln
- Komponenten wie CPU, RAM, Grafikkarten, Netzwerkadapter und Speichergeräte erfassen
- Seriennummern und Modellbezeichnungen für Inventarisierungszwecke dokumentieren
- Hardware-Berichte in verschiedenen Formaten exportieren
- Veraltete oder aufrüstungsbedürftige Hardware identifizieren
- Kompatibilitätsprüfungen für geplante Software- oder Betriebssystem-Updates durchführen

### 2.1.3 Szenario 3: Systemüberwachung und Problemerkennung
Ein Systemadministrator möchte potenzielle Probleme erkennen, bevor sie zu Ausfällen führen. Mit dem Systeminfo-Modul kann er:
- Regelmäßige automatisierte Systemscans einrichten
- Kritische Systemparameter wie Festplattenplatz, Temperatur und Fehlerraten überwachen
- Warnungen bei Überschreitung definierter Schwellenwerte erhalten
- Trends in der Systemleistung über Zeit analysieren
- Systemprotokolle auf Fehler und Warnungen überprüfen
- Präventive Maßnahmen basierend auf erkannten Mustern einleiten

## 2.2 Nutzungskontext
### 2.2.1 Umgebung
Das Systeminfo-Modul wird in folgenden Umgebungen eingesetzt:
- **Unternehmens-IT**: Zur Überwachung und Verwaltung von Arbeitsplatzrechnern und Servern
- **Helpdesk und Support**: Für schnelle Diagnose bei Benutzeranfragen
- **Systemadministration**: Zur proaktiven Systemwartung und -optimierung
- **IT-Audits**: Für die Dokumentation von Systemkonfigurationen
- **Heimnetzwerke**: Von fortgeschrittenen Benutzern zur Systemoptimierung
- **Bildungseinrichtungen**: Zur Verwaltung von Computerräumen und Laboren

### 2.2.2 Abhängigkeiten
Für die Nutzung des Systeminfo-Moduls müssen folgende Voraussetzungen erfüllt sein:
- **Windows 10/11**: Das Betriebssystem muss Windows 10 oder höher sein
- **PowerShell 5.1+**: Für die Ausführung der Diagnoseskripte
- **Administratorrechte**: Für den Zugriff auf bestimmte Systemdiagnosefunktionen
- **WMI-Zugriff**: Windows Management Instrumentation muss aktiviert sein
- **Global-Modul**: Abhängigkeit vom Global-Modul für grundlegende Funktionen
- **Ausreichend Speicherplatz**: Für die Speicherung von Diagnoseberichten und historischen Daten

### 2.2.3 Integration mit anderen Modulen
Das Systeminfo-Modul interagiert mit anderen MINTutil-Modulen:
- **Global-Modul**: Für grundlegende Funktionen wie UI-Framework, Konfiguration und Logging
- **Installer-Modul**: Liefert Informationen über installierte Software und deren Versionen
- **Cleanup-Modul** (falls vorhanden): Erhält Empfehlungen für Bereinigungsaktionen
- **Tweaks-Modul** (falls vorhanden): Erhält Systemkonfigurationsdaten für Optimierungsvorschläge

## 2.3 Erweiterte Anwendungsfälle
### 2.3.1 Netzwerkdiagnose
Das Systeminfo-Modul kann für Netzwerkdiagnosen verwendet werden:
- Analyse der Netzwerkkonfiguration und -verbindungen
- Überwachung von Netzwerkverkehr und -leistung
- Identifikation von Netzwerkproblemen und Engpässen
- Überprüfung von Firewall-Einstellungen und offenen Ports
- Diagnose von DNS- und DHCP-Konfigurationen
- Analyse der WLAN-Signalstärke und -qualität

### 2.3.2 Sicherheitsüberprüfung
Das Modul unterstützt grundlegende Sicherheitsüberprüfungen:
- Überprüfung des Patch-Status des Betriebssystems
- Identifikation veralteter oder unsicherer Software
- Analyse der Firewall-Konfiguration
- Überprüfung der Benutzerkonten und -berechtigungen
- Erkennung potenziell unerwünschter Programme
- Überprüfung der Systemprotokolle auf Sicherheitsereignisse
