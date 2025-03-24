# Module Structure Manager
# Dieses Skript implementiert die Regel für die Erstellung neuer Modulstrukturen
# Wenn ein neues Modul im modules/-Ordner angelegt wird, werden automatisch die notwendigen Unterordner und Dateien erstellt

function New-ModuleStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    try {
        Write-Host "Erstelle Modulstruktur für $ModuleName..." -ForegroundColor Cyan

        # Basisverzeichnis ermitteln
        $baseDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

        # Prüfen, ob das Modul bereits existiert
        $moduleDir = Join-Path -Path $baseDir -ChildPath "modules\$ModuleName"
        if (-not (Test-Path -Path $moduleDir)) {
            Write-Error "Modul-Verzeichnis $ModuleName existiert nicht in modules/"
            return $false
        }

        # Erstelle Unterordner in config, data, docs und meta
        $directories = @(
            "config\$ModuleName",
            "data\$ModuleName",
            "docs\$ModuleName",
            "meta\$ModuleName"
        )

        foreach ($dir in $directories) {
            $path = Join-Path -Path $baseDir -ChildPath $dir
            if (-not (Test-Path -Path $path)) {
                New-Item -Path $path -ItemType Directory -Force | Out-Null
                Write-Host "  Verzeichnis erstellt: $dir" -ForegroundColor Green
            } else {
                Write-Host "  Verzeichnis existiert bereits: $dir" -ForegroundColor Yellow
            }
        }

        # Extrahiere die Modulnummer und den Namen für die Beschreibung
        $moduleNumber = $ModuleName -replace "^M(\d+)_.*$", '$1'
        $moduleDisplayName = ($ModuleName -replace "^M\d+_", "") -replace "_", " "
        $moduleDisplayName = (Get-Culture).TextInfo.ToTitleCase($moduleDisplayName)

        # Erstelle meta.json
        $metaJsonPath = Join-Path -Path $baseDir -ChildPath "meta\$ModuleName\meta.json"
        if (-not (Test-Path -Path $metaJsonPath)) {
            $metaJson = @{
                label   = $moduleDisplayName
                icon    = "box-select"  # Standard-Icon, kann später angepasst werden
                order   = [int]$moduleNumber
                enabled = $true
            } | ConvertTo-Json -Depth 3

            Set-Content -Path $metaJsonPath -Value $metaJson
            Write-Host "  Datei erstellt: meta\$ModuleName\meta.json" -ForegroundColor Green
        }

        # Erstelle modulinfo.json
        $modulinfoJsonPath = Join-Path -Path $baseDir -ChildPath "meta\$ModuleName\modulinfo.json"
        if (-not (Test-Path -Path $modulinfoJsonPath)) {
            # Bestimme den Skriptnamen basierend auf dem Modulnamen
            $scriptName = ($ModuleName -replace "^M\d+_", "").ToLower() + ".ps1"

            $modulinfoJson = @{
                name        = $ModuleName
                description = "Modul für $moduleDisplayName-Funktionalität. Beschreibung anpassen."
                entry       = "modules/$ModuleName/$scriptName"
                config      = @(
                    "config/$ModuleName/ui.xaml",
                    "config/global/global.config.json"
                )
                data        = @()
                generates   = @()
                ui          = @{
                    type          = "tab"
                    dynamicFields = $true
                    includes      = @("actions", "statusbar")
                }
                preserve    = $true
            } | ConvertTo-Json -Depth 3

            Set-Content -Path $modulinfoJsonPath -Value $modulinfoJson
            Write-Host "  Datei erstellt: meta\$ModuleName\modulinfo.json" -ForegroundColor Green
        }

        # Erstelle ui.xaml
        $uiXamlPath = Join-Path -Path $baseDir -ChildPath "config\$ModuleName\ui.xaml"
        if (-not (Test-Path -Path $uiXamlPath)) {
            $uiXaml = @"
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
  <Grid.ColumnDefinitions>
    <ColumnDefinition Width="220"/>
    <ColumnDefinition Width="Auto"/>
    <ColumnDefinition Width="*"/>
  </Grid.ColumnDefinitions>

  <!-- Actions Panel -->
  <StackPanel Grid.Column="0" Margin="0,0,10,0">
    <TextBlock Text="Aktionen" FontWeight="Bold" FontSize="14" Margin="0,0,0,10"/>
    <Button Name="BtnAction1" Content="Aktion 1" Margin="0,5,0,0" Padding="6"/>
    <Button Name="BtnAction2" Content="Aktion 2" Margin="0,5,0,0" Padding="6"/>
    <Button Name="BtnAction3" Content="Aktion 3" Margin="0,5,0,0" Padding="6"/>
  </StackPanel>

  <!-- Visuelle Trennung -->
  <Border Grid.Column="1" Width="1" Background="#DDDDDD" Margin="5,0"/>

  <!-- Hauptbereich -->
  <StackPanel Grid.Column="2" Margin="10,0,0,0">
    <TextBlock Text="$moduleDisplayName" FontWeight="Bold" FontSize="14" Margin="0,0,0,10"/>
    <TextBlock Name="StatusText" Text="Bereit" Margin="0,5,0,0" Foreground="DarkSlateGray"/>
  </StackPanel>
</Grid>
"@

            Set-Content -Path $uiXamlPath -Value $uiXaml
            Write-Host "  Datei erstellt: config\$ModuleName\ui.xaml" -ForegroundColor Green
        }

        # Erstelle Dokumentationsdateien
        $docFiles = @(
            "1_Einführung.md",
            "2_Anwendungsfälle.md",
            "3_Benutzererfahrung.md",
            "4_Funktionalitäten.md",
            "5_Dokumentation.md"
        )

        foreach ($docFile in $docFiles) {
            $docPath = Join-Path -Path $baseDir -ChildPath "docs\$ModuleName\$docFile"
            if (-not (Test-Path -Path $docPath)) {
                $docContent = ""

                # Inhalt je nach Datei generieren
                switch ($docFile) {
                    "1_Einführung.md" {
                        $docContent = @"
# Kapitel 1: Einführung zum ${moduleDisplayName}-Modul (${ModuleName})

## 1.1 Zweck der Funktion
### 1.1.1 Definition des Problems
Das ${moduleDisplayName}-Modul löst das Problem [Problem beschreiben]. Ohne ein solches Tool müssen Benutzer [aktuelle Herausforderungen beschreiben].

### 1.1.2 Ziele der Funktion
Das ${moduleDisplayName}-Modul zielt darauf ab:
- [Ziel 1]
- [Ziel 2]
- [Ziel 3]
- [Ziel 4]

## 1.2 Zielgruppe
### 1.2.1 Hauptnutzer
Die Hauptnutzer des ${moduleDisplayName}-Moduls sind:
- [Nutzergruppe 1]
- [Nutzergruppe 2]
- [Nutzergruppe 3]

### 1.2.2 Stakeholder
Indirekte Nutznießer des ${moduleDisplayName}-Moduls sind:
- [Stakeholder 1]
- [Stakeholder 2]
- [Stakeholder 3]

## 1.3 Hauptnutzen
### 1.3.1 Effizienzsteigerung
Das ${moduleDisplayName}-Modul reduziert den Arbeitsaufwand durch:
- [Effizienzgewinn 1]
- [Effizienzgewinn 2]
- [Effizienzgewinn 3]

### 1.3.2 Kostensenkung
Die finanziellen und zeitlichen Einsparungen umfassen:
- [Kosteneinsparung 1]
- [Kosteneinsparung 2]
- [Kosteneinsparung 3]
"@
                    }
                    "2_Anwendungsfälle.md" {
                        $docContent = @"
# Kapitel 2: Anwendungsfälle für das ${moduleDisplayName}-Modul (${ModuleName})

## 2.1 Hauptanwendungsfälle
### 2.1.1 Anwendungsfall 1
**Szenario:** [Beschreibung des Szenarios]

**Akteure:** [Beteiligte Nutzer]

**Ablauf:**
1. [Schritt 1]
2. [Schritt 2]
3. [Schritt 3]

**Ergebnis:** [Erwartetes Ergebnis]

### 2.1.2 Anwendungsfall 2
**Szenario:** [Beschreibung des Szenarios]

**Akteure:** [Beteiligte Nutzer]

**Ablauf:**
1. [Schritt 1]
2. [Schritt 2]
3. [Schritt 3]

**Ergebnis:** [Erwartetes Ergebnis]

## 2.2 Sekundäre Anwendungsfälle
### 2.2.1 Anwendungsfall 3
**Szenario:** [Beschreibung des Szenarios]

**Akteure:** [Beteiligte Nutzer]

**Ablauf:**
1. [Schritt 1]
2. [Schritt 2]
3. [Schritt 3]

**Ergebnis:** [Erwartetes Ergebnis]

## 2.3 Integration mit anderen Modulen
### 2.3.1 Integration mit [anderes Modul]
**Beschreibung:** [Wie dieses Modul mit anderen Modulen interagiert]

**Vorteile:**
- [Vorteil 1]
- [Vorteil 2]

**Implementierungsdetails:**
- [Detail 1]
- [Detail 2]
"@
                    }
                    "3_Benutzererfahrung.md" {
                        $docContent = @"
# Kapitel 3: Benutzererfahrung des ${moduleDisplayName}-Moduls (${ModuleName})

## 3.1 Benutzeroberfläche
### 3.1.1 Hauptelemente
- **[Element 1]:** [Beschreibung und Zweck]
- **[Element 2]:** [Beschreibung und Zweck]
- **[Element 3]:** [Beschreibung und Zweck]

### 3.1.2 Interaktionsmuster
- **[Muster 1]:** [Beschreibung]
- **[Muster 2]:** [Beschreibung]

## 3.2 Benutzerworkflows
### 3.2.1 Workflow 1: [Name]
1. [Schritt 1]
2. [Schritt 2]
3. [Schritt 3]

### 3.2.2 Workflow 2: [Name]
1. [Schritt 1]
2. [Schritt 2]
3. [Schritt 3]

## 3.3 Barrierefreiheit und Benutzerfreundlichkeit
### 3.3.1 Barrierefreiheitsmerkmale
- [Merkmal 1]
- [Merkmal 2]
- [Merkmal 3]

### 3.3.2 Benutzerfreundlichkeitsoptimierungen
- [Optimierung 1]
- [Optimierung 2]
- [Optimierung 3]

## 3.4 Feedback und Fehlermeldungen
### 3.4.1 Feedbackmechanismen
- [Mechanismus 1]
- [Mechanismus 2]

### 3.4.2 Fehlerbehandlung
- [Fehlertyp 1]: [Behandlungsstrategie]
- [Fehlertyp 2]: [Behandlungsstrategie]
"@
                    }
                    "4_Funktionalitäten.md" {
                        $docContent = @"
# Kapitel 4: Funktionalitäten des ${moduleDisplayName}-Moduls (${ModuleName})

## 4.1 Kernfunktionen
### 4.1.1 Funktion 1: [Name]
**Beschreibung:** [Detaillierte Beschreibung]

**Parameter:**
- [Parameter 1]: [Beschreibung]
- [Parameter 2]: [Beschreibung]

**Rückgabewerte:**
- [Rückgabewert 1]: [Beschreibung]
- [Rückgabewert 2]: [Beschreibung]

**Beispiel:**
```powershell
# Beispielcode
```

### 4.1.2 Funktion 2: [Name]
**Beschreibung:** [Detaillierte Beschreibung]

**Parameter:**
- [Parameter 1]: [Beschreibung]
- [Parameter 2]: [Beschreibung]

**Rückgabewerte:**
- [Rückgabewert 1]: [Beschreibung]
- [Rückgabewert 2]: [Beschreibung]

**Beispiel:**
```powershell
# Beispielcode
```

## 4.2 Hilfsfunktionen
### 4.2.1 Hilfsfunktion 1: [Name]
**Beschreibung:** [Detaillierte Beschreibung]

**Verwendung:**
```powershell
# Beispielcode
```

## 4.3 Datenstrukturen
### 4.3.1 [Datenstruktur 1]
**Format:**
```json
{
  "eigenschaft1": "wert1",
  "eigenschaft2": "wert2"
}
```

**Beschreibung der Eigenschaften:**
- `eigenschaft1`: [Beschreibung]
- `eigenschaft2`: [Beschreibung]

## 4.4 Konfigurationsoptionen
### 4.4.1 UI-Konfiguration
**Datei:** `config/$ModuleName/ui.xaml`

**Anpassbare Elemente:**
- [Element 1]: [Beschreibung]
- [Element 2]: [Beschreibung]

### 4.4.2 Funktionskonfiguration
**Datei:** [Konfigurationsdatei]

**Optionen:**
- [Option 1]: [Beschreibung]
- [Option 2]: [Beschreibung]
"@
                    }
                    "5_Dokumentation.md" {
                        $docContent = @"
# Kapitel 5: Dokumentation des ${moduleDisplayName}-Moduls (${ModuleName})

## 5.1 Installation und Einrichtung
### 5.1.1 Voraussetzungen
- [Voraussetzung 1]
- [Voraussetzung 2]
- [Voraussetzung 3]

### 5.1.2 Installationsschritte
1. [Schritt 1]
2. [Schritt 2]
3. [Schritt 3]

## 5.2 Konfiguration
### 5.2.1 Grundkonfiguration
```powershell
# Beispielkonfiguration
```

### 5.2.2 Erweiterte Konfiguration
- [Konfigurationsoption 1]: [Beschreibung]
- [Konfigurationsoption 2]: [Beschreibung]

## 5.3 Fehlerbehebung
### 5.3.1 Häufige Probleme und Lösungen
**Problem 1:** [Beschreibung]
**Lösung:** [Lösungsschritte]

**Problem 2:** [Beschreibung]
**Lösung:** [Lösungsschritte]

### 5.3.2 Logging und Diagnose
- [Logdatei 1]: [Beschreibung und Speicherort]
- [Diagnosewerkzeug 1]: [Beschreibung und Verwendung]

## 5.4 Wartung und Updates
### 5.4.1 Regelmäßige Wartungsaufgaben
- [Aufgabe 1]: [Beschreibung und Häufigkeit]
- [Aufgabe 2]: [Beschreibung und Häufigkeit]

### 5.4.2 Update-Verfahren
1. [Schritt 1]
2. [Schritt 2]
3. [Schritt 3]

## 5.5 Referenzen
### 5.5.1 Interne Referenzen
- [Referenz 1]
- [Referenz 2]

### 5.5.2 Externe Referenzen
- [Referenz 1]
- [Referenz 2]
"@
                    }
                }

                Set-Content -Path $docPath -Value $docContent
                Write-Host "  Datei erstellt: docs\$ModuleName\$docFile" -ForegroundColor Green
            }
        }

        # Prüfe, ob ein PowerShell-Skript im Modul-Verzeichnis existiert
        $psFiles = Get-ChildItem -Path $moduleDir -Filter "*.ps1"
        if ($psFiles.Count -eq 0) {
            # Erstelle ein Basis-PowerShell-Skript
            $scriptName = ($ModuleName -replace "^M\d+_", "").ToLower() + ".ps1"
            $scriptPath = Join-Path -Path $moduleDir -ChildPath $scriptName

            $scriptContent = @"
# $ModuleName-Modul für MINTutil
# Beschreibung: Dieses Modul implementiert $moduleDisplayName-Funktionalität

# Globale Variablen
`$script:${moduleDisplayName}BasePath = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$script:${moduleDisplayName}UI = `$null

# ============= Initialisierungsfunktionen =============

<#
.SYNOPSIS
    Initialisiert das $ModuleName-Modul.
.DESCRIPTION
    Diese Funktion wird beim Laden des Moduls aufgerufen und richtet die Benutzeroberfläche ein.
.PARAMETER Window
    Das WPF-Fenster, in dem das Modul angezeigt wird.
.EXAMPLE
    Initialize-$ModuleName -Window `$mainWindow
#>
function Initialize-$ModuleName {
    param(
        [Parameter(Mandatory=`$true)]`$Window
    )
    try {
        `$script:${moduleDisplayName}UI = `$Window

        # Event-Handler für Buttons einrichten
        Register-EventHandlers

        Write-Host "$ModuleName-Modul initialisiert"
        return `$true
    } catch {
        Write-Error ("Fehler bei der Initialisierung des " + $ModuleName + "-Moduls: " + $_)
        return `$false
    }
}

<#
.SYNOPSIS
    Registriert Event-Handler für UI-Elemente.
.DESCRIPTION
    Diese Funktion registriert die Event-Handler für Buttons und andere UI-Elemente.
#>
function Register-EventHandlers {
    try {
        # Button-Event-Handler registrieren
        `$btnAction1 = `$script:${moduleDisplayName}UI.FindName("BtnAction1")
        `$btnAction2 = `$script:${moduleDisplayName}UI.FindName("BtnAction2")
        `$btnAction3 = `$script:${moduleDisplayName}UI.FindName("BtnAction3")

        `$btnAction1.Add_Click({ Invoke-Action1 })
        `$btnAction2.Add_Click({ Invoke-Action2 })
        `$btnAction3.Add_Click({ Invoke-Action3 })

        Write-Host "Event-Handler für $ModuleName-Modul registriert"
    } catch {
        Write-Error ("Fehler beim Registrieren der Event-Handler: " + $_)
        throw $_
    }
}

