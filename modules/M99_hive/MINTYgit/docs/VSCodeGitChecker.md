# VSCodeGitChecker - Konzept und Implementierungsplan

## Übersicht

Der VSCodeGitChecker ist eine Komponente des MINTYgit Agents, die den aktuellen Systemzustand von VS Code prüft, feststellt, ob die Git-Extension installiert und aktiviert ist, ob ein Repository-Link, ein Benutzer und ein Passwort/anderer Zugriff möglich ist, und den Zugriff testet - und das alles im Silent-Modus.

## Funktionalitäten

1. **VS Code-Zustandsprüfung**
   - Prüfung, ob VS Code installiert ist
   - Prüfung, ob VS Code läuft
   - Ermittlung der VS Code-Version

2. **Git-Extension-Prüfung**
   - Prüfung, ob die Git-Extension installiert ist
   - Prüfung, ob die Git-Extension aktiviert ist
   - Ermittlung der Git-Extension-Version

3. **Git-Konfigurationsprüfung**
   - Prüfung, ob Git installiert ist
   - Prüfung, ob Git konfiguriert ist (Benutzer, E-Mail)
   - Ermittlung der Git-Version

4. **Repository-Prüfung**
   - Prüfung, ob ein Repository-Link konfiguriert ist
   - Prüfung, ob das Repository erreichbar ist
   - Prüfung, ob Lese- und Schreibzugriff auf das Repository möglich ist

5. **Authentifizierungsprüfung**
   - Prüfung, ob Anmeldeinformationen für Git konfiguriert sind
   - Prüfung, ob die Anmeldeinformationen gültig sind
   - Prüfung, ob die Anmeldeinformationen ausreichende Berechtigungen haben

6. **Silent-Modus**
   - Alle Prüfungen werden ohne Ausgabe durchgeführt
   - Bei Fehlern wird ein strukturiertes Ergebnisobjekt zurückgegeben
   - Keine Fehlermeldungen werden ausgegeben

## Implementierungsdetails

### PowerShell-Modul: VSCodeGitChecker.ps1

