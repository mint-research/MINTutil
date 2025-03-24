# Kapitel 5: Dokumentation des Installer-Moduls (M01_install)

## 5.1 Hauptdokumentation
Die technische Dokumentation des Installer-Moduls ist in mehrere Bereiche gegliedert:

### 5.1.1 Architektur-Dokumentation
- **Modulstruktur**: Das Installer-Modul folgt der standardisierten MINTutil-Modulstruktur mit klarer Trennung von Code, Konfiguration, Daten und Metadaten.
- **Komponentenübersicht**: Detaillierte Beschreibung der Hauptkomponenten wie Softwarekatalog, Installationsengine, UI-Komponenten und Protokollierungssystem.
- **Datenfluss**: Erläuterung, wie Daten zwischen den verschiedenen Komponenten des Moduls fließen, von der Benutzerauswahl bis zur Installationsausführung.
- **Integration mit Winget**: Dokumentation der Schnittstelle zum Windows Package Manager und der verwendeten Kommandostrukturen.

### 5.1.2 Benutzerhandbuch
- **Grundlegende Bedienung**: Schritt-für-Schritt-Anleitung zur Nutzung des Installer-Moduls.
- **Softwareinstallation**: Detaillierte Anleitung zur Auswahl und Installation von Software.
- **Batch-Installation**: Anleitung zur effizienten Installation mehrerer Anwendungen.
- **Profile**: Erstellung und Verwendung von Installationsprofilen.
- **Updates**: Prozess zur Überprüfung und Installation von Software-Updates.
- **Fehlerbehebung**: Häufige Probleme und deren Lösungen.

### 5.1.3 Administratorhandbuch
- **Katalogverwaltung**: Anleitung zur Pflege und Erweiterung des Softwarekatalogs.
- **Anpassung**: Möglichkeiten zur Anpassung des Moduls an organisationsspezifische Anforderungen.
- **Automatisierung**: Optionen für die skriptgesteuerte Verwendung des Installer-Moduls.
- **Protokollanalyse**: Interpretation und Nutzung der Installationsprotokolle.
- **Leistungsoptimierung**: Tipps zur Optimierung der Installationsleistung.

## 5.2 API-Dokumentation
Das Installer-Modul stellt verschiedene Funktionen für andere Module und Skripte bereit:

### 5.2.1 Installations-API
Die Installations-API ermöglicht die programmatische Steuerung von Softwareinstallationen:
- **Install-Software**: Installation einer oder mehrerer Anwendungen.
- **Uninstall-Software**: Deinstallation von Anwendungen.
- **Get-InstalledSoftware**: Abrufen einer Liste installierter Software.
- **Test-SoftwareInstalled**: Überprüfen, ob eine bestimmte Anwendung installiert ist.
- **Get-InstallationLog**: Abrufen von Installationsprotokollen.

### 5.2.2 Katalog-API
Die Katalog-API bietet Zugriff auf den Softwarekatalog:
- **Get-SoftwareCatalog**: Abrufen des gesamten Softwarekatalogs.
- **Find-Software**: Suchen nach Anwendungen im Katalog.
- **Add-SoftwareToCatalog**: Hinzufügen neuer Anwendungen zum Katalog.
- **Update-SoftwareCatalog**: Aktualisieren von Katalogeinträgen.
- **Export-SoftwareCatalog**: Exportieren des Katalogs in verschiedene Formate.

### 5.2.3 Profil-API
Die Profil-API ermöglicht die Verwaltung von Installationsprofilen:
- **New-InstallationProfile**: Erstellen eines neuen Installationsprofils.
- **Get-InstallationProfiles**: Abrufen verfügbarer Profile.
- **Apply-InstallationProfile**: Anwenden eines Profils zur Installation.
- **Export-InstallationProfile**: Exportieren eines Profils.
- **Import-InstallationProfile**: Importieren eines Profils.

## 5.3 Dateiformat-Spezifikationen
Das Installer-Modul verwendet verschiedene Dateiformate:

### 5.3.1 apps.json
Die `apps.json` Datei enthält den Softwarekatalog und folgt diesem Schema:
```json
{
  "categories": [
    {
      "name": "Kategoriename",
      "description": "Kategoriebeschreibung",
      "applications": [
        {
          "id": "Eindeutige ID",
          "name": "Anwendungsname",
          "wingetId": "Winget-Paket-ID",
          "description": "Beschreibung der Anwendung",
          "version": "Aktuelle Version",
          "publisher": "Herausgeber",
          "homepage": "Website-URL",
          "tags": ["Tag1", "Tag2"],
          "installOptions": {
            "silent": true,
            "customArgs": "Zusätzliche Argumente"
          }
        }
      ]
    }
  ]
}
```

### 5.3.2 output.json
Die `output.json` Datei speichert Installationsergebnisse und folgt diesem Schema:
```json
{
  "installationSessions": [
    {
      "timestamp": "Zeitstempel",
      "user": "Benutzername",
      "system": "Systemname",
      "results": [
        {
          "applicationId": "Anwendungs-ID",
          "name": "Anwendungsname",
          "success": true/false,
          "version": "Installierte Version",
          "errorMessage": "Fehlermeldung (falls vorhanden)",
          "installationTime": "Installationsdauer",
          "commandOutput": "Ausgabe des Installationsbefehls"
        }
      ],
      "summary": {
        "total": 10,
        "successful": 9,
        "failed": 1,
        "totalTime": "Gesamtdauer"
      }
    }
  ]
}
```

### 5.3.3 Installationsprofile
Installationsprofile werden im JSON-Format gespeichert und folgen diesem Schema:
```json
{
  "profileName": "Profilname",
  "description": "Profilbeschreibung",
  "creator": "Ersteller",
  "created": "Erstellungsdatum",
  "modified": "Änderungsdatum",
  "applications": [
    {
      "id": "Anwendungs-ID",
      "customOptions": {
        "silent": true,
        "customArgs": "Zusätzliche Argumente"
      }
    }
  ],
  "metadata": {
    "targetEnvironment": "Zielumgebung",
    "version": "Profilversion",
    "tags": ["Tag1", "Tag2"]
  }
}
```

## 5.4 Fehlercodes und Problembehandlung
Das Installer-Modul verwendet standardisierte Fehlercodes für die Diagnose:

| Fehlercode | Beschreibung | Mögliche Lösung |
|------------|--------------|-----------------|
| INST001 | Winget nicht gefunden | Installation von Winget über Microsoft Store |
| INST002 | Anwendung nicht im Katalog | Aktualisierung des Katalogs oder manuelle Hinzufügung |
| INST003 | Installationsfehler | Überprüfung der Winget-Ausgabe für Details |
| INST004 | Unzureichende Berechtigungen | Ausführung mit Administratorrechten |
| INST005 | Netzwerkfehler | Überprüfung der Internetverbindung |
| INST006 | Speicherplatzproblem | Freigabe von Speicherplatz auf der Zielfestplatte |
| INST007 | Abhängigkeitsfehler | Installation fehlender Abhängigkeiten |
| INST008 | Kataloglesefehler | Überprüfung der apps.json auf Gültigkeit |
| INST009 | Profillesefehler | Überprüfung des Profilformats |
| INST010 | UI-Initialisierungsfehler | Neustart der Anwendung oder Überprüfung der XAML-Datei |
