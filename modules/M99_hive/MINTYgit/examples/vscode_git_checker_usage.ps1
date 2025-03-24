# Beispiel für die Verwendung des VSCodeGitCheckers

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

# Definiere Repository-URL
$repositoryUrl = "https://github.com/mint-research/MINTutil.git"

# Prüfe VS Code-Zustand
Write-Host "`nPrüfe VS Code-Zustand..."
$vsCodeState = Test-VSCodeState
if ($vsCodeState.Success) {
    Write-Host "VS Code ist installiert: $($vsCodeState.VSCodeInstalled)"
    Write-Host "VS Code läuft: $($vsCodeState.VSCodeRunning)"
    Write-Host "VS Code-Version: $($vsCodeState.VSCodeVersion)"
} else {
    Write-Host "Fehler bei der Prüfung des VS Code-Zustands: $($vsCodeState.Error)"
}

# Prüfe Git-Extension
Write-Host "`nPrüfe Git-Extension..."
$gitExtension = Test-GitExtension
if ($gitExtension.Success) {
    Write-Host "Git-Extension ist installiert: $($gitExtension.GitExtensionInstalled)"
    Write-Host "Git-Extension ist aktiviert: $($gitExtension.GitExtensionEnabled)"
    Write-Host "Git-Extension-Version: $($gitExtension.GitExtensionVersion)"
} else {
    Write-Host "Fehler bei der Prüfung der Git-Extension: $($gitExtension.Error)"
}

# Prüfe Git-Konfiguration
Write-Host "`nPrüfe Git-Konfiguration..."
$gitConfiguration = Test-GitConfiguration
if ($gitConfiguration.Success) {
    Write-Host "Git ist installiert: $($gitConfiguration.GitInstalled)"
    Write-Host "Git ist konfiguriert: $($gitConfiguration.GitConfigured)"
    Write-Host "Git-Version: $($gitConfiguration.GitVersion)"
    Write-Host "Git-Benutzer: $($gitConfiguration.GitUser)"
    Write-Host "Git-E-Mail: $($gitConfiguration.GitEmail)"
} else {
    Write-Host "Fehler bei der Prüfung der Git-Konfiguration: $($gitConfiguration.Error)"
}

# Prüfe Repository
Write-Host "`nPrüfe Repository..."
$repository = Test-Repository -RepositoryUrl $repositoryUrl
if ($repository.Success) {
    Write-Host "Repository existiert: $($repository.RepositoryExists)"
    Write-Host "Repository ist zugänglich: $($repository.RepositoryAccessible)"
    Write-Host "Repository ist beschreibbar: $($repository.RepositoryWritable)"
} else {
    Write-Host "Fehler bei der Prüfung des Repositories: $($repository.Error)"
}

# Prüfe Authentifizierung
Write-Host "`nPrüfe Authentifizierung..."
$authentication = Test-GitAuthentication -RepositoryUrl $repositoryUrl
if ($authentication.Success) {
    Write-Host "Anmeldeinformationen sind konfiguriert: $($authentication.CredentialsConfigured)"
    Write-Host "Anmeldeinformationen sind gültig: $($authentication.CredentialsValid)"
    Write-Host "Anmeldeinformationen haben ausreichende Berechtigungen: $($authentication.CredentialsSufficient)"
} else {
    Write-Host "Fehler bei der Prüfung der Authentifizierung: $($authentication.Error)"
}

# Prüfe gesamte Git-Umgebung
Write-Host "`nPrüfe gesamte Git-Umgebung..."
$gitEnvironment = Test-GitEnvironment -RepositoryUrl $repositoryUrl
if ($gitEnvironment.Success) {
    Write-Host "Die Git-Umgebung ist korrekt konfiguriert."
} else {
    Write-Host "Die Git-Umgebung ist nicht korrekt konfiguriert:"

    if (-not $gitEnvironment.VSCodeState.Success) {
        Write-Host "- VS Code ist nicht korrekt konfiguriert."
    }

    if (-not $gitEnvironment.GitExtension.Success) {
        Write-Host "- Die Git-Extension ist nicht korrekt konfiguriert."
    }

    if (-not $gitEnvironment.GitConfiguration.Success) {
        Write-Host "- Git ist nicht korrekt konfiguriert."
    }

    if (-not $gitEnvironment.Repository.Success) {
        Write-Host "- Das Repository ist nicht korrekt konfiguriert."
    }

    if (-not $gitEnvironment.Authentication.Success) {
        Write-Host "- Die Authentifizierung ist nicht korrekt konfiguriert."
    }
}

# Prüfe im Silent-Modus
Write-Host "`nPrüfe im Silent-Modus..."
$silentResult = Test-GitEnvironment -RepositoryUrl $repositoryUrl -Silent
Write-Host "Silent-Prüfung erfolgreich: $($silentResult.Success)"

Write-Host "`nBeispiel abgeschlossen."