# ============= Aktionsfunktionen =============

<#
.SYNOPSIS
    Führt Aktion 1 aus.
.DESCRIPTION
    Diese Funktion implementiert die Funktionalität für Aktion 1.
#>
function Invoke-Action1 {
    try {
        # Implementierung für Aktion 1
        Update-StatusText "Aktion 1 ausgeführt"
        Write-Host "Aktion 1 wurde ausgeführt"
    } catch {
        Write-Error ("Fehler bei Aktion 1: " + $_)
        Update-StatusText "Fehler bei Aktion 1"
    }
}

<#
.SYNOPSIS
    Führt Aktion 2 aus.
.DESCRIPTION
    Diese Funktion implementiert die Funktionalität für Aktion 2.
#>
function Invoke-Action2 {
    try {
        # Implementierung für Aktion 2
        Update-StatusText "Aktion 2 ausgeführt"
        Write-Host "Aktion 2 wurde ausgeführt"
    } catch {
        Write-Error ("Fehler bei Aktion 2: " + $_)
        Update-StatusText "Fehler bei Aktion 2"
    }
}

<#
.SYNOPSIS
    Führt Aktion 3 aus.
.DESCRIPTION
    Diese Funktion implementiert die Funktionalität für Aktion 3.
#>
function Invoke-Action3 {
    try {
        # Implementierung für Aktion 3
        Update-StatusText "Aktion 3 ausgeführt"
        Write-Host "Aktion 3 wurde ausgeführt"
    } catch {
        Write-Error ("Fehler bei Aktion 3: " + $_)
        Update-StatusText "Fehler bei Aktion 3"
    }
}

