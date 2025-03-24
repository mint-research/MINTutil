# MINTutil Datenarchitektur

Dieses Dokument beschreibt die Datenorganisation und den Datenfluss in MINTutil, einschließlich der Struktur von globalen und modulspezifischen Daten.

## Datenverzeichnisstruktur

```
MINTutil/
├── data/                      # Hauptverzeichnis für alle Daten
│   ├── Globale Daten/         # Systemweite Daten (modulübergreifend)
│   ├── Modul1/                # Daten für Modul 1
│   ├── Modul2/                # Daten für Modul 2
│   └── ...
```

## Globale Daten

Das Verzeichnis `data/Globale Daten/` enthält Informationen, auf die mehrere Module zugreifen können. Dies fördert die Interoperabilität und verhindert Datenredundanz.

### Strukturierung globaler Daten

- **users.json**: Benutzerdaten und -einstellungen
- **system_state.json**: Aktueller Systemzustand und Metriken
- **common_resources.json**: Gemeinsam genutzte Ressourcen und Konfigurationen
- **logs/**: Protokolldateien

## Modulspezifische Daten

Jedes Modul hat sein eigenes Unterverzeichnis im `data/`-Verzeichnis, das alle spezifischen Daten enthält, die für die Funktionalität des Moduls benötigt werden.

### Typische Datendateien pro Modul

1. **Konfigurationsdaten**: Speicherung von Benutzereinstellungen
   - Beispiel: `data/Installer/settings.json`

2. **Zustandsdaten**: Speicherung des aktuellen Zustands
   - Beispiel: `data/SystemInfo/cache.json`

3. **Verlaufsdaten**: Speicherung historischer Informationen
   - Beispiel: `data/SystemInfo/history.json`

4. **Import/Export-Daten**: Daten für den Austausch mit anderen Systemen
   - Beispiel: `data/Installer/apps.json`

5. **Temporäre Daten**: Zwischenspeicherung von Informationen
   - Beispiel: `data/Modul/temp/`

## Datenfluss

### Zugriffsmuster

1. **Direkter Zugriff**:
   ```powershell
   $dataPath = Join-Path -Path $PSScriptRoot -ChildPath "../../data/ModulName/data.json"
   $data = Get-Content -Path $dataPath -Raw | ConvertFrom-Json
   ```

2. **Über Hilfsfunktionen**:
   ```powershell
   function Get-ModuleData {
       param([string]$ModuleName, [string]$DataFile)
       $dataPath = Join-Path -Path $script:BasePath -ChildPath "data/$ModuleName/$DataFile"
       if (Test-Path -Path $dataPath) {
           return Get-Content -Path $dataPath -Raw | ConvertFrom-Json
       }
       return $null
   }
   ```

### Modulübergreifender Datenaustausch

Module können auf verschiedene Weise Daten austauschen:

1. **Über globale Daten**:
   - Mehrere Module lesen/schreiben in gemeinsame Datendateien im `data/Globale Daten/`-Verzeichnis

2. **Über Registry**:
   - Module können Informationen in der Windows-Registry speichern/lesen (unter dem Pfad `HKCU:\Software\MINTutil`)

3. **Über temporäre Dateien**:
   - Ein Modul erzeugt Ausgabedateien, die von einem anderen Modul eingelesen werden

4. **Über gemeinsame PowerShell-Objekte**:
   - Module können gegenseitig auf exportierte Funktionen zugreifen

## Datensicherheit und -integrität

### Best Practices

1. **Datenzugriffskontrolle**:
   - Immer Fehlerbehandlung bei Dateizugriffen implementieren
   - Prüfen, ob Dateien existieren, bevor sie gelesen werden
   - Sicherstellen, dass Verzeichnisse existieren, bevor Dateien geschrieben werden

2. **Datenvalidierung**:
   - Eingelesene Daten vor Verwendung validieren
   - Schema-Prüfungen für JSON-Daten durchführen

3. **Atomare Schreiboperationen**:
   - Bei wichtigen Aktualisierungen erst in temporäre Datei schreiben, dann umbenennen
   ```powershell
   $data | ConvertTo-Json -Depth 4 | Set-Content -Path "$dataPath.tmp" -Force
   Move-Item -Path "$dataPath.tmp" -Destination $dataPath -Force
   ```

4. **Backups**:
   - Kritische Daten vor Änderungen sichern
   - Versionierung von Datendateien implementieren

## Beispiel: Datenfluss im Installer-Modul

1. **Einlesen der App-Definitionen**:
   ```powershell
   $appsData = Get-Content -Path $script:AppsDataPath -Raw | ConvertFrom-Json
   ```

2. **Speichern von Benutzereinstellungen**:
   ```powershell
   New-ItemProperty -Path $script:AppRegistry -Name $fieldName -Value $fieldValue -PropertyType String -Force
   ```

3. **Ausgabegenerierung**:
   ```powershell
   $result | ConvertTo-Json -Depth 4 | Set-Content -Path $script:OutputPath -Force
   ```

## Beispiel: Datenfluss im SystemInfo-Modul

1. **Caching von Systemdaten**:
   ```powershell
   $systemData | ConvertTo-Json -Depth 4 | Set-Content -Path $script:CacheDataPath -Force
   ```

2. **Historie speichern**:
   ```powershell
   $history = @($historyEntry) + $history
   $history | ConvertTo-Json -Depth 4 | Set-Content -Path $script:HistoryDataPath -Force
   ```

3. **Berichte exportieren**:
   ```powershell
   $systemData | ConvertTo-Json -Depth 4 | Set-Content -Path $reportFile -Force
   ```

## Empfehlungen für neue Module

1. Organisieren Sie modulspezifische Daten in einem dedizierten Unterverzeichnis
2. Verwenden Sie beschreibende Dateinamen, die den Inhalt widerspiegeln
3. Implementieren Sie Datenzugriffsfunktionen für wiederholte Operationen
4. Nutzen Sie die globalen Daten für modulübergreifende Informationen
5. Dokumentieren Sie das Datenformat in Kommentaren oder separaten Dateien