# Module Register für MINTutil
# Dieses Skript verwaltet das Modulregister und stellt sicher, dass nur registrierte Module existieren

# Globale Variablen
$script:RegisterPath = Join-Path -Path $PSScriptRoot -ChildPath "../../data/global/module_register.json"

<#
.SYNOPSIS
    Initialisiert das Modulregister.
.DESCRIPTION
    Diese Funktion initialisiert das Modulregister, falls es noch nicht existiert.
#>
function Initialize-ModuleRegister {
    if (-not (Test-Path -Path $script:RegisterPath)) {
        $registerData = @{
            RegisteredModules = @()
            LastUpdate        = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        $registerData | ConvertTo-Json -Depth 3 | Set-Content -Path $script:RegisterPath -Encoding UTF8
        Write-Host "Modulregister wurde initialisiert unter $script:RegisterPath" -ForegroundColor Green
    }
}

<#
.SYNOPSIS
    Lädt das Modulregister.
.DESCRIPTION
    Diese Funktion lädt das Modulregister aus der JSON-Datei.
#>
function Get-ModuleRegister {
    if (-not (Test-Path -Path $script:RegisterPath)) {
        Initialize-ModuleRegister
    }

    $registerData = Get-Content -Path $script:RegisterPath -Raw | ConvertFrom-Json
    return $registerData
}

<#
.SYNOPSIS
    Speichert das Modulregister.
.DESCRIPTION
    Diese Funktion speichert das Modulregister in der JSON-Datei.
.PARAMETER RegisterData
    Die zu speichernden Registerdaten.
#>
function Save-ModuleRegister {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$RegisterData
    )

    $RegisterData.LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $RegisterData | ConvertTo-Json -Depth 3 | Set-Content -Path $script:RegisterPath -Encoding UTF8
}

<#
.SYNOPSIS
    Prüft, ob ein Modul registriert ist.
.DESCRIPTION
    Diese Funktion prüft, ob ein Modul im Register eingetragen ist.
.PARAMETER ModuleName
    Der Name des zu prüfenden Moduls.
#>
function Test-ModuleRegistered {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    $registerData = Get-ModuleRegister
    return $registerData.RegisteredModules -contains $ModuleName
}

<#
.SYNOPSIS
    Registriert ein Modul im Register.
.DESCRIPTION
    Diese Funktion registriert ein Modul im Register.
.PARAMETER ModuleName
    Der Name des zu registrierenden Moduls.
.PARAMETER Force
    Gibt an, ob die Registrierung erzwungen werden soll, auch wenn das Modul bereits registriert ist.
#>
function Register-Module {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ((Test-ModuleRegistered -ModuleName $ModuleName) -and -not $Force) {
        Write-Host "Modul $ModuleName ist bereits registriert." -ForegroundColor Yellow
        return
    }

    $registerData = Get-ModuleRegister

    if (-not ($registerData.RegisteredModules -contains $ModuleName)) {
        $registerData.RegisteredModules += $ModuleName
        Save-ModuleRegister -RegisterData $registerData
        Write-Host "Modul $ModuleName wurde erfolgreich registriert." -ForegroundColor Green
    }
}

<#
.SYNOPSIS
    Entfernt ein Modul aus dem Register.
.DESCRIPTION
    Diese Funktion entfernt ein Modul aus dem Register.
.PARAMETER ModuleName
    Der Name des zu entfernenden Moduls.
#>
function Unregister-Module {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    if (-not (Test-ModuleRegistered -ModuleName $ModuleName)) {
        Write-Host "Modul $ModuleName ist nicht registriert." -ForegroundColor Yellow
        return
    }

    $registerData = Get-ModuleRegister
    $registerData.RegisteredModules = $registerData.RegisteredModules | Where-Object { $_ -ne $ModuleName }
    Save-ModuleRegister -RegisterData $registerData
    Write-Host "Modul $ModuleName wurde aus dem Register entfernt." -ForegroundColor Green
}

