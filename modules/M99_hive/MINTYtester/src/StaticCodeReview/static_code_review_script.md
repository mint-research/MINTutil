# Static Code Review Script für MINTutil

Dieses Dokument enthält das PowerShell-Script für das automatisierte Static Code Review des MINTutil-Projekts. Es implementiert die in `static_code_review.md` definierten Kriterien und bietet automatische Korrekturen für häufige Probleme.

## Script-Code

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Static Code Review für MINTutil
.DESCRIPTION
    Dieses Script führt ein automatisiertes Static Code Review für das MINTutil-Projekt durch.
    Es analysiert den Code auf verschiedenen Ebenen (Architektur, Modul, Funktion, Code) und
    generiert einen detaillierten Bericht mit Problemen und automatischen Korrekturvorschlägen.
.PARAMETER Path
    Der Pfad zum MINTutil-Projektverzeichnis. Standardmäßig wird das aktuelle Verzeichnis verwendet.
.PARAMETER OutputPath
    Der Pfad, in dem der Bericht gespeichert werden soll. Standardmäßig wird ein Bericht im Verzeichnis
    'tests/reports' mit Zeitstempel erstellt.
.PARAMETER IncludeAutoCorrections
    Gibt an, ob automatische Korrekturen im Bericht enthalten sein sollen. Standardmäßig true.
.PARAMETER ApplyAutoCorrections
    Gibt an, ob automatische Korrekturen direkt angewendet werden sollen. Standardmäßig false.
.PARAMETER Levels
    Die zu überprüfenden Ebenen. Mögliche Werte: Architecture, Module, Function, Code, All.
    Standardmäßig werden alle Ebenen überprüft.
.EXAMPLE
    .\static_code_review.ps1 -Path "C:\MINTutil" -OutputPath "C:\Reports\review.md"
.NOTES
    Version: 1.0
#>

param (
    [string]$Path = (Get-Location).Path,
    [string]$OutputPath = "",
    [bool]$IncludeAutoCorrections = $true,
    [bool]$ApplyAutoCorrections = $false,
    [ValidateSet("Architecture", "Module", "Function", "Code", "All")]
    [string[]]$Levels = @("All")
)

# Globale Variablen
$script:BasePath = $Path
$script:ReportData = @{
    Summary = @{
        TotalFiles = 0
        TotalProblems = 0
        CriticalProblems = 0
        HighProblems = 0
        MediumProblems = 0
        LowProblems = 0
        AutoCorrectableProblems = 0
    }
    Problems = @()
}

# Schweregrade für Probleme
enum Severity {
    Critical
    High
    Medium
    Low
}

# ============= Hilfsfunktionen =============

function Initialize-Review {
    # Überprüfen, ob das angegebene Verzeichnis existiert
    if (-not (Test-Path -Path $script:BasePath -PathType Container)) {
        Write-Error "Das angegebene Verzeichnis existiert nicht: $script:BasePath"
        exit 1
    }

    # Ausgabepfad festlegen, falls nicht angegeben
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $reportsDir = Join-Path -Path $script:BasePath -ChildPath "tests\reports"
        if (-not (Test-Path -Path $reportsDir)) {
            New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
        }
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $script:OutputPath = Join-Path -Path $reportsDir -ChildPath "static_code_review_$timestamp.md"
    } else {
        $script:OutputPath = $OutputPath
    }

    Write-Host "Static Code Review wird gestartet..."
    Write-Host "Projektverzeichnis: $script:BasePath"
    Write-Host "Ausgabedatei: $script:OutputPath"
    Write-Host "Automatische Korrekturen im Bericht: $IncludeAutoCorrections"
    Write-Host "Automatische Korrekturen anwenden: $ApplyAutoCorrections"
    Write-Host "Zu überprüfende Ebenen: $($Levels -join ", ")"
    Write-Host ""
}

