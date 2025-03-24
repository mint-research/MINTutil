# Beispiel für die Verwendung von MINTYcoder

# Importieren des Moduls
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$srcPath = Join-Path $modulePath "src"
$modulePath = Join-Path $srcPath "MINTYcoder.ps1"

# Importieren des Moduls
. $modulePath

# Initialisieren des Code-Agents
Write-Host "Initialisiere Code-Agent..."
Initialize-Coder

# Generieren von Code
Write-Host "`nGeneriere Code..."
New-Code -Template "Function" -Name "Get-Data" -Parameters @("Path", "Filter") -OutputPath "path/to/output.ps1" -Language "PowerShell" -IncludeComments $true -IncludeExamples $true -IncludeTests $true

# Analysieren von Code
Write-Host "`nAnalysiere Code..."
Get-CodeAnalysis -Path "path/to/code.ps1" -Rules "All" -Severity "Warning"

# Optimieren von Code
Write-Host "`nOptimiere Code..."
Optimize-Code -Path "path/to/code.ps1" -OutputPath "path/to/optimized.ps1" -OptimizationLevel "Medium" -PreserveComments $true -PreserveFormatting $true

# Refactoring durchführen
Write-Host "`nFühre Refactoring durch..."
Invoke-Refactoring -Path "path/to/code.ps1" -Operation "ExtractMethod" -OutputPath "path/to/refactored.ps1" -PreserveComments $true -PreserveFormatting $true

# Dokumentation generieren
Write-Host "`nGeneriere Dokumentation..."
New-Documentation -Path "path/to/code.ps1" -OutputPath "path/to/docs.md" -Format "Markdown" -IncludeExamples $true -IncludeParameters $true -IncludeReturns $true

Write-Host "`nBeispiel abgeschlossen."