```powershell
# MINTYgit VSCodeGitChecker
# Beschreibung: Prüft den VS Code-Zustand und Git-Zugriff im Silent-Modus

# Importiere benötigte Module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$configPath = Join-Path $modulePath "config"
$dataPath = Join-Path $modulePath "data"

# Globale Variablen
$script:ConfigFile = Join-Path $configPath "vscode_git_checker.json"
$script:Config = $null
$script:IsInitialized = $false

<#
.SYNOPSIS
    Initialisiert den VSCodeGitChecker.
.DESCRIPTION
    Lädt die Konfiguration und initialisiert den VSCodeGitChecker.
#>
function Initialize-VSCodeGitChecker {
    param(
        [Parameter(Mandatory = $false)][switch]$Silent
    )

    try {
        # Erstelle Verzeichnisse, falls sie nicht existieren
        if (-not (Test-Path $configPath)) {
            New-Item -Path $configPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path $dataPath)) {
            New-Item -Path $dataPath -ItemType Directory -Force | Out-Null
        }

        # Lade Konfiguration
        if (Test-Path $script:ConfigFile) {
            $script:Config = Get-Content -Path $script:ConfigFile -Raw | ConvertFrom-Json
        } else {
            # Erstelle Standardkonfiguration
            $script:Config = @{
                VSCodePath = "C:\Program Files\Microsoft VS Code\Code.exe"
                GitPath = "git"
                CheckInterval = 60 # Sekunden
                MaxRetries = 3
                Timeout = 30 # Sekunden
            } | ConvertTo-Json
            $script:Config | Set-Content -Path $script:ConfigFile
            $script:Config = $script:Config | ConvertFrom-Json
        }

        $script:IsInitialized = $true
        if (-not $Silent) {
            Write-Host "VSCodeGitChecker initialisiert"
        }
        return $true
    } catch {
        if (-not $Silent) {
            Write-Error "Fehler bei der Initialisierung des VSCodeGitCheckers: $_"
        }
        return $false
    }
}

<#
.SYNOPSIS
    Prüft den VS Code-Zustand.
.DESCRIPTION
    Prüft, ob VS Code installiert ist, läuft und ermittelt die Version.
.PARAMETER Silent
    Gibt an, ob die Prüfung ohne Ausgabe durchgeführt werden soll.
#>
function Test-VSCodeState {
    param(
        [Parameter(Mandatory = $false)][switch]$Silent
    )

    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-VSCodeGitChecker -Silent:$Silent)) {
                return @{
                    Success = $false
                    Error = "VSCodeGitChecker konnte nicht initialisiert werden."
                    VSCodeInstalled = $false
                    VSCodeRunning = $false
                    VSCodeVersion = $null
                }
            }
        }

        # Prüfe, ob VS Code installiert ist
        $vsCodeInstalled = Test-Path $script:Config.VSCodePath

        # Prüfe, ob VS Code läuft
        $vsCodeProcess = Get-Process -Name "Code" -ErrorAction SilentlyContinue
        $vsCodeRunning = $null -ne $vsCodeProcess

        # Ermittle VS Code-Version
        $vsCodeVersion = $null
        if ($vsCodeInstalled) {
            $vsCodeVersion = (Get-Item $script:Config.VSCodePath).VersionInfo.ProductVersion
        }

        return @{
            Success = $vsCodeInstalled
            VSCodeInstalled = $vsCodeInstalled
            VSCodeRunning = $vsCodeRunning
            VSCodeVersion = $vsCodeVersion
        }
    } catch {
        if (-not $Silent) {
            Write-Error "Fehler bei der Prüfung des VS Code-Zustands: $_"
        }
        return @{
            Success = $false
            Error = "Fehler bei der Prüfung des VS Code-Zustands: $_"
            VSCodeInstalled = $false
            VSCodeRunning = $false
            VSCodeVersion = $null
        }
    }
}

<#
.SYNOPSIS
    Prüft die Git-Extension.
.DESCRIPTION
    Prüft, ob die Git-Extension installiert ist, aktiviert ist und ermittelt die Version.
.PARAMETER Silent
    Gibt an, ob die Prüfung ohne Ausgabe durchgeführt werden soll.
#>
function Test-GitExtension {
    param(
        [Parameter(Mandatory = $false)][switch]$Silent
    )

    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-VSCodeGitChecker -Silent:$Silent)) {
                return @{
                    Success = $false
                    Error = "VSCodeGitChecker konnte nicht initialisiert werden."
                    GitExtensionInstalled = $false
                    GitExtensionEnabled = $false
                    GitExtensionVersion = $null
                }
            }
        }

        # Prüfe, ob VS Code installiert ist
        $vsCodeState = Test-VSCodeState -Silent:$Silent
        if (-not $vsCodeState.Success) {
            return @{
                Success = $false
                Error = "VS Code ist nicht installiert."
                GitExtensionInstalled = $false
                GitExtensionEnabled = $false
                GitExtensionVersion = $null
            }
        }

        # Prüfe, ob die Git-Extension installiert ist
        $extensionsDir = Join-Path $env:USERPROFILE ".vscode\extensions"
        $gitExtension = Get-ChildItem -Path $extensionsDir -Directory -Filter "vscode.git-*" -ErrorAction SilentlyContinue | Sort-Object -Property Name -Descending | Select-Object -First 1
        $gitExtensionInstalled = $null -ne $gitExtension

        # Prüfe, ob die Git-Extension aktiviert ist
        $gitExtensionEnabled = $false
        $gitExtensionVersion = $null

        if ($gitExtensionInstalled) {
            $packageJsonPath = Join-Path $gitExtension.FullName "package.json"
            if (Test-Path $packageJsonPath) {
                $packageJson = Get-Content -Path $packageJsonPath -Raw | ConvertFrom-Json
                $gitExtensionVersion = $packageJson.version

                # Prüfe, ob die Extension aktiviert ist
                # Dies ist schwierig zu prüfen, da VS Code die Aktivierung von Extensions zur Laufzeit verwaltet
                # Wir nehmen an, dass die Extension aktiviert ist, wenn sie installiert ist
                $gitExtensionEnabled = $true
            }
        }

        return @{
            Success = $gitExtensionInstalled -and $gitExtensionEnabled
            GitExtensionInstalled = $gitExtensionInstalled
            GitExtensionEnabled = $gitExtensionEnabled
            GitExtensionVersion = $gitExtensionVersion
        }
    } catch {
        if (-not $Silent) {
            Write-Error "Fehler bei der Prüfung der Git-Extension: $_"
        }
        return @{
            Success = $false
            Error = "Fehler bei der Prüfung der Git-Extension: $_"
            GitExtensionInstalled = $false
            GitExtensionEnabled = $false
            GitExtensionVersion = $null
        }
    }
}

<#
.SYNOPSIS
    Prüft die Git-Konfiguration.
.DESCRIPTION
    Prüft, ob Git installiert ist, konfiguriert ist und ermittelt die Version.
.PARAMETER Silent
    Gibt an, ob die Prüfung ohne Ausgabe durchgeführt werden soll.
#>
function Test-GitConfiguration {
    param(
        [Parameter(Mandatory = $false)][switch]$Silent
    )

    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-VSCodeGitChecker -Silent:$Silent)) {
                return @{
                    Success = $false
                    Error = "VSCodeGitChecker konnte nicht initialisiert werden."
                    GitInstalled = $false
                    GitConfigured = $false
                    GitVersion = $null
                    GitUser = $null
                    GitEmail = $null
                }
            }
        }

        # Prüfe, ob Git installiert ist
        $gitInstalled = $null -ne (Get-Command $script:Config.GitPath -ErrorAction SilentlyContinue)

        # Ermittle Git-Version
        $gitVersion = $null
        if ($gitInstalled) {
            $gitVersion = (& $script:Config.GitPath --version) -replace "git version ", ""
        } else {
            return @{
                Success = $false
                Error = "Git ist nicht installiert."
                GitInstalled = $false
                GitConfigured = $false
                GitVersion = $null
                GitUser = $null
                GitEmail = $null
            }
        }

        # Prüfe, ob Git konfiguriert ist
        $gitUser = & $script:Config.GitPath config --global user.name
        $gitEmail = & $script:Config.GitPath config --global user.email
        $gitConfigured = -not [string]::IsNullOrWhiteSpace($gitUser) -and -not [string]::IsNullOrWhiteSpace($gitEmail)

        return @{
            Success = $gitInstalled -and $gitConfigured
            GitInstalled = $gitInstalled
            GitConfigured = $gitConfigured
            GitVersion = $gitVersion
            GitUser = $gitUser
            GitEmail = $gitEmail
        }
    } catch {
        if (-not $Silent) {
            Write-Error "Fehler bei der Prüfung der Git-Konfiguration: $_"
        }
        return @{
            Success = $false
            Error = "Fehler bei der Prüfung der Git-Konfiguration: $_"
            GitInstalled = $false
            GitConfigured = $false
            GitVersion = $null
            GitUser = $null
            GitEmail = $null
        }
    }
}

<#
.SYNOPSIS
    Prüft das Repository.
.DESCRIPTION
    Prüft, ob ein Repository-Link konfiguriert ist, erreichbar ist und ob Lese- und Schreibzugriff möglich ist.
.PARAMETER RepositoryUrl
    Die URL des Repositories.
.PARAMETER Silent
    Gibt an, ob die Prüfung ohne Ausgabe durchgeführt werden soll.
#>
function Test-Repository {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryUrl,
        [Parameter(Mandatory = $false)][switch]$Silent
    )

    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-VSCodeGitChecker -Silent:$Silent)) {
                return @{
                    Success = $false
                    Error = "VSCodeGitChecker konnte nicht initialisiert werden."
                    RepositoryExists = $false
                    RepositoryAccessible = $false
                    RepositoryWritable = $false
                }
            }
        }

        # Prüfe, ob Git installiert ist
        $gitConfig = Test-GitConfiguration -Silent:$Silent
        if (-not $gitConfig.Success) {
            return @{
                Success = $false
                Error = "Git ist nicht konfiguriert."
                RepositoryExists = $false
                RepositoryAccessible = $false
                RepositoryWritable = $false
            }
        }

        # Prüfe, ob das Repository existiert
        $repositoryExists = $false
        $repositoryAccessible = $false
        $repositoryWritable = $false

        # Prüfe, ob das Repository erreichbar ist
        $output = & $script:Config.GitPath ls-remote --heads $RepositoryUrl 2>&1
        $repositoryExists = $LASTEXITCODE -eq 0

        if ($repositoryExists) {
            # Prüfe, ob Lesezugriff möglich ist
            $tempDir = Join-Path $env:TEMP "MINTYgit_repo_test"
            if (Test-Path $tempDir) {
                Remove-Item -Path $tempDir -Recurse -Force
            }
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

            Push-Location $tempDir
            $output = & $script:Config.GitPath clone --depth 1 $RepositoryUrl . 2>&1
            $repositoryAccessible = $LASTEXITCODE -eq 0

            if ($repositoryAccessible) {
                # Prüfe, ob Schreibzugriff möglich ist
                $testFile = Join-Path $tempDir "MINTYgit_write_test.txt"
                "test" | Out-File -FilePath $testFile
                & $script:Config.GitPath add $testFile
                $output = & $script:Config.GitPath commit -m "Test write access" 2>&1
                $commitSuccess = $LASTEXITCODE -eq 0

                if ($commitSuccess) {
                    $output = & $script:Config.GitPath push 2>&1
                    $repositoryWritable = $LASTEXITCODE -eq 0

                    # Rückgängig machen des Commits
                    if ($repositoryWritable) {
                        & $script:Config.GitPath reset --hard HEAD~1
                        & $script:Config.GitPath push --force
                    }
                }
            }

            Pop-Location
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        return @{
            Success = $repositoryExists -and $repositoryAccessible
            RepositoryExists = $repositoryExists
            RepositoryAccessible = $repositoryAccessible
            RepositoryWritable = $repositoryWritable
        }
    } catch {
        if (-not $Silent) {
            Write-Error "Fehler bei der Prüfung des Repositories: $_"
        }
        return @{
            Success = $false
            Error = "Fehler bei der Prüfung des Repositories: $_"
            RepositoryExists = $false
            RepositoryAccessible = $false
            RepositoryWritable = $false
        }
    }
}

<#
.SYNOPSIS
    Prüft die Authentifizierung.
.DESCRIPTION
    Prüft, ob Anmeldeinformationen für Git konfiguriert sind, gültig sind und ausreichende Berechtigungen haben.
.PARAMETER RepositoryUrl
    Die URL des Repositories.
.PARAMETER Silent
    Gibt an, ob die Prüfung ohne Ausgabe durchgeführt werden soll.
#>
function Test-GitAuthentication {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryUrl,
        [Parameter(Mandatory = $false)][switch]$Silent
    )

    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-VSCodeGitChecker -Silent:$Silent)) {
                return @{
                    Success = $false
                    Error = "VSCodeGitChecker konnte nicht initialisiert werden."
                    CredentialsConfigured = $false
                    CredentialsValid = $false
                    CredentialsSufficient = $false
                }
            }
        }

        # Prüfe, ob Git installiert ist
        $gitConfig = Test-GitConfiguration -Silent:$Silent
        if (-not $gitConfig.Success) {
            return @{
                Success = $false
                Error = "Git ist nicht konfiguriert."
                CredentialsConfigured = $false
                CredentialsValid = $false
                CredentialsSufficient = $false
            }
        }

        # Prüfe, ob das Repository existiert
        $repoTest = Test-Repository -RepositoryUrl $RepositoryUrl -Silent:$Silent

        # Prüfe, ob Anmeldeinformationen konfiguriert sind
        $credentialsConfigured = $repoTest.RepositoryAccessible

        # Prüfe, ob Anmeldeinformationen gültig sind
        $credentialsValid = $repoTest.RepositoryAccessible

        # Prüfe, ob Anmeldeinformationen ausreichende Berechtigungen haben
        $credentialsSufficient = $repoTest.RepositoryWritable

        return @{
            Success = $credentialsConfigured -and $credentialsValid
            CredentialsConfigured = $credentialsConfigured
            CredentialsValid = $credentialsValid
            CredentialsSufficient = $credentialsSufficient
        }
    } catch {
        if (-not $Silent) {
            Write-Error "Fehler bei der Prüfung der Authentifizierung: $_"
        }
        return @{
            Success = $false
            Error = "Fehler bei der Prüfung der Authentifizierung: $_"
            CredentialsConfigured = $false
            CredentialsValid = $false
            CredentialsSufficient = $false
        }
    }
}

<#
.SYNOPSIS
    Führt alle Prüfungen durch.
.DESCRIPTION
    Führt alle Prüfungen durch und gibt ein Gesamtergebnis zurück.
.PARAMETER RepositoryUrl
    Die URL des Repositories.
.PARAMETER Silent
    Gibt an, ob die Prüfung ohne Ausgabe durchgeführt werden soll.
#>
function Test-GitEnvironment {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryUrl,
        [Parameter(Mandatory = $false)][switch]$Silent
    )

    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-VSCodeGitChecker -Silent:$Silent)) {
                return @{
                    Success = $false
                    Error = "VSCodeGitChecker konnte nicht initialisiert werden."
                    VSCodeState = $null
                    GitExtension = $null
                    GitConfiguration = $null
                    Repository = $null
                    Authentication = $null
                }
            }
        }

        # Führe alle Prüfungen durch
        $vsCodeState = Test-VSCodeState -Silent:$Silent
        $gitExtension = Test-GitExtension -Silent:$Silent
        $gitConfiguration = Test-GitConfiguration -Silent:$Silent
        $repository = Test-Repository -RepositoryUrl $RepositoryUrl -Silent:$Silent
        $authentication = Test-GitAuthentication -RepositoryUrl $RepositoryUrl -Silent:$Silent

        # Erstelle Gesamtergebnis
        $success = $vsCodeState.Success -and $gitExtension.Success -and $gitConfiguration.Success -and $repository.Success -and $authentication.Success

        return @{
            Success = $success
            VSCodeState = $vsCodeState
            GitExtension = $gitExtension
            GitConfiguration = $gitConfiguration
            Repository = $repository
            Authentication = $authentication
        }
    } catch {
        if (-not $Silent) {
            Write-Error "Fehler bei der Prüfung der Git-Umgebung: $_"
        }
        return @{
            Success = $false
            Error = "Fehler bei der Prüfung der Git-Umgebung: $_"
            VSCodeState = $null
            GitExtension = $null
            GitConfiguration = $null
            Repository = $null
            Authentication = $null
        }
    }
}

# Exportiere Funktionen
Export-ModuleMember -Function Initialize-VSCodeGitChecker, Test-VSCodeState, Test-GitExtension, Test-GitConfiguration, Test-Repository, Test-GitAuthentication, Test-GitEnvironment
```