function Add-Problem {
    param (
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][int]$LineNumber,
        [Parameter(Mandatory=$true)][string]$Description,
        [Parameter(Mandatory=$true)][Severity]$Severity,
        [string]$Recommendation,
        [bool]$AutoCorrectable = $false,
        [string]$CurrentCode = "",
        [string]$CorrectedCode = ""
    )

    # Relativen Pfad erstellen
    $relativePath = $FilePath.Replace($script:BasePath, "").TrimStart("\", "/")

    # Problem zum Bericht hinzufügen
    $problem = @{
        FilePath = $relativePath
        LineNumber = $LineNumber
        Description = $Description
        Severity = $Severity
        Recommendation = $Recommendation
        AutoCorrectable = $AutoCorrectable
        CurrentCode = $CurrentCode
        CorrectedCode = $CorrectedCode
    }

    $script:ReportData.Problems += $problem

    # Zusammenfassung aktualisieren
    $script:ReportData.Summary.TotalProblems++
    
    switch ($Severity) {
        "Critical" { $script:ReportData.Summary.CriticalProblems++ }
        "High" { $script:ReportData.Summary.HighProblems++ }
        "Medium" { $script:ReportData.Summary.MediumProblems++ }
        "Low" { $script:ReportData.Summary.LowProblems++ }
    }

    if ($AutoCorrectable) {
        $script:ReportData.Summary.AutoCorrectableProblems++
    }
}

function Apply-AutoCorrection {
    param (
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][string]$CurrentCode,
        [Parameter(Mandatory=$true)][string]$CorrectedCode
    )

    if ($ApplyAutoCorrections) {
        try {
            $content = Get-Content -Path $FilePath -Raw
            $newContent = $content.Replace($CurrentCode, $CorrectedCode)
            Set-Content -Path $FilePath -Value $newContent -Force
            Write-Host "Automatische Korrektur angewendet in: $FilePath"
            return $true
        } catch {
            Write-Warning "Fehler beim Anwenden der automatischen Korrektur in $FilePath : $_"
            return $false
        }
    }
    
    return $false
}

function Generate-Report {
    $report = @"
# Static Code Review Bericht für MINTutil

Erstellt am: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Zusammenfassung
- Geprüfte Dateien: $($script:ReportData.Summary.TotalFiles)
- Gefundene Probleme: $($script:ReportData.Summary.TotalProblems)
- Kritisch: $($script:ReportData.Summary.CriticalProblems)
- Wichtig: $($script:ReportData.Summary.HighProblems)
- Mittel: $($script:ReportData.Summary.MediumProblems)
- Niedrig: $($script:ReportData.Summary.LowProblems)
- Automatisch korrigierbar: $($script:ReportData.Summary.AutoCorrectableProblems)

## Detaillierte Ergebnisse

"@

    # Probleme nach Schweregrad gruppieren
    $criticalProblems = $script:ReportData.Problems | Where-Object { $_.Severity -eq "Critical" }
    $highProblems = $script:ReportData.Problems | Where-Object { $_.Severity -eq "High" }
    $mediumProblems = $script:ReportData.Problems | Where-Object { $_.Severity -eq "Medium" }
    $lowProblems = $script:ReportData.Problems | Where-Object { $_.Severity -eq "Low" }

    # Kritische Probleme
    if ($criticalProblems.Count -gt 0) {
        $report += @"

### Kritische Probleme

"@
        foreach ($problem in $criticalProblems) {
            $report += Generate-ProblemReport -Problem $problem
        }
    }

    # Wichtige Probleme
    if ($highProblems.Count -gt 0) {
        $report += @"

### Wichtige Probleme

"@
        foreach ($problem in $highProblems) {
            $report += Generate-ProblemReport -Problem $problem
        }
    }

    # Mittlere Probleme
    if ($mediumProblems.Count -gt 0) {
        $report += @"

### Mittlere Probleme

"@
        foreach ($problem in $mediumProblems) {
            $report += Generate-ProblemReport -Problem $problem
        }
    }

    # Niedrige Probleme
    if ($lowProblems.Count -gt 0) {
        $report += @"

### Niedrige Probleme

"@
        foreach ($problem in $lowProblems) {
            $report += Generate-ProblemReport -Problem $problem
        }
    }

    # Bericht speichern
    Set-Content -Path $script:OutputPath -Value $report -Force
    Write-Host "Bericht wurde gespeichert unter: $script:OutputPath"
}