# ============= Hilfsfunktionen =============

<#
.SYNOPSIS
    Aktualisiert den Statustext in der UI.
.DESCRIPTION
    Diese Funktion aktualisiert den Statustext in der Benutzeroberfläche.
.PARAMETER Text
    Der anzuzeigende Statustext.
#>
function Update-StatusText {
    param(
        [Parameter(Mandatory=`$true)][string]`$Text
    )

    `$statusText = `$script:${moduleDisplayName}UI.FindName("StatusText")
    `$statusText.Text = `$Text

    # UI aktualisieren
    [System.Windows.Forms.Application]::DoEvents()
}

# Exportiere die Initialisierungsfunktion für main.ps1
Export-ModuleMember -Function Initialize-$ModuleName
"@

            Set-Content -Path $scriptPath -Value $scriptContent
            Write-Host "  Datei erstellt: modules\$ModuleName\$scriptName" -ForegroundColor Green
        }

        Write-Host "Modulstruktur für $ModuleName erfolgreich erstellt!" -ForegroundColor Green
        return $true
    } catch {
        Write-Error ("Fehler beim Erstellen der Modulstruktur für " + $ModuleName + ": " + $_)
        return $false
    }
}

<#
.SYNOPSIS
    Überwacht das modules/-Verzeichnis auf neue Module und erstellt die entsprechende Struktur.