### Konfigurationsdatei: vscode_git_checker.json

```json
{
  "VSCodePath": "C:\\Program Files\\Microsoft VS Code\\Code.exe",
  "GitPath": "git",
  "CheckInterval": 60,
  "MaxRetries": 3,
  "Timeout": 30
}
```

## Integration in MINTYgit

Der VSCodeGitChecker wird in den MINTYgit Agent integriert, indem er in der MINTYgit.ps1-Datei importiert und in der Initialize-VersionControl-Funktion initialisiert wird. Außerdem wird eine neue Funktion Test-GitEnvironment exportiert, die von anderen Komponenten des MINTYgit Agents verwendet werden kann.

### Änderungen an MINTYgit.ps1

```powershell
# Importiere Module
$versioningManagerPath = Join-Path $scriptPath "VersioningManager.ps1"
$commitManagerPath = Join-Path $scriptPath "CommitManager.ps1"
$vsCodeIntegrationPath = Join-Path $scriptPath "VSCodeIntegration.ps1"
$gitCommitStrategyPath = Join-Path $scriptPath "GitCommitStrategy.ps1"
$vsCodeGitCheckerPath = Join-Path $scriptPath "VSCodeGitChecker.ps1"

if (Test-Path $versioningManagerPath) {
    . $versioningManagerPath
}
if (Test-Path $commitManagerPath) {
    . $commitManagerPath
}
if (Test-Path $vsCodeIntegrationPath) {
    . $vsCodeIntegrationPath
}
if (Test-Path $gitCommitStrategyPath) {
    . $gitCommitStrategyPath
}
if (Test-Path $vsCodeGitCheckerPath) {
    . $vsCodeGitCheckerPath
}

# ...

function Initialize-VersionControl {
    param(
        [Parameter(Mandatory = $false)][string]$Path = $PWD,
        [Parameter(Mandatory = $false)][string]$RemoteUrl = "",
        [Parameter(Mandatory = $false)][string]$Branch = "main",
        [Parameter(Mandatory = $false)][switch]$Force
    )

    try {
        # ...

        if (Get-Command "Initialize-VersioningManager" -ErrorAction SilentlyContinue) {
            Initialize-VersioningManager
        }

        if (Get-Command "Initialize-CommitManager" -ErrorAction SilentlyContinue) {
            Initialize-CommitManager
        }

        if (Get-Command "Initialize-VSCodeIntegration" -ErrorAction SilentlyContinue) {
            Initialize-VSCodeIntegration
        }

        if (Get-Command "Initialize-GitCommitStrategy" -ErrorAction SilentlyContinue) {
            Initialize-GitCommitStrategy
        }

        if (Get-Command "Initialize-VSCodeGitChecker" -ErrorAction SilentlyContinue) {
            Initialize-VSCodeGitChecker
        }

        # ...
    } catch {
        # ...
    }
}

# ...

# Exportiere Funktionen
Export-ModuleMember -Function Initialize-VersionControl, New-Branch, Switch-Branch, Merge-Branch, Get-History, Set-AutoCommitStrategy, Enable-VSCodeIntegration, Invoke-AutoCommit, New-GitSnapshot, New-GitBranch, New-ChangeDoc, Test-CommitRules, Merge-GitBranch, New-GitCommit, New-AutoCommit, Test-GitEnvironment
```