<#
.SYNOPSIS
    Zeigt alle registrierten Module an.
.DESCRIPTION
    Diese Funktion zeigt alle im Register eingetragenen Module an.
#>
function Show-RegisteredModules {
    $registerData = Get-ModuleRegister

    Write-Host "Registrierte Module:" -ForegroundColor Cyan
    foreach ($module in $registerData.RegisteredModules) {
        Write-Host "  - $module" -ForegroundColor White
    }

    Write-Host "Letztes Update: $($registerData.LastUpdate)" -ForegroundColor Gray
}

<#
.SYNOPSIS
    Prüft, ob nicht registrierte Module existieren.
.DESCRIPTION
    Diese Funktion prüft, ob Module existieren, die nicht im Register eingetragen sind.
#>
function Find-UnregisteredModules {
    $baseDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $modulesDir = Join-Path -Path $baseDir -ChildPath "modules"

    $existingModules = Get-ChildItem -Path $modulesDir -Directory |
    Where-Object { $_.Name -match "^M\d+_" -and $_.Name -ne "global" } |
    Select-Object -ExpandProperty Name

    $registerData = Get-ModuleRegister
    $unregisteredModules = $existingModules | Where-Object { $registerData.RegisteredModules -notcontains $_ }

    if ($unregisteredModules.Count -eq 0) {
        Write-Host "Keine nicht registrierten Module gefunden." -ForegroundColor Green
        return @()
    }

    Write-Host "Nicht registrierte Module gefunden:" -ForegroundColor Yellow
    foreach ($module in $unregisteredModules) {
        Write-Host "  - $module" -ForegroundColor White
    }

    return $unregisteredModules
}

<#
.SYNOPSIS
    Fragt den Benutzer, ob ein Modul registriert werden soll.
.DESCRIPTION
    Diese Funktion fragt den Benutzer, ob ein nicht registriertes Modul registriert oder gelöscht werden soll.
.PARAMETER ModuleName
    Der Name des zu prüfenden Moduls.
#>
function Request-ModuleRegistration {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    $title = "Modul-Registrierung"
    $message = "Das Modul '$ModuleName' ist nicht registriert. Möchten Sie es registrieren?"

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Ja", "Registriert das Modul."
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&Nein", "Löscht das Modul."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $result = $host.UI.PromptForChoice($title, $message, $options, 0)

    switch ($result) {
        0 {
            Register-Module -ModuleName $ModuleName
            return $true
        }
        1 {
            # Modul löschen
            $baseDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            $modulePath = Join-Path -Path $baseDir -ChildPath "modules\$ModuleName"
            $configPath = Join-Path -Path $baseDir -ChildPath "config\$ModuleName"
            $dataPath = Join-Path -Path $baseDir -ChildPath "data\$ModuleName"
            $docsPath = Join-Path -Path $baseDir -ChildPath "docs\$ModuleName"
            $metaPath = Join-Path -Path $baseDir -ChildPath "meta\$ModuleName"

            Remove-Item -Path $modulePath -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $configPath -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $dataPath -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $docsPath -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $metaPath -Recurse -Force -ErrorAction SilentlyContinue

            Write-Host "Modul $ModuleName wurde gelöscht." -ForegroundColor Green
            return $false
        }
    }
}

<#
.SYNOPSIS
    Prüft alle Module und fragt nach Registrierung für nicht registrierte Module.
.DESCRIPTION
    Diese Funktion prüft alle existierenden Module und fragt für nicht registrierte Module nach, ob sie registriert werden sollen.
#>
function Check-AllModules {
    $unregisteredModules = Find-UnregisteredModules

    foreach ($module in $unregisteredModules) {
        Request-ModuleRegistration -ModuleName $module
    }
}

# Exportiere die Funktionen
Export-ModuleMember -Function Initialize-ModuleRegister, Get-ModuleRegister, Register-Module, Unregister-Module, Show-RegisteredModules, Find-UnregisteredModules, Request-ModuleRegistration, Check-AllModules
