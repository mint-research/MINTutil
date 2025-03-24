#Requires -Version 5.1
<#
.SYNOPSIS
    MINTutil - Modulares PowerShell-Tool für Windows-Systemverwaltung
.DESCRIPTION
    Modulares, datengetriebenes PowerShell-Tool mit grafischer Oberfläche zur
    Automatisierung von Softwareinstallation, Systemanpassung und Wartung unter Windows.
.NOTES
    Version: 10
#>

param (
    [switch]$Validate = $false,  # Validierung der Modulstruktur vor dem Start
    [string]$ModulePath = $null  # Direktes Laden eines bestimmten Moduls, falls angegeben
)

# Globale Variablen und Konstanten
$script:BasePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ConfigPath = Join-Path -Path $script:BasePath -ChildPath "config"
$script:GlobalConfigFile = Join-Path -Path $script:ConfigPath -ChildPath "global.config.json"
$script:MetaPath = Join-Path -Path $script:BasePath -ChildPath "meta"
$script:ModulesPath = Join-Path -Path $script:BasePath -ChildPath "modules"
$script:DataPath = Join-Path -Path $script:BasePath -ChildPath "data"
$script:ThemesPath = Join-Path -Path $script:BasePath -ChildPath "themes"

# PowerShell für GUI optimieren
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
[System.Windows.Forms.Application]::EnableVisualStyles()

# Hauptobjekte
$script:Window = $null  # Hauptfenster
$script:GlobalConfig = $null  # Globale Konfiguration
$script:Modules = @{}  # Geladene Module
$script:CurrentTheme = $null  # Aktuelles Theme

# Registry-Pfad für Einstellungen
$script:RegistryBasePath = "HKCU:\Software\MINTutil"

# ============= Hilfsfunktionen =============

function Initialize-RegistryStore {
    # Erstellt den Registry-Pfad für MINTutil falls nicht vorhanden
    if (-not (Test-Path -Path $script:RegistryBasePath)) {
        New-Item -Path $script:RegistryBasePath -Force | Out-Null
        Write-Host "Registry-Speicher initialisiert: $script:RegistryBasePath"
    }
}

function Get-RegistrySetting {
    param (
        [Parameter(Mandatory=$true)][string]$Name,
        $DefaultValue = $null
    )
    
    try {
        $value = Get-ItemProperty -Path $script:RegistryBasePath -Name $Name -ErrorAction SilentlyContinue
        if ($null -ne $value) {
            return $value.$Name
        }
    } catch {
        # Bei Fehler Standardwert zurückgeben
    }
    
    return $DefaultValue
}

function Set-RegistrySetting {
    param (
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)]$Value
    )
    
    try {
        # Stelle sicher, dass der Registry-Pfad existiert
        if (-not (Test-Path -Path $script:RegistryBasePath)) {
            New-Item -Path $script:RegistryBasePath -Force | Out-Null
        }
        
        # Wert speichern
        New-ItemProperty -Path $script:RegistryBasePath -Name $Name -Value $Value -PropertyType String -Force | Out-Null
        return $true
    } catch {
        Write-Error "Fehler beim Speichern von Registry-Einstellung '$Name': $_"
        return $false
    }
}

function Write-StatusMessage {
    param (
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")][string]$Type = "Info"
    )
    
    # Statusleiste aktualisieren, wenn vorhanden
    if ($null -ne $script:Window -and $null -ne $script:Window.FindName("StatusText")) {
        $statusText = $script:Window.FindName("StatusText")
        $statusText.Text = $Message
        
        # Farbliche Hervorhebung je nach Meldungstyp
        switch ($Type) {
            "Info"    { $statusText.Foreground = "Black" }
            "Warning" { $statusText.Foreground = "Orange" }
            "Error"   { $statusText.Foreground = "Red" }
            "Success" { $statusText.Foreground = "Green" }
        }
    }
    
    # Auch in die Konsole schreiben
    switch ($Type) {
        "Info"    { Write-Host $Message }
        "Warning" { Write-Warning $Message }
        "Error"   { Write-Error $Message }
        "Success" { Write-Host $Message -ForegroundColor Green }
    }
}