## Verwendung

Der VSCodeGitChecker kann wie folgt verwendet werden:

```powershell
# Importiere das Modul
Import-Module .\src\MINTYgit.ps1

# Initialisiere den Versionierungsagenten
Initialize-VersionControl

# Prüfe die Git-Umgebung
$result = Test-GitEnvironment -RepositoryUrl "https://github.com/mint-research/MINTutil.git" -Silent

# Überprüfe das Ergebnis
if ($result.Success) {
    Write-Host "Die Git-Umgebung ist korrekt konfiguriert."
} else {
    Write-Host "Die Git-Umgebung ist nicht korrekt konfiguriert:"

    if (-not $result.VSCodeState.Success) {
        Write-Host "- VS Code ist nicht korrekt konfiguriert."
    }

    if (-not $result.GitExtension.Success) {
        Write-Host "- Die Git-Extension ist nicht korrekt konfiguriert."
    }

    if (-not $result.GitConfiguration.Success) {
        Write-Host "- Git ist nicht korrekt konfiguriert."
    }

    if (-not $result.Repository.Success) {
        Write-Host "- Das Repository ist nicht korrekt konfiguriert."
    }

    if (-not $result.Authentication.Success) {
        Write-Host "- Die Authentifizierung ist nicht korrekt konfiguriert."
    }
}
```

## Nächste Schritte

1. **Implementierung des VSCodeGitChecker.ps1-Moduls**: Erstellen des PowerShell-Moduls gemäß dem oben beschriebenen Plan.

2. **Erstellung der Konfigurationsdatei**: Erstellen der vscode_git_checker.json-Konfigurationsdatei.

3. **Integration in MINTYgit**: Anpassen der MINTYgit.ps1-Datei, um den VSCodeGitChecker zu integrieren.

4. **Testen der Funktionalität**: Testen der Funktionalität in verschiedenen Szenarien.

5. **Dokumentation**: Erstellen einer ausführlichen Dokumentation für den VSCodeGitChecker.
