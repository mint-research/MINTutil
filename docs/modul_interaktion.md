# Modul-Interaktion in MINTutil

Dieses Dokument beschreibt, wie Module in MINTutil miteinander interagieren können und welche Mechanismen zur Kommunikation und zum Datenaustausch zur Verfügung stehen.

## Grundprinzipien

Module in MINTutil sind grundsätzlich unabhängig voneinander konzipiert, um eine lose Kopplung zu gewährleisten. Dennoch gibt es mehrere Wege, wie Module interagieren können:

1. **Über gemeinsame globale Daten**
2. **Über die Windows-Registry**
3. **Über exportierte PowerShell-Funktionen**
4. **Über Event-basierte Kommunikation**
5. **Über Abhängigkeiten in der Modulkonfiguration**

## 1. Interaktion über globale Daten

### Gemeinsame Datendateien

Module können auf gemeinsame Datendateien im Verzeichnis `data/Globale Daten/` zugreifen:

```powershell
# Beispiel: Lesen von gemeinsamen Einstellungen
$globalSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath "../../data/Globale Daten/common_settings.json"
$globalSettings = Get-Content -Path $globalSettingsPath -Raw | ConvertFrom-Json
```

### Dateistruktur für gemeinsame Daten

- **common_settings.json**: Allgemeine Einstellungen
- **system_state.json**: Systemzustand
- **shared_resources.json**: Gemeinsam genutzte Ressourcen

## 2. Interaktion über die Windows-Registry

MINTutil verwendet den Registry-Schlüssel `HKCU:\Software\MINTutil` für modulübergreifende Einstellungen:

```powershell
# Registry-Einstellung lesen
function Get-RegistrySetting {
    param (
        [Parameter(Mandatory=$true)][string]$Name,
        $DefaultValue = $null
    )
    
    try {
        $value = Get-ItemProperty -Path "HKCU:\Software\MINTutil" -Name $Name -ErrorAction SilentlyContinue
        if ($null -ne $value) {
            return $value.$Name
        }
    } catch {
        # Bei Fehler Standardwert zurückgeben
    }
    
    return $DefaultValue
}

# Registry-Einstellung schreiben
function Set-RegistrySetting {
    param (
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)]$Value
    )
    
    try {
        # Stelle sicher, dass der Registry-Pfad existiert
        if (-not (Test-Path -Path "HKCU:\Software\MINTutil")) {
            New-Item -Path "HKCU:\Software\MINTutil" -Force | Out-Null
        }
        
        # Wert speichern
        New-ItemProperty -Path "HKCU:\Software\MINTutil" -Name $Name -Value $Value -PropertyType String -Force | Out-Null
        return $true
    } catch {
        Write-Error "Fehler beim Speichern von Registry-Einstellung '$Name': $_"
        return $false
    }
}
```

Module können auch eigene Registry-Schlüssel unter dem Hauptschlüssel haben:

```powershell
$moduleRegistry = "HKCU:\Software\MINTutil\ModulName"
```

## 3. Interaktion über exportierte PowerShell-Funktionen

Module können Funktionen exportieren, die von anderen Modulen genutzt werden können:

```powershell
# Im Modul A (export.ps1)
function Get-ModuleAData {
    # Implementierung
}

# Funktion exportieren
Export-ModuleMember -Function Get-ModuleAData

# In Modul B (verwenden)
if (Get-Command "Get-ModuleAData" -ErrorAction SilentlyContinue) {
    $dataFromModuleA = Get-ModuleAData
}
```

### Best Practices für Funktionsexport

- Exportieren Sie nur die notwendigen Funktionen mit klaren Namen
- Dokumentieren Sie die API-Schnittstelle für andere Modulentwickler
- Behandeln Sie Fehler robust, um andere Module nicht zu beeinträchtigen

## 4. Event-basierte Kommunikation

Module können über PowerShell-Events kommunizieren:

```powershell
# In Modul A: Event-Quelle registrieren
$modulAEventSource = New-Object System.Management.Automation.PSObject
Register-ObjectEvent -InputObject $modulAEventSource -EventName DataChanged -Action {
    param($sender, $eventArgs)
    # Aktion bei Ereignis
}

# In Modul B: Event auslösen
$event = [PSCustomObject]@{
    Source = "ModulB"
    Data = $someData
}
$modulAEventSource.DataChanged($modulAEventSource, $event)
```