function Load-GlobalConfig {
    try {
        # Prüfen, ob globale Konfigurationsdatei existiert
        if (-not (Test-Path -Path $script:GlobalConfigFile)) {
            throw "Globale Konfigurationsdatei nicht gefunden: $script:GlobalConfigFile"
        }
        
        # JSON-Datei laden
        $script:GlobalConfig = Get-Content -Path $script:GlobalConfigFile -Raw | ConvertFrom-Json
        
        # Theme aus der Registry laden oder Standardwert verwenden
        $themeSetting = Get-RegistrySetting -Name "Theme" -DefaultValue $script:GlobalConfig.theme
        $script:GlobalConfig.theme = $themeSetting
        
        Write-Host "Globale Konfiguration geladen, Theme: $($script:GlobalConfig.theme)"
        return $true
    } catch {
        Write-Error "Fehler beim Laden der globalen Konfiguration: $_"
        return $false
    }
}

function Load-Theme {
    param(
        [Parameter(Mandatory=$true)][string]$ThemeName
    )
    
    try {
        $themeFile = Join-Path -Path $script:ThemesPath -ChildPath "$ThemeName.xaml"
        
        # Prüfen, ob Theme existiert
        if (-not (Test-Path -Path $themeFile)) {
            # Fallback auf Light-Theme
            Write-Warning "Theme '$ThemeName' nicht gefunden, verwende 'light'"
            $themeFile = Join-Path -Path $script:ThemesPath -ChildPath "light.xaml"
            
            # Wenn auch Light nicht existiert, Fehler
            if (-not (Test-Path -Path $themeFile)) {
                throw "Kein Theme gefunden"
            }
        }
        
        # Theme laden und in Ressourcenwörterbuch einfügen
        $reader = [System.Xml.XmlReader]::Create($themeFile)
        $script:CurrentTheme = [System.Windows.Markup.XamlReader]::Load($reader)
        $reader.Close()
        
        if ($null -ne $script:Window) {
            $script:Window.Resources.MergedDictionaries.Clear()
            $script:Window.Resources.MergedDictionaries.Add($script:CurrentTheme)
            Write-Host "Theme '$ThemeName' geladen"
        }
        
        return $true
    } catch {
        Write-Error "Fehler beim Laden des Themes '$ThemeName': $_"
        return $false
    }
}

function Scan-Modules {
    try {
        $modules = @{}
        
        # Prüfen, ob Metadatenverzeichnis existiert
        if (-not (Test-Path -Path $script:MetaPath)) {
            throw "Metadatenverzeichnis nicht gefunden: $script:MetaPath"
        }
        
        # Modulverzeichnisse durchsuchen
        $moduleDirs = Get-ChildItem -Path $script:MetaPath -Directory
        foreach ($moduleDir in $moduleDirs) {
            $moduleName = $moduleDir.Name
            
            $metaFile = Join-Path -Path $moduleDir.FullName -ChildPath "meta.json"
            $infoFile = Join-Path -Path $moduleDir.FullName -ChildPath "modulinfo.json"
            
            # Prüfen, ob erforderliche Dateien existieren
            if (-not (Test-Path -Path $metaFile) -or -not (Test-Path -Path $infoFile)) {
                Write-Warning "Modul '$moduleName' unvollständig, wird übersprungen"
                continue
            }
            
            # Metadaten laden
            $meta = Get-Content -Path $metaFile -Raw | ConvertFrom-Json
            $info = Get-Content -Path $infoFile -Raw | ConvertFrom-Json
            
            # Nur aktivierte Module laden
            if ($meta.enabled -ne $true) {
                Write-Host "Modul '$moduleName' ist deaktiviert, wird übersprungen"
                continue
            }
            
            # Modul-Eintrag erstellen
            $moduleEntry = @{
                Name = $moduleName
                Meta = $meta
                Info = $info
                Tab = $null  # Wird später gefüllt
                UIElements = @{}  # UI-Elemente des Moduls
            }
            
            $modules[$moduleName] = $moduleEntry
            Write-Host "Modul entdeckt: $moduleName (Label: $($meta.label), Order: $($meta.order))"
        }
        
        # Module nach Reihenfolge sortieren
        $script:Modules = $modules.GetEnumerator() | 
                        Sort-Object { $_.Value.Meta.order } | 
                        ForEach-Object { $_.Value } | 
                        Group-Object -Property Name -AsHashTable -AsString
        
        return $true
    } catch {
        Write-Error "Fehler beim Scannen der Module: $_"
        return $false
    }
}

