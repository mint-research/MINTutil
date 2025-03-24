# Global-Modul für MINTutil
# Enthält gemeinsame Funktionen und Einstellungen für alle Module

# Globale Variablen
$script:GlobalBasePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:CommonSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath "../../data/global/common_settings.json"
$script:ModuleRegisterPath = Join-Path -Path $PSScriptRoot -ChildPath "../../data/global/module_register.json"
$script:GlobalUI = $null

# Module Register importieren
. "$PSScriptRoot\module_register.ps1"

# ============= Initialisierungsfunktionen =============

<#
.SYNOPSIS
    Kurzbeschreibung der Funktion Initialize-global.
.DESCRIPTION
    Detaillierte Beschreibung der Funktion Initialize-global.
.PARAMETER Parameter1
    Beschreibung des ersten Parameters.
.EXAMPLE
    Initialize-global -Parameter1 Wert
#>
function Initialize-global {
    param(
        [Parameter(Mandatory = $true)]$Window
    )
    try {
        $script:GlobalUI = $Window

        # Sicherstellen, dass Verzeichnisse existieren
        $settingsDir = Split-Path -Parent $script:CommonSettingsPath
        if (-not (Test-Path -Path $settingsDir)) {
            New-Item -Path $settingsDir -ItemType Directory -Force | Out-Null
        }

        # Einstellungsdatei erstellen, falls nicht vorhanden
        if (-not (Test-Path -Path $script:CommonSettingsPath)) {
            $settings = @{
                Theme           = "light"
                Language        = "de-DE"
                LogLevel        = "Info"
                UpdateCheck     = $true
                LastUpdateCheck = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            }
            $settings | ConvertTo-Json | Set-Content -Path $script:CommonSettingsPath -Force
        }

        # Modulregister initialisieren
        Initialize-ModuleRegister

        # Prüfen, ob nicht registrierte Module existieren
        $unregisteredModules = Find-UnregisteredModules
        if ($unregisteredModules.Count -gt 0) {
            $message = "Es wurden nicht registrierte Module gefunden. Möchten Sie diese jetzt überprüfen?"
            $title = "Modul-Registrierung"
            $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Ja", "Überprüft die nicht registrierten Module."
            $no = New-Object System.Management.Automation.Host.ChoiceDescription "&Nein", "Überspringt die Überprüfung."
            $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
            $result = $host.UI.PromptForChoice($title, $message, $options, 0)

            if ($result -eq 0) {
                Check-AllModules
            }
        }

        Write-Host "Global-Modul initialisiert"
        return $true
    } catch {
        Write-Error "Fehler bei der Initialisierung des Global-Moduls: $_"
        return $false
    }
}

# ============= Gemeinsame Funktionen =============

<#
.SYNOPSIS
    Kurzbeschreibung der Funktion Get-CommonSetting.
.DESCRIPTION
    Detaillierte Beschreibung der Funktion Get-CommonSetting.
.PARAMETER Parameter1
    Beschreibung des ersten Parameters.
.EXAMPLE
    Get-CommonSetting -Parameter1 Wert
#>
function Get-CommonSetting {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        $DefaultValue = $null
    )
    try {
        if (-not (Test-Path -Path $script:CommonSettingsPath)) {
            return $DefaultValue
        }

        $settings = Get-Content -Path $script:CommonSettingsPath -Raw | ConvertFrom-Json

        if ($null -ne $settings -and (Get-Member -InputObject $settings -Name $Key -MemberType Properties)) {
            return $settings.$Key
        } else {
            return $DefaultValue
        }
    } catch {
        Write-Error "Fehler beim Lesen der gemeinsamen Einstellung '$Key': $_"
        return $DefaultValue
    }
}

<#
.SYNOPSIS
    Kurzbeschreibung der Funktion Set-CommonSetting.
.DESCRIPTION
    Detaillierte Beschreibung der Funktion Set-CommonSetting.
.PARAMETER Parameter1
    Beschreibung des ersten Parameters.
.EXAMPLE
    Set-CommonSetting -Parameter1 Wert
#>
function Set-CommonSetting {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)]$Value
    )
    try {
        if (-not (Test-Path -Path $script:CommonSettingsPath)) {
            $settings = @{}
        } else {
            $settings = Get-Content -Path $script:CommonSettingsPath -Raw | ConvertFrom-Json
            # Konvertieren zu PSCustomObject zu Hashtable
            $settingsHash = @{}
            $settings.PSObject.Properties | ForEach-Object { $settingsHash[$_.Name] = $_.Value }
            $settings = $settingsHash
        }

        $settings[$Key] = $Value
        $settings | ConvertTo-Json | Set-Content -Path $script:CommonSettingsPath -Force

        return $true
    } catch {
        Write-Error "Fehler beim Speichern der gemeinsamen Einstellung '$Key': $_"
        return $false
    }
}

# Exportiere die Initialisierungsfunktion für main.ps1
Export-ModuleMember -Function Initialize-global, Get-CommonSetting, Set-CommonSetting, Initialize-ModuleRegister, Register-Module, Unregister-Module, Show-RegisteredModules, Find-UnregisteredModules, Check-AllModules


