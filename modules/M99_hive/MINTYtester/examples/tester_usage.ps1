# Beispiel für die Verwendung von MINTYtester

# Importieren des Moduls
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$srcPath = Join-Path $modulePath "src"
$modulePath = Join-Path $srcPath "MINTYtester.ps1"

# Importieren des Moduls
. $modulePath

# Initialisieren des Test-Agents
Write-Host "Initialisiere Test-Agent..."
Initialize-Tester

# Ausführen von Tests
Write-Host "`nFühre Tests aus..."
Run-Tests -Path "path/to/tests" -Filter "*.Tests.ps1" -Parallel $true -MaxParallelTests 3 -Timeout 30

# Analysieren der Testabdeckung
Write-Host "`nAnalysiere Testabdeckung..."
Get-TestCoverage -Path "path/to/code" -MinimumCoverage 80 -IncludeUntested $true

# Validieren von Code
Write-Host "`nValidiere Code..."
Validate-Code -Path "path/to/code" -Rules "PSScriptAnalyzer" -Severity "Warning"

# Analysieren von Fehlern
Write-Host "`nAnalysiere Fehler..."
$errors = @(
    [PSCustomObject]@{
        Message    = "Test error message"
        StackTrace = "at line 10 in file.ps1"
        Context    = "function Test-Function { ... }"
    }
)
Analyze-Errors -Errors $errors -MaxErrors 10 -IncludeStackTrace $true -IncludeContext $true

# Generieren eines Berichts
Write-Host "`nGeneriere Testbericht..."
New-TestReport -OutputPath "path/to/report.html" -ReportFormat "HTML" -IncludeDetails $true -IncludeTimestamp $true -IncludeEnvironment $true

Write-Host "`nBeispiel abgeschlossen."
