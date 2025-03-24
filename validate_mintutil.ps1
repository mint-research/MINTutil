# MINTutil Validierungsskript
# Überprüft die Struktur und Integrität des modularen Systems

param (
    [Parameter(Mandatory=$false)][string]$BasePath = $PSScriptRoot
)

# Fortschrittszähler initialisieren
$validationSteps = 0
$completedSteps = 0
$warnings = 0
$errors = 0

function Write-ValidationProgress {
    param(
        [Parameter(Mandatory=$true)][string]$Status,
        [Parameter(Mandatory=$false)][int]$PercentComplete = -1
    )
    
    if ($PercentComplete -lt 0) {
        # Automatisch berechnen
        $completedSteps++
        $PercentComplete = [math]::Min(100, [math]::Round(($completedSteps / $validationSteps) * 100))
    }
    
    Write-Progress -Activity "MINTutil Validierung" -Status $Status -PercentComplete $PercentComplete
}

function Write-ValidationMessage {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$false)][string]$Type = "Info"
    )
    
    switch ($Type) {
        "Success" { 
            Write-Host "✓ $Message" -ForegroundColor Green 
        }
        "Warning" { 
            Write-Host "! $Message" -ForegroundColor Yellow 
            $script:warnings++
        }
        "Error" { 
            Write-Host "✗ $Message" -ForegroundColor Red 
            $script:errors++
        }
        default { 
            Write-Host "- $Message" 
        }
    }
}

function Test-JsonFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )
    
    if (-not (Test-Path -Path $Path)) {
        return $false
    }
    
    try {
        $null = Get-Content -Path $Path -Raw | ConvertFrom-Json
        return $true
    } catch {
        return $false
    }
}

Write-Host "`nMINTutil Validierungsskript`n" -ForegroundColor Cyan
Write-Host "Überprüfe die Struktur und Integrität des modularen Systems..." -ForegroundColor Cyan
Write-Host "Basispfad: $BasePath`n" -ForegroundColor Cyan

# Anzahl der Validierungsschritte feststellen
$validationSteps = 5  # Basis-Prüfungen
Write-ValidationProgress -Status "Initialisiere..."

# Schritt 1: Überprüfen, ob Hauptverzeichnisse existieren
Write-ValidationProgress -Status "Überprüfe Hauptverzeichnisse..."

$requiredDirs = @("config", "data", "docs", "meta", "modules", "themes")
$dirStatus = @{}

foreach ($dir in $requiredDirs) {
    $dirPath = Join-Path -Path $BasePath -ChildPath $dir
    $dirExists = Test-Path -Path $dirPath -PathType Container
    $dirStatus[$dir] = $dirExists
    
    if ($dirExists) {
        Write-ValidationMessage -Message "Verzeichnis '$dir' gefunden" -Type "Success"
    } else {
        Write-ValidationMessage -Message "Verzeichnis '$dir' fehlt" -Type "Error"
    }
}

# Schritt 2: Überprüfen, ob globale Konfigurationsdatei existiert
Write-ValidationProgress -Status "Überprüfe globale Konfiguration..."

$globalConfigPath = Join-Path -Path $BasePath -ChildPath "config/global.config.json"
$globalConfigExists = Test-Path -Path $globalConfigPath -PathType Leaf
$globalConfigValid = $globalConfigExists -and (Test-JsonFile -Path $globalConfigPath)

if ($globalConfigExists) {
    if ($globalConfigValid) {
        Write-ValidationMessage -Message "Globale Konfigurationsdatei gefunden und ist gültig" -Type "Success"
    } else {
        Write-ValidationMessage -Message "Globale Konfigurationsdatei gefunden, enthält aber ungültiges JSON" -Type "Error"
    }
} else {
    Write-ValidationMessage -Message "Globale Konfigurationsdatei fehlt" -Type "Error"
}

# Schritt 3: Überprüfen, ob Theme-Dateien existieren
Write-ValidationProgress -Status "Überprüfe Themes..."

$lightThemePath = Join-Path -Path $BasePath -ChildPath "themes/light.xaml"
$darkThemePath = Join-Path -Path $BasePath -ChildPath "themes/dark.xaml"

$lightThemeExists = Test-Path -Path $lightThemePath -PathType Leaf
$darkThemeExists = Test-Path -Path $darkThemePath -PathType Leaf

if ($lightThemeExists) {
    Write-ValidationMessage -Message "Light-Theme gefunden" -Type "Success"
} else {
    Write-ValidationMessage -Message "Light-Theme fehlt" -Type "Error"
}

