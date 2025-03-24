# Anleitung zum Erstellen eines neuen MINTutil-Moduls

Diese Anleitung beschreibt den Prozess zum Erstellen eines neuen Moduls für MINTutil.

## Übersicht der Modulstruktur

Jedes Modul in MINTutil besteht aus mehreren Komponenten, die in verschiedenen Verzeichnissen organisiert sind:

```
MINTutil/
├── modules/ModulName/           # PowerShell-Hauptcode
├── config/ModulName/            # UI und Konfiguration
├── data/ModulName/              # Daten
├── meta/ModulName/              # Metadaten
└── docs/ModulName/              # Dokumentation
```

## Schritte zum Erstellen eines neuen Moduls

### 1. Verzeichnisstruktur erstellen

Erstellen Sie die Basisverzeichnisse für Ihr neues Modul:

```powershell
$ModuleName = "MeinNeuesModul"
New-Item -Path "modules/$ModuleName" -ItemType Directory -Force
New-Item -Path "config/$ModuleName" -ItemType Directory -Force
New-Item -Path "data/$ModuleName" -ItemType Directory -Force
New-Item -Path "meta/$ModuleName" -ItemType Directory -Force
New-Item -Path "docs/$ModuleName" -ItemType Directory -Force
```

### 2. Metadatendateien erstellen

Erstellen Sie die beiden erforderlichen Metadatendateien:

**meta.json**:
```powershell
@"
{
  "label": "$ModuleName",
  "icon": "gear",
  "order": 10,
  "enabled": true
}
"@ | Set-Content -Path "meta/$ModuleName/meta.json"
```

**modulinfo.json**:
```powershell
@"
{
  "name": "$ModuleName",
  "description": "Beschreibung des Moduls und seiner Funktionen.",
  "entry": "modules/$ModuleName/$($ModuleName.ToLower()).ps1",
  "config": [
    "config/$ModuleName/config.json",
    "config/global.config.json"
  ],
  "data": [
    "data/$ModuleName/data.json"
  ],
  "generates": [
    "data/$ModuleName/output.json"
  ],
  "ui": {
    "type": "tab",
    "dynamicFields": false,
    "includes": ["feature1", "feature2"]
  },
  "preserve": true
}
"@ | Set-Content -Path "meta/$ModuleName/modulinfo.json"
```

### 3. UI-XAML-Datei erstellen

Erstellen Sie die XAML-UI-Datei:

```powershell
@"
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
  <Grid.ColumnDefinitions>
    <ColumnDefinition Width="220"/>
    <ColumnDefinition Width="Auto"/>
    <ColumnDefinition Width="*"/>
  </Grid.ColumnDefinitions>

  <!-- Linkes Panel für Aktionen -->
  <StackPanel Grid.Column="0" Margin="0,0,10,0">
    <TextBlock Text="Aktionen" FontWeight="Bold" FontSize="14" Margin="0,0,0,10"/>
    <Button Name="BtnAction1" Content="Aktion 1" Margin="0,5,0,0" Padding="6"/>
    <Button Name="BtnAction2" Content="Aktion 2" Margin="0,5,0,0" Padding="6"/>
  </StackPanel>

  <!-- Visuelle Trennung -->
  <Border Grid.Column="1" Width="1" Background="#DDDDDD" Margin="5,0"/>

  <!-- Hauptinhalt -->
  <StackPanel Grid.Column="2" Margin="10,0,0,0">
    <TextBlock Text="$ModuleName" FontWeight="Bold" FontSize="14" Margin="0,0,0,10"/>
    <!-- Hier den Hauptinhalt der UI einfügen -->
    <TextBlock Text="Hauptinhalt des Moduls" Margin="0,5,0,5"/>
  </StackPanel>
</Grid>
"@ | Set-Content -Path "config/$ModuleName/ui.xaml"
```

### 4. PowerShell-Hauptcode erstellen

Erstellen Sie die Hauptskriptdatei:

```powershell
$modulScript = @"
# $ModuleName-Modul für MINTutil
# Beschreibung der Modulfunktionalität

# Globale Variablen
`$script:${ModuleName}BasePath = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$script:ConfigPath = Join-Path -Path `$PSScriptRoot -ChildPath "../../config/$ModuleName/config.json"
`$script:DataPath = Join-Path -Path `$PSScriptRoot -ChildPath "../../data/$ModuleName/data.json"
`$script:OutputPath = Join-Path -Path `$PSScriptRoot -ChildPath "../../data/$ModuleName/output.json"
`$script:${ModuleName}UI = `$null

# ============= Initialisierungsfunktionen =============

function Initialize-$ModuleName {
    param(
        [Parameter(Mandatory=`$true)]`$Window
    )
    try {
        `$script:${ModuleName}UI = `$Window
        
        # Sicherstellen, dass Verzeichnisse existieren
        if (-not (Test-Path -Path (Split-Path -Parent `$script:DataPath))) {
            New-Item -Path (Split-Path -Parent `$script:DataPath) -ItemType Directory -Force | Out-Null
        }
        
        # Event-Handler für Buttons einrichten
        Register-EventHandlers
        
        # Initialen Zustand laden oder erstellen
        Initialize-ModuleData
        
        Write-Host "$ModuleName-Modul initialisiert"
        return `$true
    } catch {
        Write-Error "Fehler bei der Initialisierung des $ModuleName-Moduls: `$_"
        return `$false
    }
}

function Register-EventHandlers {
    try {
        # Button-Event-Handler registrieren
        `$btnAction1 = `$script:${ModuleName}UI.FindName("BtnAction1")
        `$btnAction2 = `$script:${ModuleName}UI.FindName("BtnAction2")
        
        `$btnAction1.Add_Click({ Invoke-Action1 })
        `$btnAction2.Add_Click({ Invoke-Action2 })
        
        Write-Host "Event-Handler für $ModuleName-Modul registriert"
    } catch {
        Write-Error "Fehler beim Registrieren der Event-Handler: `$_"
        throw `$_
    }
}

function Initialize-ModuleData {
    try {
        # Prüfen, ob Datendatei existiert
        if (Test-Path -Path `$script:DataPath) {
            # Daten laden
            `$data = Get-Content -Path `$script:DataPath -Raw | ConvertFrom-Json
            Write-Host "Moduldaten geladen"
        } else {
            # Standarddaten erstellen
            `$data = @{
                Created = Get-Date
                Settings = @{
                    Option1 = "Standardwert"
                    Option2 = `$true
                }
                Items = @()
            }
            
            # Daten speichern
            `$data | ConvertTo-Json -Depth 4 | Set-Content -Path `$script:DataPath -Force
            Write-Host "Standarddaten erstellt"
        }
        
        # UI mit Daten aktualisieren
        Update-UI -Data `$data
        
        return `$data
    } catch {
        Write-Error "Fehler beim Initialisieren der Moduldaten: `$_"
        throw `$_
    }
}

# ============= Aktionsfunktionen =============

function Invoke-Action1 {
    try {
        # Implementierung von Aktion 1
        Write-Host "Aktion 1 ausgeführt"
        
        [System.Windows.MessageBox]::Show(
            "Aktion 1 wurde erfolgreich ausgeführt.", 
            "Information", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Information)
    } catch {
        Write-Error "Fehler bei Aktion 1: `$_"
        [System.Windows.MessageBox]::Show(
            "Fehler bei Aktion 1: `$_", 
            "Fehler", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Error)
    }
}

function Invoke-Action2 {
    try {
        # Implementierung von Aktion 2
        Write-Host "Aktion 2 ausgeführt"
        
        [System.Windows.MessageBox]::Show(
            "Aktion 2 wurde erfolgreich ausgeführt.", 
            "Information", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Information)
    } catch {
        Write-Error "Fehler bei Aktion 2: `$_"
        [System.Windows.MessageBox]::Show(
            "Fehler bei Aktion 2: `$_", 
            "Fehler", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Error)
    }
}