function Create-MainWindow {
    try {
        # XAML für Hauptfenster erstellen
        $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="MINTutil" Height="540" Width="740" FontFamily="Segoe UI" FontSize="13">
  <DockPanel>
    <!-- Statusleiste -->
    <StatusBar DockPanel.Dock="Bottom">
      <StatusBarItem>
        <TextBlock Name="StatusText" Text="Bereit" />
      </StatusBarItem>
    </StatusBar>

    <!-- Hauptlayout -->
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
      </Grid.RowDefinitions>

      <!-- Tab-Leiste -->
      <DockPanel Grid.Row="0" Background="LightGray">
        <StackPanel Orientation="Horizontal" Name="TabButtonPanel">
          <!-- Tab-Buttons werden dynamisch hinzugefügt -->
        </StackPanel>
      </DockPanel>

      <!-- Haupt-Inhaltsbereich -->
      <TabControl Name="MainTabControl" Grid.Row="1">
        <!-- Tabs werden dynamisch hinzugefügt -->
      </TabControl>
    </Grid>
  </DockPanel>
</Window>
"@
        
        # XAML in Window-Objekt umwandeln
        $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
        $script:Window = [System.Windows.Markup.XamlReader]::Load($reader)
        $reader.Close()
        
        # Tab-Steuerelemente abrufen
        $tabButtonPanel = $script:Window.FindName("TabButtonPanel")
        $mainTabControl = $script:Window.FindName("MainTabControl")
        
        # Tab-Schaltflächen und -Inhalte für jedes Modul erstellen
        foreach ($moduleName in $script:Modules.Keys) {
            $module = $script:Modules[$moduleName]
            
            # Tab-Button erstellen
            $tabButton = New-Object System.Windows.Controls.RadioButton
            $tabButton.Content = $module.Meta.label
            $tabButton.GroupName = "ModuleTabs"
            $tabButton.Margin = "5,5,0,5"
            $tabButton.Padding = "10,5"
            $tabButton.Name = "Tab_$moduleName"
            $tabButtonPanel.Children.Add($tabButton)
            
            # Tab erstellen
            $tabItem = New-Object System.Windows.Controls.TabItem
            $tabItem.Header = $module.Meta.label
            $tabItem.Name = "TabItem_$moduleName"
            $tabItem.Visibility = "Collapsed"  # Versteckt, wird über RadioButtons gesteuert
            $mainTabControl.Items.Add($tabItem)
            
            # Modul-Tab speichern
            $module.Tab = $tabItem
            
            # Event-Handler für Tab-Button
            $tabButton.Add_Checked({
                param($sender, $e)
                $buttonName = $sender.Name
                $moduleName = $buttonName -replace "Tab_", ""
                
                # Entsprechenden Tab anzeigen
                foreach ($tab in $mainTabControl.Items) {
                    $tab.IsSelected = ($tab.Name -eq "TabItem_$moduleName")
                }
                
                # Modulinhalt laden, falls noch nicht geschehen
                Load-ModuleUI -ModuleName $moduleName
            })
        }
        
        # Ersten Tab standardmäßig auswählen
        if ($tabButtonPanel.Children.Count -gt 0) {
            $tabButtonPanel.Children[0].IsChecked = $true
        }
        
        return $true
    } catch {
        Write-Error "Fehler beim Erstellen des Hauptfensters: $_"
        return $false
    }
}