function Generate-ProblemReport {
    param (
        [Parameter(Mandatory=$true)][hashtable]$Problem
    )

    $severityText = switch ($Problem.Severity) {
        "Critical" { "KRITISCH" }
        "High" { "WICHTIG" }
        "Medium" { "MITTEL" }
        "Low" { "NIEDRIG" }
    }

    $report = @"
1. [$severityText] $($Problem.Description) in $($Problem.FilePath):$($Problem.LineNumber)
   - Problem: $($Problem.Description)
"@

    if (-not [string]::IsNullOrEmpty($Problem.Recommendation)) {
        $report += @"
   - Empfehlung: $($Problem.Recommendation)
"@
    }

    $report += @"
   - Automatische Korrektur verfügbar: $($Problem.AutoCorrectable)
"@

    if ($IncludeAutoCorrections -and $Problem.AutoCorrectable -and 
        -not [string]::IsNullOrEmpty($Problem.CurrentCode) -and 
        -not [string]::IsNullOrEmpty($Problem.CorrectedCode)) {
        
        $report += @"
   
   ```powershell
   # Aktueller Code
   $($Problem.CurrentCode)
   
   # Korrigierter Code
   $($Problem.CorrectedCode)
   ```
"@
    }

    return $report
}

# ============= Review-Funktionen =============

function Start-ArchitectureReview {
    Write-Host "Starte Architektur-Review..."
    
    # Überprüfen der Projektstruktur
    $expectedDirs = @("config", "data", "docs", "meta", "modules", "themes")
    foreach ($dir in $expectedDirs) {
        $dirPath = Join-Path -Path $script:BasePath -ChildPath $dir
        if (-not (Test-Path -Path $dirPath -PathType Container)) {
            Add-Problem -FilePath $script:BasePath -LineNumber 0 `
                -Description "Erwartetes Verzeichnis '$dir' fehlt in der Projektstruktur" `
                -Severity "High" `
                -Recommendation "Erstellen Sie das Verzeichnis '$dir' gemäß der Projektstruktur" `
                -AutoCorrectable $true `
                -CurrentCode "" `
                -CorrectedCode "New-Item -Path '$dirPath' -ItemType Directory -Force"
        }
    }
    
    # Überprüfen der Modulstruktur
    $modulesDir = Join-Path -Path $script:BasePath -ChildPath "modules"
    if (Test-Path -Path $modulesDir -PathType Container) {
        $modules = Get-ChildItem -Path $modulesDir -Directory
        
        foreach ($module in $modules) {
            # Überprüfen, ob für jedes Modul die entsprechenden Verzeichnisse in anderen Bereichen existieren
            $moduleName = $module.Name
            
            $configDir = Join-Path -Path $script:BasePath -ChildPath "config\$moduleName"
            $dataDir = Join-Path -Path $script:BasePath -ChildPath "data\$moduleName"
            $metaDir = Join-Path -Path $script:BasePath -ChildPath "meta\$moduleName"
            
            if (-not (Test-Path -Path $configDir -PathType Container)) {
                Add-Problem -FilePath $modulesDir -LineNumber 0 `
                    -Description "Konfigurationsverzeichnis für Modul '$moduleName' fehlt" `
                    -Severity "Medium" `
                    -Recommendation "Erstellen Sie das Verzeichnis 'config\$moduleName'" `
                    -AutoCorrectable $true `
                    -CurrentCode "" `
                    -CorrectedCode "New-Item -Path '$configDir' -ItemType Directory -Force"
            }
            
            if (-not (Test-Path -Path $dataDir -PathType Container)) {
                Add-Problem -FilePath $modulesDir -LineNumber 0 `
                    -Description "Datenverzeichnis für Modul '$moduleName' fehlt" `
                    -Severity "Medium" `
                    -Recommendation "Erstellen Sie das Verzeichnis 'data\$moduleName'" `
                    -AutoCorrectable $true `
                    -CurrentCode "" `
                    -CorrectedCode "New-Item -Path '$dataDir' -ItemType Directory -Force"
            }
            
            if (-not (Test-Path -Path $metaDir -PathType Container)) {
                Add-Problem -FilePath $modulesDir -LineNumber 0 `
                    -Description "Metadatenverzeichnis für Modul '$moduleName' fehlt" `
                    -Severity "Medium" `
                    -Recommendation "Erstellen Sie das Verzeichnis 'meta\$moduleName'" `
                    -AutoCorrectable $true `
                    -CurrentCode "" `
                    -CorrectedCode "New-Item -Path '$metaDir' -ItemType Directory -Force"
            }
        }
    }
    
    Write-Host "Architektur-Review abgeschlossen."
}

