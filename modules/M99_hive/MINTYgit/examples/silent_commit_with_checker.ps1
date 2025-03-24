# Beispiel für die Integration des VSCodeGitCheckers in die silent commit Funktionalität

# Importieren des Moduls
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$srcPath = Join-Path $modulePath "src"
$modulePath = Join-Path $srcPath "MINTYgit.ps1"

# Importieren des Moduls
. $modulePath

# Initialisieren des Versionierungsagenten
Write-Host "Initialisiere Versionierungsagent..."
Initialize-VersionControl

<#
.SYNOPSIS
    Führt einen silent commit mit Umgebungsprüfung durch.
.DESCRIPTION
    Prüft die Git-Umgebung im Silent-Modus und führt einen silent commit durch, wenn die Umgebung korrekt konfiguriert ist.
.PARAMETER Path
    Der Pfad zum Repository.
.PARAMETER Message
    Die Commit-Nachricht.
.PARAMETER RepositoryUrl
    Die URL des Repositories.
#>
function Invoke-SilentCommitWithCheck {
    param(
        [Parameter(Mandatory = $false)][string]$Path = $PWD,
        [Parameter(Mandatory = $false)][string]$Message = "Automatischer Commit",
        [Parameter(Mandatory = $true)][string]$RepositoryUrl
    )

    try {
        # Prüfe die Git-Umgebung im Silent-Modus
        $gitEnvironment = Test-GitEnvironment -RepositoryUrl $RepositoryUrl -Silent

        if (-not $gitEnvironment.Success) {
            # Wenn die Umgebung nicht korrekt konfiguriert ist, prüfe die einzelnen Komponenten

            # Prüfe VS Code-Zustand
            if (-not $gitEnvironment.VSCodeState.Success) {
                Write-Host "VS Code ist nicht korrekt konfiguriert."
                $vsCodeState = Test-VSCodeState
                Write-Host "VS Code ist installiert: $($vsCodeState.VSCodeInstalled)"
                Write-Host "VS Code läuft: $($vsCodeState.VSCodeRunning)"
                Write-Host "VS Code-Version: $($vsCodeState.VSCodeVersion)"
                return $false
            }

            # Prüfe Git-Extension
            if (-not $gitEnvironment.GitExtension.Success) {
                Write-Host "Die Git-Extension ist nicht korrekt konfiguriert."
                $gitExtension = Test-GitExtension
                Write-Host "Git-Extension ist installiert: $($gitExtension.GitExtensionInstalled)"
                Write-Host "Git-Extension ist aktiviert: $($gitExtension.GitExtensionEnabled)"
                Write-Host "Git-Extension-Version: $($gitExtension.GitExtensionVersion)"
                return $false
            }

            # Prüfe Git-Konfiguration
            if (-not $gitEnvironment.GitConfiguration.Success) {
                Write-Host "Git ist nicht korrekt konfiguriert."
                $gitConfiguration = Test-GitConfiguration
                Write-Host "Git ist installiert: $($gitConfiguration.GitInstalled)"
                Write-Host "Git ist konfiguriert: $($gitConfiguration.GitConfigured)"
                Write-Host "Git-Version: $($gitConfiguration.GitVersion)"
                Write-Host "Git-Benutzer: $($gitConfiguration.GitUser)"
                Write-Host "Git-E-Mail: $($gitConfiguration.GitEmail)"

                # Wenn Git nicht konfiguriert ist, frage nach Benutzerinformationen
                if ($gitConfiguration.GitInstalled -and -not $gitConfiguration.GitConfigured) {
                    $gitUser = Read-Host "Bitte gib deinen Namen ein"
                    $gitEmail = Read-Host "Bitte gib deine E-Mail-Adresse ein"

                    if (-not [string]::IsNullOrWhiteSpace($gitUser) -and -not [string]::IsNullOrWhiteSpace($gitEmail)) {
                        git config --global user.name $gitUser
                        git config --global user.email $gitEmail
                        Write-Host "Git-Benutzer konfiguriert."
                    } else {
                        Write-Host "Git-Benutzer konnte nicht konfiguriert werden."
                        return $false
                    }
                } else {
                    return $false
                }
            }

            # Prüfe Repository
            if (-not $gitEnvironment.Repository.Success) {
                Write-Host "Das Repository ist nicht korrekt konfiguriert."
                $repository = Test-Repository -RepositoryUrl $RepositoryUrl
                Write-Host "Repository existiert: $($repository.RepositoryExists)"
                Write-Host "Repository ist zugänglich: $($repository.RepositoryAccessible)"
                Write-Host "Repository ist beschreibbar: $($repository.RepositoryWritable)"
                return $false
            }

            # Prüfe Authentifizierung
            if (-not $gitEnvironment.Authentication.Success) {
                Write-Host "Die Authentifizierung ist nicht korrekt konfiguriert."
                $authentication = Test-GitAuthentication -RepositoryUrl $RepositoryUrl
                Write-Host "Anmeldeinformationen sind konfiguriert: $($authentication.CredentialsConfigured)"
                Write-Host "Anmeldeinformationen sind gültig: $($authentication.CredentialsValid)"
                Write-Host "Anmeldeinformationen haben ausreichende Berechtigungen: $($authentication.CredentialsSufficient)"
                return $false
            }

            # Wenn wir hier ankommen, sollte die Umgebung korrekt konfiguriert sein
            # Prüfe erneut
            $gitEnvironment = Test-GitEnvironment -RepositoryUrl $RepositoryUrl -Silent
            if (-not $gitEnvironment.Success) {
                Write-Host "Die Git-Umgebung konnte nicht korrekt konfiguriert werden."
                return $false
            }
        }

        # Führe silent commit durch
        return (New-AutoCommit -Path $Path -Message $Message)
    } catch {
        Write-Error "Fehler beim Ausführen des silent commits mit Umgebungsprüfung: $_"
        return $false
    }
}

# Beispiel für die Verwendung
$repositoryUrl = "https://github.com/mint-research/MINTutil.git"

# Führe silent commit mit Umgebungsprüfung durch
Write-Host "`nFühre silent commit mit Umgebungsprüfung durch..."
$result = Invoke-SilentCommitWithCheck -Message "Automatischer Commit mit Umgebungsprüfung" -RepositoryUrl $repositoryUrl
Write-Host "Silent commit erfolgreich: $result"

Write-Host "`nBeispiel abgeschlossen."