function Load-ModuleUI {
    param(
        [Parameter(Mandatory=$true)][string]$ModuleName
    )
    
    try {
        $module = $script:Modules[$ModuleName]
        if ($null -eq $module) {
            throw "Modul '$ModuleName' nicht gefunden"
        }
        
        # Prüfen, ob UI bereits geladen wurde
        if ($module.UIElements.Count -gt 0) {
            Write-Host "UI für Modul '$ModuleName' bereits geladen"
            return $true
        }
        
        # UI-XAML-Datei laden
        $uiXamlPath = Join-Path -Path $script:ConfigPath -ChildPath "$ModuleName/ui.xaml"
        if (-not (Test-Path -Path $uiXamlPath)) {
            throw "UI-XAML für Modul '$ModuleName' nicht gefunden: $uiXamlPath"
        }
        
        $xamlContent = Get-Content -Path $uiXamlPath -Raw
        
        # XAML in UI-Objekt umwandeln
        $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlContent))
        $moduleUI = [System.Windows.Markup.XamlReader]::Load($reader)
        $reader.Close()
        
        # UI zum Tab hinzufügen
        $module.Tab.Content = $moduleUI
        
        # Modullogik laden und initialisieren
        $entryScript = Join-Path -Path $script:BasePath -ChildPath $module.Info.entry
        if (-not (Test-Path -Path $entryScript)) {
            throw "Entry-Script für Modul '$ModuleName' nicht gefunden: $entryScript"
        }
        
        # Skript in globalem Scope ausführen, um Funktionen zu definieren
        . $entryScript
        
        # Wenn es eine Initialize-Funktion gibt, diese aufrufen
        if (Get-Command "Initialize-$ModuleName" -ErrorAction SilentlyContinue) {
            & "Initialize-$ModuleName" -Window $moduleUI
            Write-Host "Modul '$ModuleName' initialisiert"
        }
        
        Write-Host "UI für Modul '$ModuleName' geladen"
        return $true
    } catch {
        Write-Error "Fehler beim Laden der UI für Modul '$ModuleName': $_"
        return $false
    }
}

function Start-MINTutil {
    try {
        # Registry-Speicher initialisieren
        Initialize-RegistryStore
        
        # Globale Konfiguration laden
        $configResult = Load-GlobalConfig
        if (-not $configResult) {
            throw "Fehler beim Laden der globalen Konfiguration"
        }
        
        # Theme laden
        $themeResult = Load-Theme -ThemeName $script:GlobalConfig.theme
        if (-not $themeResult) {
            throw "Fehler beim Laden des Themes"
        }
        
        # Module scannen
        $modulesResult = Scan-Modules
        if (-not $modulesResult) {
            throw "Fehler beim Scannen der Module"
        }
        
        # Hauptfenster erstellen
        $windowResult = Create-MainWindow
        if (-not $windowResult) {
            throw "Fehler beim Erstellen des Hauptfensters"
        }
        
        # Anwendung starten
        $script:Window.ShowDialog() | Out-Null
        
    } catch {
        Write-Error "Fehler beim Starten von MINTutil: $_"
        [System.Windows.MessageBox]::Show("Fehler beim Starten von MINTutil: $_", "Fehler", 
                                          [System.Windows.MessageBoxButton]::OK, 
                                          [System.Windows.MessageBoxImage]::Error)
    }
}

# ============= Hauptprogramm =============

# Wenn Validierung angefordert wurde, diese ausführen
if ($Validate) {
    & "$script:BasePath\validate_mintutil.ps1" -BasePath $script:BasePath
}

# Wenn ein spezifisches Modul angefordert wurde, nur dieses laden
if ($ModulePath) {
    if (Test-Path -Path $ModulePath) {
        & $ModulePath
    } else {
        Write-Error "Angegebenes Modul nicht gefunden: $ModulePath"
    }
} else {
    # Normaler Programmstart
    Start-MINTutil
}