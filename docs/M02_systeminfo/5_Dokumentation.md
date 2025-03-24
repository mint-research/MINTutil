# Kapitel 5: Dokumentation des Systeminfo-Moduls (M02_systeminfo)

## 5.1 Hauptdokumentation
Die technische Dokumentation des Systeminfo-Moduls ist in mehrere Bereiche gegliedert:

### 5.1.1 Architektur-Dokumentation
- **Modulstruktur**: Das Systeminfo-Modul folgt der standardisierten MINTutil-Modulstruktur mit klarer Trennung von Code, Konfiguration, Daten und Metadaten.
- **Komponentenübersicht**: Detaillierte Beschreibung der Hauptkomponenten wie Datenerfassungsengine, Analysesystem, Berichterstellung und Benutzeroberfläche.
- **Datenfluss**: Erläuterung, wie Systemdaten erfasst, verarbeitet, analysiert, visualisiert und gespeichert werden.
- **Erweiterbarkeit**: Dokumentation der Schnittstellen, über die das Systeminfo-Modul erweitert werden kann, z.B. für zusätzliche Datenquellen oder Analysemethoden.

### 5.1.2 Benutzerhandbuch
- **Grundlegende Bedienung**: Schritt-für-Schritt-Anleitung zur Nutzung des Systeminfo-Moduls.
- **Dashboard-Nutzung**: Erklärung der verschiedenen Dashboard-Elemente und deren Interpretation.
- **Systemdiagnose**: Anleitung zur Durchführung einer umfassenden Systemdiagnose.
- **Berichterstellung**: Prozess zur Generierung und Anpassung von Systemberichten.
- **Leistungsüberwachung**: Anleitung zur Einrichtung und Nutzung der Leistungsüberwachungsfunktionen.
- **Fehlerbehebung**: Häufige Probleme und deren Lösungen.

### 5.1.3 Administratorhandbuch
- **Konfiguration**: Anleitung zur Anpassung der Systeminfo-Konfiguration.
- **Schwellenwerte**: Einstellung und Anpassung von Schwellenwerten für Warnungen.
- **Datenmanagement**: Verwaltung historischer Daten und Berichte.
- **Automatisierung**: Einrichtung automatisierter Scans und Berichte.
- **Integration**: Möglichkeiten zur Integration mit anderen Systemen und Tools.

## 5.2 API-Dokumentation
Das Systeminfo-Modul stellt verschiedene Funktionen für andere Module und Skripte bereit:

### 5.2.1 Datenerfassungs-API
Die Datenerfassungs-API ermöglicht den Zugriff auf Systemdaten:
- **Get-SystemHardwareInfo**: Abrufen von Hardware-Informationen.
- **Get-SystemSoftwareInfo**: Abrufen von Software-Informationen.
- **Get-SystemPerformanceData**: Abrufen von Leistungsdaten.
- **Get-SystemHealthStatus**: Abrufen des Systemgesundheitszustands.
- **Get-NetworkConfiguration**: Abrufen der Netzwerkkonfiguration.

### 5.2.2 Analyse-API
Die Analyse-API bietet Funktionen zur Systemanalyse:
- **Invoke-SystemDiagnostics**: Durchführung einer umfassenden Systemdiagnose.
- **Test-SystemPerformance**: Durchführung von Leistungstests.
- **Find-SystemBottlenecks**: Identifikation von Systemengpässen.
- **Compare-SystemStates**: Vergleich von Systemzuständen über Zeit.
- **Measure-SystemStability**: Bewertung der Systemstabilität.

### 5.2.3 Berichts-API
Die Berichts-API ermöglicht die Generierung von Berichten:
- **New-SystemReport**: Erstellen eines neuen Systemberichts.
- **Export-SystemReport**: Exportieren eines Berichts in verschiedene Formate.
- **Get-ReportTemplates**: Abrufen verfügbarer Berichtsvorlagen.
- **Customize-ReportTemplate**: Anpassen einer Berichtsvorlage.
- **Schedule-ReportGeneration**: Planen regelmäßiger Berichtserstellung.

## 5.3 Dateiformat-Spezifikationen
Das Systeminfo-Modul verwendet verschiedene Dateiformate:

