# MINTYarchivar

MINTYarchivar ist der Archivierungs-Agent des MINTYhive-Systems. Er ist verantwortlich für die Archivierung, Wiederherstellung und Verwaltung von Daten und Dokumenten.

## Funktionen

- **Archivierung**: Archiviert Daten und Dokumente für langfristige Aufbewahrung
- **Wiederherstellung**: Stellt archivierte Daten und Dokumente wieder her
- **Versionierung**: Verwaltet verschiedene Versionen von archivierten Daten
- **Kompression**: Komprimiert Daten für effiziente Speichernutzung
- **Verschlüsselung**: Verschlüsselt sensible Daten für sichere Aufbewahrung

## Komponenten

- **ArchiveManager**: Hauptkomponente für die Archivierung und Wiederherstellung
- **VersionManager**: Verwaltet Versionen von archivierten Daten
- **CompressionManager**: Komprimiert und dekomprimiert Daten
- **EncryptionManager**: Verschlüsselt und entschlüsselt Daten
- **StorageManager**: Verwaltet den Speicherort der archivierten Daten

## Konfiguration

Die Konfiguration erfolgt über die Datei `config/archivar_config.json`. Folgende Einstellungen können angepasst werden:

- **ArchiveSettings**: Konfiguration der Archivierung
- **VersionSettings**: Konfiguration der Versionierung
- **CompressionSettings**: Konfiguration der Kompression
- **EncryptionSettings**: Konfiguration der Verschlüsselung
- **StorageSettings**: Konfiguration des Speicherorts

## Verwendung

```powershell
# Importieren des Moduls
Import-Module .\src\MINTYarchivar.ps1

# Initialisieren des Archivierungs-Agents
Initialize-Archivar

# Archivieren von Daten
Add-ToArchive -Path "path/to/data" -ArchiveName "MyArchive" -Version "1.0" -Compress $true -Encrypt $true

# Wiederherstellen von Daten
Restore-FromArchive -ArchiveName "MyArchive" -Version "1.0" -OutputPath "path/to/output"

# Auflisten von archivierten Daten
Get-ArchiveList

# Löschen von archivierten Daten
Remove-FromArchive -ArchiveName "MyArchive" -Version "1.0"
```

Weitere Beispiele finden Sie in der Datei `examples/archivar_usage.ps1`.

## Integration mit anderen Agenten

MINTYarchivar integriert sich mit anderen Agenten des MINTYhive-Systems, um eine nahtlose Archivierung und Wiederherstellung zu ermöglichen. Andere Agenten können die Archivierungsfunktionen nutzen, um ihre Daten zu sichern und wiederherzustellen.