.DESCRIPTION
    Diese Funktion überwacht das modules/-Verzeichnis auf neue Module und erstellt automatisch
    die notwendigen Unterordner und Dateien gemäß den Projektstandards.
#>
function Watch-ModuleDirectory {
    [CmdletBinding()]
    param()

    try {
        # Basisverzeichnis ermitteln
        $baseDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $modulesDir = Join-Path -Path $baseDir -ChildPath "modules"

        Write-Host "Überwache Verzeichnis: $modulesDir" -ForegroundColor Cyan

        # Bestehende Module erfassen
        $existingModules = Get-ChildItem -Path $modulesDir -Directory |
        Where-Object { $_.Name -match "^M\d+_" } |
        Select-Object -ExpandProperty Name

        Write-Host "Gefundene Module: $($existingModules -join ', ')" -ForegroundColor Gray

        # FileSystemWatcher einrichten
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $modulesDir
        $watcher.IncludeSubdirectories = $false
        $watcher.EnableRaisingEvents = $true

        # Event für neue Verzeichnisse
        $action = {
            $path = $Event.SourceEventArgs.FullPath
            $name = Split-Path -Path $path -Leaf

            # Nur für Module mit dem Muster "M\d+_*"
            if ($name -match "^M\d+_") {
                Write-Host "Neues Modul erkannt: $name" -ForegroundColor Yellow

                # Warte kurz, um sicherzustellen, dass das Verzeichnis vollständig erstellt wurde
                Start-Sleep -Seconds 1

                # Modulstruktur erstellen
                $scriptBlock = {
                    param($moduleName, $scriptPath)
                    # Lade das Skript
                    . $scriptPath
                    # Führe die Funktion aus
                    New-ModuleStructure -ModuleName $moduleName
                }

                # Führe in einem neuen PowerShell-Prozess aus, um Berechtigungsprobleme zu vermeiden
                $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes(
                        ". '$PSCommandPath'; New-ModuleStructure -ModuleName '$name'"
                    ))

                Start-Process powershell.exe -ArgumentList "-NoProfile", "-EncodedCommand", $encodedCommand -Wait
            }
        }

        # Event-Handler registrieren
        $created = Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action

        Write-Host "Überwachung gestartet. Drücken Sie STRG+C zum Beenden." -ForegroundColor Green

        try {
            # Halte das Skript am Laufen
            while ($true) {
                Start-Sleep -Seconds 1
            }
        } finally {
            # Bereinigen beim Beenden
            $watcher.EnableRaisingEvents = $false
            Unregister-Event -SourceIdentifier $created.Name
            $watcher.Dispose()
            Write-Host "Überwachung beendet." -ForegroundColor Yellow
        }
    } catch {
        Write-Error ("Fehler bei der Überwachung des Modulverzeichnisses: " + $_)
    }
}