### 5.3.1 display.json
Die `display.json` Datei konfiguriert die Anzeigeoptionen und folgt diesem Schema:
```json
{
  "dashboard": {
    "refreshInterval": 5,
    "defaultView": "overview",
    "showGraphs": true,
    "graphHistoryLength": 60,
    "colorScheme": "default"
  },
  "categories": [
    {
      "id": "hardware",
      "label": "Hardware",
      "icon": "computer",
      "visible": true,
      "expanded": true,
      "components": ["cpu", "memory", "storage", "gpu", "network"]
    },
    {
      "id": "software",
      "label": "Software",
      "icon": "application",
      "visible": true,
      "expanded": false,
      "components": ["os", "applications", "services", "updates"]
    }
  ],
  "thresholds": {
    "cpu": {
      "warning": 80,
      "critical": 95
    },
    "memory": {
      "warning": 85,
      "critical": 95
    },
    "storage": {
      "warning": 90,
      "critical": 95
    }
  }
}
```

### 5.3.2 cache.json
Die `cache.json` Datei speichert zwischengespeicherte Systemdaten und folgt diesem Schema:
```json
{
  "timestamp": "2025-03-24T20:30:00",
  "systemId": "DESKTOP-ABC123",
  "hardware": {
    "cpu": {
      "model": "Intel Core i7-10700K",
      "cores": 8,
      "threads": 16,
      "speed": 3.8,
      "cache": 16
    },
    "memory": {
      "total": 32768,
      "type": "DDR4",
      "speed": 3200
    }
  },
  "software": {
    "os": {
      "name": "Windows 11 Pro",
      "version": "21H2",
      "build": "22000.556"
    }
  },
  "performance": {
    "cpu": {
      "usage": 23,
      "temperature": 45
    },
    "memory": {
      "used": 12288,
      "available": 20480
    }
  }
}
```

### 5.3.3 history.json
Die `history.json` Datei speichert historische Leistungsdaten und folgt diesem Schema:
```json
{
  "systemId": "DESKTOP-ABC123",
  "dataPoints": [
    {
      "timestamp": "2025-03-24T20:00:00",
      "cpu": {
        "usage": 25,
        "temperature": 46
      },
      "memory": {
        "used": 12800,
        "available": 19968
      },
      "storage": {
        "reads": 1.2,
        "writes": 0.8
      },
      "network": {
        "received": 0.5,
        "sent": 0.3
      }
    },
    {
      "timestamp": "2025-03-24T20:05:00",
      "cpu": {
        "usage": 30,
        "temperature": 48
      },
      "memory": {
        "used": 13312,
        "available": 19456
      },
      "storage": {
        "reads": 2.1,
        "writes": 1.5
      },
      "network": {
        "received": 1.2,
        "sent": 0.7
      }
    }
  ]
}
```

## 5.4 Fehlercodes und Problembehandlung
Das Systeminfo-Modul verwendet standardisierte Fehlercodes für die Diagnose:

| Fehlercode | Beschreibung | Mögliche Lösung |
|------------|--------------|-----------------|
| SYSINFO001 | WMI-Zugriffsfehler | Überprüfung der WMI-Dienste und -Berechtigungen |
| SYSINFO002 | Unzureichende Berechtigungen | Ausführung mit Administratorrechten |
| SYSINFO003 | Datenerfassungsfehler | Überprüfung der spezifischen Komponente |
| SYSINFO004 | Leistungsdaten nicht verfügbar | Neustart des Performance Counter-Dienstes |
| SYSINFO005 | Berichtsgenerierungsfehler | Überprüfung der Berichtsvorlage und Daten |
| SYSINFO006 | Datenspeicherungsfehler | Überprüfung der Schreibberechtigungen |
| SYSINFO007 | Historische Daten beschädigt | Zurücksetzen der Verlaufsdaten |
| SYSINFO008 | UI-Initialisierungsfehler | Neustart der Anwendung oder Überprüfung der XAML-Datei |
| SYSINFO009 | Schwellenwert-Konfigurationsfehler | Überprüfung der display.json auf Gültigkeit |
| SYSINFO010 | Netzwerkdiagnosefehler | Überprüfung der Netzwerkadapter und -dienste |