if ($darkThemeExists) {
    Write-ValidationMessage -Message "Dark-Theme gefunden" -Type "Success"
} else {
    Write-ValidationMessage -Message "Dark-Theme fehlt" -Type "Error"
}

# Schritt 4: Module validieren
Write-ValidationProgress -Status "Suche nach Modulen..."

# Modulverzeichnisse identifizieren
$moduleDirectories = Get-ChildItem -Path (Join-Path -Path $BasePath -ChildPath "meta") -Directory

if ($moduleDirectories.Count -eq 0) {
    Write-ValidationMessage -Message "Keine Module gefunden" -Type "Error"
} else {
    Write-ValidationMessage -Message "$($moduleDirectories.Count) Module gefunden"
    
    # Validierungsschritte aktualisieren
    $validationSteps += $moduleDirectories.Count
    
    foreach ($moduleDir in $moduleDirectories) {
        $moduleName = $moduleDir.Name
        Write-ValidationProgress -Status "Validiere Modul: $moduleName..."
        
        # Überprüfen, ob alle erforderlichen Dateien und Verzeichnisse für das Modul existieren
        $moduleStructureValid = $true
        $missingComponents = @()
        
        # Meta-Dateien prüfen
        $metaJsonPath = Join-Path -Path $moduleDir.FullName -ChildPath "meta.json"
        $modulinfoJsonPath = Join-Path -Path $moduleDir.FullName -ChildPath "modulinfo.json"
        
        $metaJsonExists = Test-Path -Path $metaJsonPath -PathType Leaf
        $metaJsonValid = $metaJsonExists -and (Test-JsonFile -Path $metaJsonPath)
        
        $modulinfoJsonExists = Test-Path -Path $modulinfoJsonPath -PathType Leaf
        $modulinfoJsonValid = $modulinfoJsonExists -and (Test-JsonFile -Path $modulinfoJsonPath)
        
        if (-not $metaJsonExists) {
            $moduleStructureValid = $false
            $missingComponents += "meta.json fehlt"
        } elseif (-not $metaJsonValid) {
            $moduleStructureValid = $false
            $missingComponents += "meta.json enthält ungültiges JSON"
        }
        
        if (-not $modulinfoJsonExists) {
            $moduleStructureValid = $false
            $missingComponents += "modulinfo.json fehlt"
        } elseif (-not $modulinfoJsonValid) {
            $moduleStructureValid = $false
            $missingComponents += "modulinfo.json enthält ungültiges JSON"
        }
        
        # Falls modulinfo.json vorhanden und gültig ist, zusätzliche Prüfungen durchführen
        if ($modulinfoJsonValid) {
            $modulinfo = Get-Content -Path $modulinfoJsonPath -Raw | ConvertFrom-Json
            
            # Prüfen, ob das Einstiegsskript existiert
            if ($modulinfo.entry) {
                $entryScriptPath = Join-Path -Path $BasePath -ChildPath $modulinfo.entry
                $entryScriptExists = Test-Path -Path $entryScriptPath -PathType Leaf
                
                if (-not $entryScriptExists) {
                    $moduleStructureValid = $false
                    $missingComponents += "Einstiegsskript $($modulinfo.entry) fehlt"
                }
            } else {
                $moduleStructureValid = $false
                $missingComponents += "Kein Einstiegsskript in modulinfo.json definiert"
            }
            
            # Prüfen, ob Konfigurationsdateien existieren
            if ($modulinfo.config) {
                foreach ($configPath in $modulinfo.config) {
                    $fullConfigPath = Join-Path -Path $BasePath -ChildPath $configPath
                    $configExists = Test-Path -Path $fullConfigPath -PathType Leaf
                    
                    if (-not $configExists) {
                        $moduleStructureValid = $false
                        $missingComponents += "Konfigurationsdatei $configPath fehlt"
                    } elseif ($configPath -like "*.json" -and -not (Test-JsonFile -Path $fullConfigPath)) {
                        $moduleStructureValid = $false
                        $missingComponents += "Konfigurationsdatei $configPath enthält ungültiges JSON"
                    }
                }
            }
            
            # Prüfen, ob Datendateien existieren (außer 'generates', diese dürfen fehlen)
            if ($modulinfo.data) {
                foreach ($dataPath in $modulinfo.data) {
                    $fullDataPath = Join-Path -Path $BasePath -ChildPath $dataPath
                    $dataExists = Test-Path -Path $fullDataPath -PathType Leaf
                    
                    # Nur warnen, wenn Datendateien fehlen, kein Fehler
                    if (-not $dataExists) {
                        Write-ValidationMessage -Message "Modul '$moduleName': Datendatei $dataPath fehlt" -Type "Warning"
                    } elseif ($dataPath -like "*.json" -and -not (Test-JsonFile -Path $fullDataPath)) {
                        Write-ValidationMessage -Message "Modul '$moduleName': Datendatei $dataPath enthält ungültiges JSON" -Type "Warning"
                    }
                }
            }
        }
        
        # Prüfen, ob das Modulverzeichnis existiert
        $moduleCodeDir = Join-Path -Path $BasePath -ChildPath "modules/$moduleName"
        $moduleCodeDirExists = Test-Path -Path $moduleCodeDir -PathType Container
        
        if (-not $moduleCodeDirExists) {
            $moduleStructureValid = $false
            $missingComponents += "Modulverzeichnis 'modules/$moduleName' fehlt"
        }
        
        # Prüfen, ob das Konfigurationsverzeichnis existiert
        $moduleConfigDir = Join-Path -Path $BasePath -ChildPath "config/$moduleName"
        $moduleConfigDirExists = Test-Path -Path $moduleConfigDir -PathType Container
        
        if (-not $moduleConfigDirExists) {
            $moduleStructureValid = $false
            $missingComponents += "Konfigurationsverzeichnis 'config/$moduleName' fehlt"
        }
        
        # Prüfen, ob das Datenverzeichnis existiert
        $moduleDataDir = Join-Path -Path $BasePath -ChildPath "data/$moduleName"
        $moduleDataDirExists = Test-Path -Path $moduleDataDir -PathType Container
        
        if (-not $moduleDataDirExists) {
            # Nur Warnung, kein Fehler
            Write-ValidationMessage -Message "Modul '$moduleName': Datenverzeichnis 'data/$moduleName' fehlt" -Type "Warning"
        }
        
        # Ergebnis ausgeben
        if ($moduleStructureValid) {
            Write-ValidationMessage -Message "Modul '$moduleName' hat eine gültige Struktur" -Type "Success"
        } else {
            Write-ValidationMessage -Message "Modul '$moduleName' hat strukturelle Probleme:" -Type "Error"
            foreach ($component in $missingComponents) {
                Write-ValidationMessage -Message "  - $component" -Type "Error"
            }
        }
    }
}

