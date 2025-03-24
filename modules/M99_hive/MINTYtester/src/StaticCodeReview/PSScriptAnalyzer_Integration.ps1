# PSScriptAnalyzer Integration für das Static Code Review-Script

# ============= PSScriptAnalyzer Integration =============

function Start-PSScriptAnalyzerReview {
    Write-Host "Starte PSScriptAnalyzer-Review..."

    # Prüfen, ob PSScriptAnalyzer installiert ist
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-Warning "PSScriptAnalyzer ist nicht installiert. Installiere es mit 'Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force'"
        return
    }

    # PSScriptAnalyzer-Einstellungen laden
    $settingsPath = Join-Path -Path $script:BasePath -ChildPath ".vscode\PSScriptAnalyzerSettings.psd1"
    if (-not (Test-Path -Path $settingsPath)) {
        Write-Warning "PSScriptAnalyzer-Einstellungen nicht gefunden unter: $settingsPath"
        Write-Warning "Verwende Standardeinstellungen"
        $settingsPath = $null
    }

    # Alle PowerShell-Dateien im Projekt durchsuchen
    $psFiles = Get-ChildItem -Path $script:BasePath -Filter "*.ps1" -Recurse

    foreach ($file in $psFiles) {
        # Datei bereits gezählt? Wenn nicht, zählen
        if (-not ($script:ReportData.Problems | Where-Object { $_.FilePath -eq $file.FullName })) {
            $script:ReportData.Summary.TotalFiles++
        }

        # PSScriptAnalyzer ausführen
        $results = Invoke-ScriptAnalyzer -Path $file.FullName -Settings $settingsPath

        foreach ($result in $results) {
            $severity = switch ($result.Severity) {
                "Error" { "High" }
                "Warning" { "Medium" }
                "Information" { "Low" }
                default { "Low" }
            }

            # Automatische Korrektur möglich?
            $autoCorrectableRules = @(
                "PSUseConsistentIndentation",
                "PSUseConsistentWhitespace",
                "PSAlignAssignmentStatement",
                "PSAvoidUsingCmdletAliases",
                "PSAvoidUsingPositionalParameters"
            )
            $isAutoCorrectable = $autoCorrectableRules -contains $result.RuleName

            # Korrekturvorschlag generieren
            $recommendation = switch ($result.RuleName) {
                "PSAvoidUsingCmdletAliases" {
                    $alias = $result.Extent.Text
                    $command = Get-Alias -Name $alias -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ReferencedCommand
                    "Verwenden Sie den vollständigen Befehlsnamen '$command' anstelle des Alias '$alias'"
                }
                "PSUseConsistentIndentation" { "Verwenden Sie konsistente Einrückung (4 Leerzeichen)" }
                "PSUseConsistentWhitespace" { "Verwenden Sie konsistente Leerzeichen um Operatoren, Klammern und Trennzeichen" }
                "PSAlignAssignmentStatement" { "Richten Sie Zuweisungsanweisungen konsistent aus" }
                default { $result.Message }
            }

            # Problem hinzufügen
            Add-Problem -FilePath $file.FullName -LineNumber $result.Line `
                -Description "[$($result.RuleName)] $($result.Message)" `
                -Severity $severity `
                -Recommendation $recommendation `
                -AutoCorrectable $isAutoCorrectable `
                -CurrentCode $result.Extent.Text `
                -CorrectedCode (Get-CorrectedCode -Rule $result.RuleName -OriginalCode $result.Extent.Text)
        }
    }

    Write-Host "PSScriptAnalyzer-Review abgeschlossen."
}

# Hilfsfunktion zum Generieren von korrigiertem Code
function Get-CorrectedCode {
    param (
        [string]$Rule,
        [string]$OriginalCode
    )

    switch ($Rule) {
        "PSAvoidUsingCmdletAliases" {
            $alias = $OriginalCode.Trim()
            $command = Get-Alias -Name $alias -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ReferencedCommand
            if ($command) {
                return $command
            }
        }
        # Weitere Regeln können hier hinzugefügt werden
    }

    # Standardmäßig den Originalcode zurückgeben
    return $OriginalCode
}

# ============= Änderungen am Hauptprogramm =============

# 1. Aktualisieren Sie den ValidateSet für den $Levels-Parameter:
# [ValidateSet("Architecture", "Module", "Function", "Code", "PSScriptAnalyzer", "All")]

# 2. Fügen Sie den folgenden Code nach dem Start-CodeReview-Aufruf ein:
# if ($Levels -contains "All" -or $Levels -contains "PSScriptAnalyzer") {
#     Start-PSScriptAnalyzerReview
# }

# ============= Anleitung zur Integration =============

# 1. Kopieren Sie die Funktionen Start-PSScriptAnalyzerReview und Get-CorrectedCode in das static_code_review.ps1-Script
#    direkt vor dem Hauptprogramm (nach der Start-CodeReview-Funktion).
#
# 2. Aktualisieren Sie den ValidateSet für den $Levels-Parameter, um "PSScriptAnalyzer" hinzuzufügen:
#    [ValidateSet("Architecture", "Module", "Function", "Code", "PSScriptAnalyzer", "All")]
#
# 3. Fügen Sie den folgenden Code nach dem Start-CodeReview-Aufruf im Hauptprogramm ein:
#    if ($Levels -contains "All" -or $Levels -contains "PSScriptAnalyzer") {
#        Start-PSScriptAnalyzerReview
#    }