### Beispiel für einen Ereignisbus

```powershell
# Globaler Ereignisbus (in main.ps1)
$script:EventBus = @{
    Subscribers = @{}
}

function Register-EventHandler {
    param(
        [string]$EventName,
        [scriptblock]$Handler
    )
    
    if (-not $script:EventBus.Subscribers.ContainsKey($EventName)) {
        $script:EventBus.Subscribers[$EventName] = @()
    }
    
    $script:EventBus.Subscribers[$EventName] += $Handler
}

function Publish-Event {
    param(
        [string]$EventName,
        $Data
    )
    
    if ($script:EventBus.Subscribers.ContainsKey($EventName)) {
        foreach ($handler in $script:EventBus.Subscribers[$EventName]) {
            & $handler $Data
        }
    }
}

# Verwendung in Modulen
Register-EventHandler -EventName "AppInstalled" -Handler {
    param($Data)
    Write-Host "App installiert: $($Data.AppName)"
}

Publish-Event -EventName "AppInstalled" -Data @{
    AppName = "Firefox"
    Timestamp = Get-Date
}
```

## 5. Abhängigkeiten in der Modulkonfiguration

Module können Abhängigkeiten in ihrer `modulinfo.json`-Datei deklarieren:

```json
{
  "name": "ModulName",
  "dependencies": [
    {
      "module": "RequiredModule",
      "version": "1.0.0",
      "optional": false
    }
  ]
}
```

Das Hauptprogramm kann diese Abhängigkeiten überprüfen und sicherstellen, dass Module in der richtigen Reihenfolge geladen werden.

## Beispiel: Interaktion zwischen Installer und SystemInfo

### 1. Installer informiert SystemInfo über Änderungen

```powershell
# In Installer-Modul nach Installation einer App
function Notify-SystemChange {
    param(
        [string]$ChangeType,
        $ChangeData
    )
    
    # Option 1: Über Registry
    Set-RegistrySetting -Name "LastSystemChange" -Value (Get-Date).ToString("o")
    
    # Option 2: Über Event
    Publish-Event -EventName "SystemChanged" -Data @{
        Type = $ChangeType
        Data = $ChangeData
        Timestamp = Get-Date
    }
}

# Nach Installation aufrufen
Notify-SystemChange -ChangeType "SoftwareInstalled" -ChangeData @{
    AppName = $app.Name
    AppId = $app.Id
}
```

### 2. SystemInfo reagiert auf Änderungen

```powershell
# In SystemInfo-Modul
function Initialize-SystemInfo {
    # Event-Handler registrieren
    Register-EventHandler -EventName "SystemChanged" -Handler {
        param($Data)
        
        if ($Data.Type -eq "SoftwareInstalled") {
            Write-Host "Neue Software erkannt: $($Data.Data.AppName)"
            # Cache aktualisieren
            Refresh-SystemData
        }
    }
}
```

## Best Practices für Modul-Interaktionen

1. **Lose Kopplung bevorzugen**: Module sollten möglichst unabhängig bleiben
2. **Klare Schnittstellen definieren**: Eindeutige und stabile APIs für die Kommunikation
3. **Fehlerbehandlung**: Robuste Fehlerbehandlung, um Ausfallsicherheit zu gewährleisten
4. **Dokumentation**: Schnittstellen und Interaktionsmuster dokumentieren
5. **Versionierung**: Schnittstellen zwischen Modulen versionieren
6. **Minimale Abhängigkeiten**: Nur notwendige Abhängigkeiten definieren

## Fazit

Die modulare Architektur von MINTutil bietet verschiedene Wege für die Interaktion zwischen Modulen. Diese Flexibilität ermöglicht es, sowohl lose gekoppelte als auch eng integrierte Module zu entwickeln, je nach Anforderung. Durch die Verwendung gemeinsamer Daten, Registry-Einstellungen, exportierter Funktionen, Events und deklarierter Abhängigkeiten können Module effektiv und robust kommunizieren, während sie gleichzeitig ihre Unabhängigkeit bewahren.