# Schritt 5: Überprüfen, ob globale Daten vorhanden sind
Write-ValidationProgress -Status "Überprüfe globale Daten..."

$globalDataDir = Join-Path -Path $BasePath -ChildPath "data/Globale Daten"
$globalDataDirExists = Test-Path -Path $globalDataDir -PathType Container

if ($globalDataDirExists) {
    Write-ValidationMessage -Message "Verzeichnis für globale Daten gefunden" -Type "Success"
} else {
    Write-ValidationMessage -Message "Verzeichnis für globale Daten fehlt" -Type "Warning"
}

# Validierung abschließen
Write-Progress -Activity "MINTutil Validierung" -Status "Validierung abgeschlossen" -PercentComplete 100
Start-Sleep -Milliseconds 500
Write-Progress -Activity "MINTutil Validierung" -Completed

# Zusammenfassung ausgeben
Write-Host "`nVALIDIERUNG ABGESCHLOSSEN" -ForegroundColor Cyan
Write-Host "-----------------------------------------" -ForegroundColor Cyan
Write-Host "Warnungen: $warnings" -ForegroundColor $(if ($warnings -gt 0) { "Yellow" } else { "Green" })
Write-Host "Fehler: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })
Write-Host "-----------------------------------------" -ForegroundColor Cyan

if ($errors -gt 0) {
    Write-Host "`nDie Validierung hat strukturelle Probleme gefunden, die behoben werden sollten." -ForegroundColor Red
    Write-Host "MINTutil funktioniert möglicherweise nicht korrekt, bis diese Probleme behoben sind." -ForegroundColor Red
    Exit 1
} elseif ($warnings -gt 0) {
    Write-Host "`nDie Validierung hat potenzielle Probleme gefunden, die überprüft werden sollten." -ForegroundColor Yellow
    Write-Host "MINTutil sollte trotzdem funktionieren, aber einige Funktionen sind möglicherweise eingeschränkt." -ForegroundColor Yellow
    Exit 0
} else {
    Write-Host "`nDie Validierung wurde ohne Probleme abgeschlossen. MINTutil ist bereit!" -ForegroundColor Green
    Exit 0
}