<#
.SYNOPSIS
    Prüft alle vorhandenen Module und erstellt fehlende Strukturen.
.DESCRIPTION
    Diese Funktion prüft alle vorhandenen Module im modules/-Verzeichnis und erstellt
    für jedes Modul die notwendigen Unterordner und Dateien, falls diese fehlen.
#>
function Update-AllModuleStructures {
    [CmdletBinding()]
    param()

    try {
        # Basisverzeichnis ermitteln
        $baseDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $modulesDir = Join-Path -Path $baseDir -ChildPath "modules"

        Write-Host "Prüfe alle Module im Verzeichnis: $modulesDir" -ForegroundColor Cyan

        # Alle Module erfassen
        $modules = Get-ChildItem -Path $modulesDir -Directory |
        Where-Object { $_.Name -match "^M\d+_" } |
        Select-Object -ExpandProperty Name

        if ($modules.Count -eq 0) {
            Write-Host "Keine Module gefunden." -ForegroundColor Yellow
            return
        }

        Write-Host "Gefundene Module: $($modules -join ', ')" -ForegroundColor Gray

        # Für jedes Modul die Struktur prüfen und ggf. erstellen
        foreach ($module in $modules) {
            Write-Host "Prüfe Modul: $module" -ForegroundColor Cyan
            $result = New-ModuleStructure -ModuleName $module

            if ($result) {
                Write-Host "Modul $module erfolgreich aktualisiert." -ForegroundColor Green
            } else {
                Write-Host "Fehler bei der Aktualisierung von Modul $module." -ForegroundColor Red
            }
        }

        Write-Host "Alle Module wurden überprüft und aktualisiert." -ForegroundColor Green
    } catch {
        Write-Error ("Fehler bei der Aktualisierung aller Modulstrukturen: " + $_)
    }
}

# Exportiere die Funktionen
Export-ModuleMember -Function New-ModuleStructure, Watch-ModuleDirectory, Update-AllModuleStructures