function Start-ModuleReview {
    Write-Host "Starte Modul-Review..."
    
    # Überprüfen der Modulschnittstellen
    $modulesDir = Join-Path -Path $script:BasePath -ChildPath "modules"
    if (Test-Path -Path $modulesDir -PathType Container) {
        $modules = Get-ChildItem -Path $modulesDir -Directory
        
        foreach ($module in $modules) {
            $moduleName = $module.Name
            $moduleFiles = Get-ChildItem -Path $module.FullName -Filter "*.ps1"
            
            foreach ($file in $moduleFiles) {
                $content = Get-Content -Path $file.FullName -Raw
                $script:ReportData.Summary.TotalFiles++
                
                # Überprüfen, ob das Modul eine Initialize-Funktion exportiert
                $initFunctionName = "Initialize-$moduleName"
                if (-not ($content -match "function\s+$initFunctionName")) {
                    Add-Problem -FilePath $file.FullName -LineNumber 1 `
                        -Description "Modul '$moduleName' hat keine standardisierte Initialize-Funktion" `
                        -Severity "High" `
                        -Recommendation "Implementieren Sie eine '$initFunctionName'-Funktion als Einstiegspunkt" `
                        -AutoCorrectable $true `
                        -CurrentCode "" `
                        -CorrectedCode @"
function $initFunctionName {
    param(
        [Parameter(Mandatory=`$true)]`$Window
    )
    try {
        # Initialisierungscode hier
        
        Write-Host "$moduleName-Modul initialisiert"
        return `$true
    } catch {
        Write-Error "Fehler bei der Initialisierung des $moduleName-Moduls: `$_"
        return `$false
    }
}
"@
                }
                
                # Überprüfen, ob die Initialize-Funktion exportiert wird
                if ($content -match "function\s+$initFunctionName" -and 
                    -not ($content -match "Export-ModuleMember.*$initFunctionName")) {
                    
                    Add-Problem -FilePath $file.FullName -LineNumber (Get-Content -Path $file.FullName).Count `
                        -Description "Initialize-Funktion wird nicht exportiert" `
                        -Severity "Medium" `
                        -Recommendation "Exportieren Sie die '$initFunctionName'-Funktion mit Export-ModuleMember" `
                        -AutoCorrectable $true `
                        -CurrentCode "" `
                        -CorrectedCode "Export-ModuleMember -Function $initFunctionName"
                }
            }
        }
    }
    
    Write-Host "Modul-Review abgeschlossen."
}

function Start-FunctionReview {
    Write-Host "Starte Funktions-Review..."
    
    # Alle PowerShell-Dateien im Projekt durchsuchen
    $psFiles = Get-ChildItem -Path $script:BasePath -Filter "*.ps1" -Recurse
    
    foreach ($file in $psFiles) {
        $content = Get-Content -Path $file.FullName
        $script:ReportData.Summary.TotalFiles++
        
        # Funktionen im File identifizieren
        $lineNumber = 0
        $inFunction = $false
        $functionName = ""
        $functionStart = 0
        $functionContent = @()
        $braceCount = 0
        
        foreach ($line in $content) {
            $lineNumber++
            
            # Funktionsdefinition finden
            if (-not $inFunction -and $line -match "function\s+([a-zA-Z0-9_-]+)") {
                $inFunction = $true
                $functionName = $Matches[1]
                $functionStart = $lineNumber
                $functionContent = @($line)
                
                # Geschweifte Klammern zählen
                $braceCount += ($line.ToCharArray() | Where-Object { $_ -eq '{' }).Count
                $braceCount -= ($line.ToCharArray() | Where-Object { $_ -eq '}' }).Count
            }
            elseif ($inFunction) {
                $functionContent += $line
                
                # Geschweifte Klammern zählen
                $braceCount += ($line.ToCharArray() | Where-Object { $_ -eq '{' }).Count
                $braceCount -= ($line.ToCharArray() | Where-Object { $_ -eq '}' }).Count
                
                # Ende der Funktion erreicht
                if ($braceCount -eq 0) {
                    $inFunction = $false
                    
                    # Funktion analysieren
                    Analyze-Function -FilePath $file.FullName -FunctionName $functionName `
                        -FunctionStart $functionStart -FunctionContent $functionContent
                    
                    $functionContent = @()
                }
            }
        }
    }
    
    Write-Host "Funktions-Review abgeschlossen."
}

function Analyze-Function {
    param (
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][string]$FunctionName,
        [Parameter(Mandatory=$true)][int]$FunctionStart,
        [Parameter(Mandatory=$true)][string[]]$FunctionContent
    )
    
    $fullContent = $FunctionContent -join "`n"
    
    # 1. Überprüfen der Dokumentation
    $hasDocumentation = $FunctionContent[0] -match "<#" -or ($FunctionStart -gt 1 -and (Get-Content -Path $FilePath)[$FunctionStart-2] -match "<#")
    
    if (-not $hasDocumentation) {
        Add-Problem -FilePath $FilePath -LineNumber $FunctionStart `
            -Description "Funktion '$FunctionName' hat keine Dokumentation" `
            -Severity "Medium" `
            -Recommendation "Fügen Sie einen Kommentarblock mit Synopsis, Beschreibung und Parametern hinzu" `
            -AutoCorrectable $true `
            -CurrentCode "function $FunctionName" `
            -CorrectedCode @"
<#
.SYNOPSIS
    Kurzbeschreibung der Funktion $FunctionName.
.DESCRIPTION
    Detaillierte Beschreibung der Funktion $FunctionName.
.PARAMETER Parameter1
    Beschreibung des ersten Parameters.
.EXAMPLE
    $FunctionName -Parameter1 Wert
#>
function $FunctionName
"@
    }
    
    # 2. Überprüfen der Fehlerbehandlung
    $hasTryCatch = $fullContent -match "try\s*{"
    
    if (-not $hasTryCatch -and -not ($FunctionName -match "^(Get|Test|Find|Search)-")) {
        # Nur für Funktionen, die nicht nur lesend sind (nicht Get-, Test-, Find-, Search-)
        Add-Problem -FilePath $FilePath -LineNumber $FunctionStart `
            -Description "Funktion '$FunctionName' hat keine Try-Catch-Fehlerbehandlung" `
            -Severity "High" `
            -Recommendation "Implementieren Sie Try-Catch-Blöcke für robuste Fehlerbehandlung" `
            -AutoCorrectable $true `
            -CurrentCode $fullContent `
            -CorrectedCode ($fullContent -replace "function $FunctionName([^{]*){", @"
function $FunctionName`$1{
    try {
        # Ursprünglicher Code hier
    } catch {
        Write-Error "Fehler in $FunctionName: `$_"
        return `$false
    }
"@)
    }
    
    # 3. Überprüfen der Parametervalidierung
    if ($fullContent -match "param\s*\(" -and -not ($fullContent -match "\[Parameter\(")) {
        Add-Problem -FilePath $FilePath -LineNumber $FunctionStart `
            -Description "Funktion '$FunctionName' verwendet keine Parameter-Attribute" `
            -Severity "Medium" `
            -Recommendation "Verwenden Sie Parameter-Attribute für bessere Validierung und Dokumentation" `
            -AutoCorrectable $false
    }
    
    # 4. Überprüfen der Funktionslänge
    if ($FunctionContent.Count -gt 100) {
        Add-Problem -FilePath $FilePath -LineNumber $FunctionStart `
            -Description "Funktion '$FunctionName' ist zu lang ($($FunctionContent.Count) Zeilen)" `
            -Severity "Medium" `
            -Recommendation "Teilen Sie die Funktion in kleinere, spezialisierte Funktionen auf" `
            -AutoCorrectable $false
    }
}

function Start-CodeReview {
    Write-Host "Starte Code-Review..."
    
    # Alle PowerShell-Dateien im Projekt durchsuchen
    $psFiles = Get-ChildItem -Path $script:BasePath -Filter "*.ps1" -Recurse
    
    foreach ($file in $psFiles) {
        $content = Get-Content -Path $file.FullName
        
        # Datei bereits gezählt? Wenn nicht, zählen
        if (-not ($script:ReportData.Problems | Where-Object { $_.FilePath -eq $file.FullName })) {
            $script:ReportData.Summary.TotalFiles++
        }
        
        # Zeilenweise Code analysieren
        for ($i = 0; $i -lt $content.Count; $i++) {
            $lineNumber = $i + 1
            $line = $content[$i]
            
            # 1. Überprüfen auf unsichere Befehlsausführung
            if ($line -match "Invoke-Expression|iex" -and $line -match "\$") {
                Add-Problem -FilePath $file.FullName -LineNumber $lineNumber `
                    -Description "Unsichere Verwendung von Invoke-Expression mit Variablen" `
                    -Severity "Critical" `
                    -Recommendation "Vermeiden Sie Invoke-Expression mit Variablen, verwenden Sie stattdessen validierte Parameter" `
                    -AutoCorrectable $false
            }
            
            # 2. Überprüfen auf Write-Host ohne Fehlerbehandlung
            if ($line -match "Write-Error" -and -not ($content -join "`n" -match "try\s*{")) {
                Add-Problem -FilePath $file.FullName -LineNumber $lineNumber `
                    -Description "Write-Error ohne Try-Catch-Block" `
                    -Severity "Medium" `
                    -Recommendation "Umschließen Sie den Code mit einem Try-Catch-Block" `
                    -AutoCorrectable $false
            }
            
            # 3. Überprüfen auf ineffiziente Array-Operationen
            if ($line -match "\$\w+\s*\+=\s*\$\w+" -and -not ($line -match "\$\w+\s*\+=\s*\d+")) {
                Add-Problem -FilePath $file.FullName -LineNumber $lineNumber `
                    -Description "Ineffiziente Array-Konkatenation mit +=" `
                    -Severity "Low" `
                    -Recommendation "Verwenden Sie [System.Collections.ArrayList] oder [System.Collections.Generic.List[]]" `
                    -AutoCorrectable $true `
                    -CurrentCode $line `
                    -CorrectedCode ($line -replace "(\$\w+)\s*\+=\s*(\$\w+)", "`$null = `$1.Add(`$2)")
            }
            
            # 4. Überprüfen auf fehlende Kommentare in komplexem Code
            if (($line -match "foreach|if|switch|while" -or $line -match "{") -and 
                $line.Trim().Length -gt 50 -and -not ($line -match "#")) {
                
                # Prüfen, ob in den nächsten oder vorherigen Zeilen Kommentare sind
                $hasComment = $false
                if ($i -gt 0 -and $content[$i-1] -match "#") { $hasComment = $true }
                if ($i -lt $content.Count - 1 -and $content[$i+1] -match "#") { $hasComment = $true }
                
                if (-not $hasComment) {
                    Add-Problem -FilePath $file.FullName -LineNumber $lineNumber `
                        -Description "Komplexer Code ohne erklärende Kommentare" `
                        -Severity "Low" `
                        -Recommendation "Fügen Sie Kommentare hinzu, um den Zweck des Codes zu erklären" `
                        -AutoCorrectable $false
                }
            }
            
            # 5. Überprüfen auf hardcodierte Pfade
            if ($line -match "C:\\|D:\\|E:\\|F:\\|G:\\|H:\\") {
                Add-Problem -FilePath $file.FullName -LineNumber $lineNumber `
                    -Description "Hardcodierter Dateipfad gefunden" `
                    -Severity "Medium" `
                    -Recommendation "Verwenden Sie relative Pfade oder Konfigurationsvariablen" `
                    -AutoCorrectable $false
            }
        }
    }
    
    Write-Host "Code-Review abgeschlossen."
}

# ============= Hauptprogramm =============

# Review initialisieren
Initialize-Review

# Review-Ebenen durchführen
if ($Levels -contains "All" -or $Levels -contains "Architecture") {
    Start-ArchitectureReview
}

if ($Levels -contains "All" -or $Levels -contains "Module") {
    Start-ModuleReview
}

if ($Levels -contains "All" -or $Levels -contains "Function") {
    Start-FunctionReview
}

if ($Levels -contains "All" -or $Levels -contains "Code") {
    Start-CodeReview
}

# Bericht generieren
Generate-Report

Write-Host "Static Code Review abgeschlossen."
Write-Host "Gefundene Probleme: $($script:ReportData.Summary.TotalProblems)"
Write-Host "Kritisch: $($script:ReportData.Summary.CriticalProblems)"
Write-Host "Wichtig: $($script:ReportData.Summary.HighProblems)"
Write-Host "Mittel: $($script:ReportData.Summary.MediumProblems)"
Write-Host "Niedrig: $($script:ReportData.Summary.LowProblems)"
Write-Host "Automatisch korrigierbar: $($script:ReportData.Summary.AutoCorrectableProblems)"
Write-Host "Bericht wurde gespeichert unter: $script:OutputPath"
```

## Verwendung des Scripts

Um das Static Code Review durchzuführen, speichern Sie den obigen Code als `static_code_review.ps1` im Verzeichnis `tests` und führen Sie ihn wie folgt aus:

```powershell
# Einfache Ausführung mit Standardeinstellungen
.\tests\static_code_review.ps1

# Ausführung mit spezifischen Parametern
.\tests\static_code_review.ps1 -Path "C:\MINTutil" -OutputPath "C:\Reports\review.md" -IncludeAutoCorrections $true -ApplyAutoCorrections $false -Levels "Architecture", "Code"
```

## Erweiterungsmöglichkeiten

Das Script kann in folgenden Bereichen erweitert werden:

1. **Zusätzliche Prüfungen**: Weitere spezifische Prüfungen für PowerShell-Code oder die MINTutil-Architektur
2. **Automatische Korrekturen**: Mehr automatische Korrekturvorschläge für häufige Probleme
3. **Integration in CI/CD**: Anpassung für die Verwendung in einer CI/CD-Pipeline
4. **Interaktiver Modus**: Implementierung eines interaktiven Modus, in dem der Benutzer Korrekturen bestätigen kann