# ============= UI-Funktionen =============

function Update-UI {
    param(
        [Parameter(Mandatory=`$true)]`$Data
    )
    
    try {
        # UI-Elemente mit Daten aktualisieren
        # Beispiel:
        # `$textBlock = `$script:${ModuleName}UI.FindName("TextBlock1")
        # `$textBlock.Text = `$Data.Settings.Option1
        
        Write-Host "UI aktualisiert"
    } catch {
        Write-Error "Fehler beim Aktualisieren der UI: `$_"
    }
}

# Exportiere die Initialisierungsfunktion für main.ps1
Export-ModuleMember -Function Initialize-$ModuleName
"@

# Script-Datei speichern
$modulScript | Set-Content -Path "modules/$ModuleName/$($ModuleName.ToLower()).ps1"
```

### 5. Konfigurationsdatei erstellen

Erstellen Sie eine Konfigurationsdatei:

```powershell
@"
{
  "settings": {
    "option1": "Wert1",
    "option2": true,
    "option3": 42
  },
  "ui": {
    "theme": "default",
    "layout": "standard"
  },
  "advanced": {
    "feature1Enabled": true,
    "feature2Enabled": false,
    "debugMode": false
  }
}
"@ | Set-Content -Path "config/$ModuleName/config.json"
```

### 6. Datendatei erstellen

Erstellen Sie eine Beispieldatendatei:

```powershell
@"
{
  "created": "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")",
  "settings": {
    "option1": "Standardwert",
    "option2": true
  },
  "items": [
    {
      "id": "item1",
      "name": "Beispielitem 1",
      "value": 42
    },
    {
      "id": "item2",
      "name": "Beispielitem 2",
      "value": 84
    }
  ]
}
"@ | Set-Content -Path "data/$ModuleName/data.json"
```

### 7. Dokumentation erstellen

Erstellen Sie eine Moduldokumentation:

```powershell
@"
# $ModuleName Modul

## Übersicht

Dieses Modul bietet [Beschreibung der Funktionalität].

## Funktionen

- Funktion 1: Beschreibung der ersten Funktion
- Funktion 2: Beschreibung der zweiten Funktion

## Konfiguration

Das Modul kann über die Datei `config/$ModuleName/config.json` konfiguriert werden.

### Konfigurationsoptionen

- `option1`: Beschreibung der Option 1
- `option2`: Beschreibung der Option 2
- `option3`: Beschreibung der Option 3

## Datendateien

Das Modul verwendet folgende Datendateien:

- `data/$ModuleName/data.json`: Speichert [Beschreibung der Daten]
- `data/$ModuleName/output.json`: Enthält [Beschreibung der Ausgabedaten]

## Verwendung

1. Öffnen Sie das $ModuleName-Tab in MINTutil
2. Verwenden Sie [Beschreibung der Verwendung]
3. [Weitere Schritte]
"@ | Set-Content -Path "docs/$ModuleName/readme.md"
```

## Integrieren des neuen Moduls

Nachdem Sie alle erforderlichen Dateien erstellt haben, wird das Modul beim nächsten Start von MINTutil automatisch erkannt und geladen, sofern die Metadaten korrekt sind und die `enabled`-Eigenschaft auf `true` gesetzt ist.

## Beispielmodule

Als Referenz können Sie sich die bestehenden Module anschauen:

- **Installer-Modul**: Stellt Funktionen zur Softwareinstallation bereit
- **SystemInfo-Modul**: Zeigt System- und Hardwareinformationen an

Diese Module verwenden das gleiche Grundmuster und können als Vorlage für neue Module dienen.

## Testen des neuen Moduls

Starten Sie MINTutil und überprüfen Sie, ob Ihr neues Modul als Tab in der Benutzeroberfläche erscheint. Überprüfen Sie auch die Konsole auf Fehlermeldungen oder Warnungen, falls das Modul nicht ordnungsgemäß geladen wird.