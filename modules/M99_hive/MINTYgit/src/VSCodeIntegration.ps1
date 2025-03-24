# MINTYgit VSCodeIntegration
# Beschreibung: Komponente für die Integration von MINTYgit in VS Code

# Importiere benötigte Module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$configPath = Join-Path $modulePath "config"
$dataPath = Join-Path $modulePath "data"

# Globale Variablen
$script:ConfigFile = Join-Path $configPath "git_config.json"
$script:Config = $null
$script:IsInitialized = $false
$script:VSCodeExtensionPath = $null
$script:StatusBarItem = $null

<#
.SYNOPSIS
    Initialisiert die VS Code-Integration.
.DESCRIPTION
    Lädt die Konfiguration und initialisiert die VS Code-Integration.
#>
function Initialize-VSCodeIntegration {
    try {
        # Lade Konfiguration
        if (Test-Path $script:ConfigFile) {
            $script:Config = Get-Content -Path $script:ConfigFile -Raw | ConvertFrom-Json
        } else {
            Write-Error "Konfigurationsdatei nicht gefunden: $script:ConfigFile"
            return $false
        }

        # Überprüfe, ob VS Code-Integration aktiviert ist
        if (-not $script:Config.VSCodeSettings.EnableExtension) {
            Write-Host "VS Code-Integration ist deaktiviert"
            return $true
        }

        # Erstelle Verzeichnisse, falls sie nicht existieren
        if (-not (Test-Path $dataPath)) {
            New-Item -Path $dataPath -ItemType Directory -Force | Out-Null
        }

        # Bestimme Pfad zur VS Code-Erweiterung
        $vsCodeExtDir = $null

        # Überprüfe verschiedene mögliche Pfade für VS Code-Erweiterungen
        $possiblePaths = @(
            "$env:USERPROFILE\.vscode\extensions",
            "$env:APPDATA\Code\User\extensions",
            "$env:USERPROFILE\AppData\Roaming\Code\User\extensions"
        )

        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                $vsCodeExtDir = $path
                break
            }
        }

        if (-not $vsCodeExtDir) {
            Write-Error "VS Code-Erweiterungsverzeichnis nicht gefunden"
            return $false
        }

        $script:VSCodeExtensionPath = $vsCodeExtDir
        $script:IsInitialized = $true

        Write-Host "VS Code-Integration initialisiert"
        return $true
    } catch {
        Write-Error "Fehler bei der Initialisierung der VS Code-Integration: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Aktiviert die VS Code-Integration.
.DESCRIPTION
    Aktiviert die VS Code-Integration und erstellt die notwendigen Dateien.
#>
function Enable-VSCodeIntegration {
    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-VSCodeIntegration)) {
                return $false
            }
        }

        # Aktualisiere Konfiguration
        $config = Get-Content -Path $script:ConfigFile -Raw | ConvertFrom-Json
        $config.VSCodeSettings.EnableExtension = $true
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile
        $script:Config = $config

        # Erstelle VS Code-Workspace-Einstellungen
        $vsCodeSettingsDir = ".vscode"
        $vsCodeSettingsFile = Join-Path $vsCodeSettingsDir "settings.json"

        if (-not (Test-Path $vsCodeSettingsDir)) {
            New-Item -Path $vsCodeSettingsDir -ItemType Directory -Force | Out-Null
        }

        $vsCodeSettings = $null
        if (Test-Path $vsCodeSettingsFile) {
            $vsCodeSettings = Get-Content -Path $vsCodeSettingsFile -Raw | ConvertFrom-Json
        } else {
            $vsCodeSettings = @{}
        }

        # Füge MINTYgit-Einstellungen hinzu
        if (-not $vsCodeSettings.PSObject.Properties["mintyGit"]) {
            Add-Member -InputObject $vsCodeSettings -MemberType NoteProperty -Name "mintyGit" -Value @{
                "enabled"              = $true
                "autoCommit"           = $config.RepositorySettings.AutoCommit
                "commitOnSave"         = $config.VSCodeSettings.CommitOnSave
                "showNotifications"    = $config.VSCodeSettings.ShowNotifications
                "statusBarIntegration" = $config.VSCodeSettings.StatusBarIntegration
            }
        } else {
            $vsCodeSettings.mintyGit.enabled = $true
            $vsCodeSettings.mintyGit.autoCommit = $config.RepositorySettings.AutoCommit
            $vsCodeSettings.mintyGit.commitOnSave = $config.VSCodeSettings.CommitOnSave
            $vsCodeSettings.mintyGit.showNotifications = $config.VSCodeSettings.ShowNotifications
            $vsCodeSettings.mintyGit.statusBarIntegration = $config.VSCodeSettings.StatusBarIntegration
        }

        # Speichere VS Code-Einstellungen
        $vsCodeSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $vsCodeSettingsFile

        # Erstelle VS Code-Tasks für Git-Operationen
        $vsCodeTasksFile = Join-Path $vsCodeSettingsDir "tasks.json"
        $vsCodeTasks = $null
        if (Test-Path $vsCodeTasksFile) {
            $vsCodeTasks = Get-Content -Path $vsCodeTasksFile -Raw | ConvertFrom-Json
        } else {
            $vsCodeTasks = @{
                "version" = "2.0.0"
                "tasks"   = @()
            }
        }

        # Definiere MINTYgit-Tasks
        $mintyGitTasks = @(
            @{
                "label"          = "MINTYgit: Commit"
                "type"           = "shell"
                "command"        = "powershell.exe"
                "args"           = @(
                    "-ExecutionPolicy", "Bypass",
                    "-File", "`"$modulePath\src\MINTYgit.ps1`"",
                    "-Command", "New-GitCommit -Path `"`${workspaceFolder}`" -Message `"`${input:commitMessage}`" -Type `"`${input:commitType}`""
                )
                "problemMatcher" = @()
                "presentation"   = @{
                    "reveal" = "always"
                    "panel"  = "new"
                }
                "group"          = @{
                    "kind"      = "build"
                    "isDefault" = $false
                }
            },
            @{
                "label"          = "MINTYgit: Push"
                "type"           = "shell"
                "command"        = "powershell.exe"
                "args"           = @(
                    "-ExecutionPolicy", "Bypass",
                    "-File", "`"$modulePath\src\MINTYgit.ps1`"",
                    "-Command", "Invoke-GitPush -Path `"`${workspaceFolder}`""
                )
                "problemMatcher" = @()
                "presentation"   = @{
                    "reveal" = "always"
                    "panel"  = "new"
                }
                "group"          = @{
                    "kind"      = "build"
                    "isDefault" = $false
                }
            },
            @{
                "label"          = "MINTYgit: Pull"
                "type"           = "shell"
                "command"        = "powershell.exe"
                "args"           = @(
                    "-ExecutionPolicy", "Bypass",
                    "-File", "`"$modulePath\src\MINTYgit.ps1`"",
                    "-Command", "Invoke-GitPull -Path `"`${workspaceFolder}`""
                )
                "problemMatcher" = @()
                "presentation"   = @{
                    "reveal" = "always"
                    "panel"  = "new"
                }
                "group"          = @{
                    "kind"      = "build"
                    "isDefault" = $false
                }
            },
            @{
                "label"          = "MINTYgit: Auto-Commit"
                "type"           = "shell"
                "command"        = "powershell.exe"
                "args"           = @(
                    "-ExecutionPolicy", "Bypass",
                    "-File", "`"$modulePath\src\MINTYgit.ps1`"",
                    "-Command", "Invoke-AutoCommit -Path `"`${workspaceFolder}`""
                )
                "problemMatcher" = @()
                "presentation"   = @{
                    "reveal" = "always"
                    "panel"  = "new"
                }
                "group"          = @{
                    "kind"      = "build"
                    "isDefault" = $false
                }
            }
        )

        # Füge MINTYgit-Tasks hinzu, falls sie noch nicht existieren
        foreach ($task in $mintyGitTasks) {
            $existingTask = $vsCodeTasks.tasks | Where-Object { $_.label -eq $task.label }
            if (-not $existingTask) {
                $vsCodeTasks.tasks += $task
            }
        }

        # Füge Eingabeaufforderungen hinzu
        if (-not $vsCodeTasks.PSObject.Properties["inputs"]) {
            Add-Member -InputObject $vsCodeTasks -MemberType NoteProperty -Name "inputs" -Value @()
        }

        $commitTypeInput = @{
            "id"          = "commitType"
            "type"        = "pickString"
            "description" = "Wähle den Typ des Commits"
            "options"     = $config.CommitSettings.CommitTypes
            "default"     = "chore"
        }

        $commitMessageInput = @{
            "id"          = "commitMessage"
            "type"        = "promptString"
            "description" = "Gib eine Commit-Nachricht ein"
            "default"     = "Änderungen"
        }

        # Füge Eingabeaufforderungen hinzu, falls sie noch nicht existieren
        $existingCommitTypeInput = $vsCodeTasks.inputs | Where-Object { $_.id -eq "commitType" }
        if (-not $existingCommitTypeInput) {
            $vsCodeTasks.inputs += $commitTypeInput
        }

        $existingCommitMessageInput = $vsCodeTasks.inputs | Where-Object { $_.id -eq "commitMessage" }
        if (-not $existingCommitMessageInput) {
            $vsCodeTasks.inputs += $commitMessageInput
        }

        # Speichere VS Code-Tasks
        $vsCodeTasks | ConvertTo-Json -Depth 10 | Set-Content -Path $vsCodeTasksFile

        # Erstelle VS Code-Keybindings für Git-Operationen
        $vsCodeKeybindingsDir = "$env:APPDATA\Code\User"
        $vsCodeKeybindingsFile = Join-Path $vsCodeKeybindingsDir "keybindings.json"

        $vsCodeKeybindings = @()
        if (Test-Path $vsCodeKeybindingsFile) {
            $vsCodeKeybindings = Get-Content -Path $vsCodeKeybindingsFile -Raw | ConvertFrom-Json
        }

        # Definiere MINTYgit-Keybindings
        $mintyGitKeybindings = @(
            @{
                "key"     = "ctrl+alt+c"
                "command" = "workbench.action.tasks.runTask"
                "args"    = "MINTYgit: Commit"
                "when"    = "editorTextFocus"
            },
            @{
                "key"     = "ctrl+alt+p"
                "command" = "workbench.action.tasks.runTask"
                "args"    = "MINTYgit: Push"
                "when"    = "editorTextFocus"
            },
            @{
                "key"     = "ctrl+alt+l"
                "command" = "workbench.action.tasks.runTask"
                "args"    = "MINTYgit: Pull"
                "when"    = "editorTextFocus"
            },
            @{
                "key"     = "ctrl+alt+a"
                "command" = "workbench.action.tasks.runTask"
                "args"    = "MINTYgit: Auto-Commit"
                "when"    = "editorTextFocus"
            }
        )

        # Füge MINTYgit-Keybindings hinzu, falls sie noch nicht existieren
        foreach ($keybinding in $mintyGitKeybindings) {
            $existingKeybinding = $vsCodeKeybindings | Where-Object {
                $_.key -eq $keybinding.key -and $_.command -eq $keybinding.command -and $_.args -eq $keybinding.args
            }
            if (-not $existingKeybinding) {
                $vsCodeKeybindings += $keybinding
            }
        }

        # Speichere VS Code-Keybindings
        if (-not (Test-Path $vsCodeKeybindingsDir)) {
            New-Item -Path $vsCodeKeybindingsDir -ItemType Directory -Force | Out-Null
        }
        $vsCodeKeybindings | ConvertTo-Json -Depth 10 | Set-Content -Path $vsCodeKeybindingsFile

        Write-Host "VS Code-Integration aktiviert"
        return $true
    } catch {
        Write-Error "Fehler beim Aktivieren der VS Code-Integration: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Deaktiviert die VS Code-Integration.
.DESCRIPTION
    Deaktiviert die VS Code-Integration und entfernt die erstellten Dateien.
#>
function Disable-VSCodeIntegration {
    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-VSCodeIntegration)) {
                return $false
            }
        }

        # Aktualisiere Konfiguration
        $config = Get-Content -Path $script:ConfigFile -Raw | ConvertFrom-Json
        $config.VSCodeSettings.EnableExtension = $false
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile
        $script:Config = $config

        # Aktualisiere VS Code-Workspace-Einstellungen
        $vsCodeSettingsDir = ".vscode"
        $vsCodeSettingsFile = Join-Path $vsCodeSettingsDir "settings.json"

        if (Test-Path $vsCodeSettingsFile) {
            $vsCodeSettings = Get-Content -Path $vsCodeSettingsFile -Raw | ConvertFrom-Json

            if ($vsCodeSettings.PSObject.Properties["mintyGit"]) {
                $vsCodeSettings.mintyGit.enabled = $false
                $vsCodeSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $vsCodeSettingsFile
            }
        }

        Write-Host "VS Code-Integration deaktiviert"
        return $true
    } catch {
        Write-Error "Fehler beim Deaktivieren der VS Code-Integration: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Registriert einen VS Code-Dateispeicher-Event.
.DESCRIPTION
    Registriert einen Event, der bei jedem Speichern einer Datei in VS Code ausgelöst wird.
.PARAMETER Path
    Der Pfad zum Repository.
#>
function Register-VSCodeSaveEvent {
    param(
        [Parameter(Mandatory = $false)][string]$Path = $PWD
    )

    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-VSCodeIntegration)) {
                return $false
            }
        }

        # Überprüfe, ob CommitOnSave aktiviert ist
        if (-not $script:Config.VSCodeSettings.CommitOnSave) {
            Write-Host "CommitOnSave ist deaktiviert"
            return $true
        }

        # Erstelle Datei-Watcher für VS Code-Workspace
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $Path
        $watcher.IncludeSubdirectories = $true
        $watcher.EnableRaisingEvents = $true

        # Registriere Event für Dateiänderungen
        $action = {
            $path = $Event.SourceEventArgs.FullPath
            $changeType = $Event.SourceEventArgs.ChangeType
            $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

            # Ignoriere .git-Verzeichnis
            if ($path -match "\.git\\") {
                return
            }

            Write-Host "[$timeStamp] Datei $changeType`: $path"

            # Importiere CommitManager
            $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
            $modulePath = Split-Path -Parent $scriptPath
            $commitManagerPath = Join-Path $modulePath "src\CommitManager.ps1"
            . $commitManagerPath

            # Registriere Dateiänderung
            Register-FileChange -File $path -ChangeType $changeType
        }

        # Registriere Events
        Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action -SourceIdentifier "VSCodeFileChanged" | Out-Null
        Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action -SourceIdentifier "VSCodeFileCreated" | Out-Null
        Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action -SourceIdentifier "VSCodeFileDeleted" | Out-Null
        Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action -SourceIdentifier "VSCodeFileRenamed" | Out-Null

        Write-Host "VS Code-Dateispeicher-Events registriert"
        return $true
    } catch {
        Write-Error "Fehler beim Registrieren der VS Code-Dateispeicher-Events: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Deregistriert VS Code-Dateispeicher-Events.
.DESCRIPTION
    Deregistriert die Events, die bei Dateispeicherungen in VS Code ausgelöst werden.
#>
function Unregister-VSCodeSaveEvent {
    try {
        Unregister-Event -SourceIdentifier "VSCodeFileChanged" -ErrorAction SilentlyContinue
        Unregister-Event -SourceIdentifier "VSCodeFileCreated" -ErrorAction SilentlyContinue
        Unregister-Event -SourceIdentifier "VSCodeFileDeleted" -ErrorAction SilentlyContinue
        Unregister-Event -SourceIdentifier "VSCodeFileRenamed" -ErrorAction SilentlyContinue

        Write-Host "VS Code-Dateispeicher-Events deregistriert"
        return $true
    } catch {
        Write-Error "Fehler beim Deregistrieren der VS Code-Dateispeicher-Events: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Aktualisiert die VS Code-Statusleiste.
.DESCRIPTION
    Aktualisiert die Anzeige in der VS Code-Statusleiste.
.PARAMETER Path
    Der Pfad zum Repository.
#>
function Update-VSCodeStatusBar {
    param(
        [Parameter(Mandatory = $false)][string]$Path = $PWD
    )

    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-VSCodeIntegration)) {
                return $false
            }
        }

        # Überprüfe, ob StatusBarIntegration aktiviert ist
        if (-not $script:Config.VSCodeSettings.StatusBarIntegration) {
            return $true
        }

        # Überprüfe, ob das Verzeichnis ein Git-Repository ist
        if (-not (Test-Path (Join-Path $Path ".git"))) {
            return $true
        }

        # Wechsle in das Verzeichnis
        Push-Location $Path

        try {
            # Hole aktuellen Branch
            $currentBranch = git rev-parse --abbrev-ref HEAD
            if (-not $?) {
                throw "Fehler beim Ermitteln des aktuellen Branches."
            }

            # Hole Status
            $status = git status --porcelain
            $changedFiles = ($status | Measure-Object).Count

            # Erstelle Statustext
            $statusText = "$(if ($changedFiles -gt 0) { '●' } else { '○' }) $currentBranch ($changedFiles)"

            # Aktualisiere Statusleiste
            # Hinweis: In einer echten Implementierung würde hier die VS Code-API verwendet werden
            # Da dies nur ein MVP ist, wird hier nur eine Ausgabe erzeugt
            Write-Host "VS Code-Statusleiste: $statusText"

            return $true
        } finally {
            # Zurück zum ursprünglichen Verzeichnis
            Pop-Location
        }
    } catch {
        Write-Error "Fehler beim Aktualisieren der VS Code-Statusleiste: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Zeigt eine VS Code-Benachrichtigung an.
.DESCRIPTION
    Zeigt eine Benachrichtigung in VS Code an.
.PARAMETER Message
    Die Nachricht, die angezeigt werden soll.
.PARAMETER Type
    Der Typ der Benachrichtigung (Information, Warning, Error).
#>
function Show-VSCodeNotification {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $false)][ValidateSet("Information", "Warning", "Error")][string]$Type = "Information"
    )

    try {
        if (-not $script:IsInitialized) {
            if (-not (Initialize-VSCodeIntegration)) {
                return $false
            }
        }

        # Überprüfe, ob ShowNotifications aktiviert ist
        if (-not $script:Config.VSCodeSettings.ShowNotifications) {
            return $true
        }

        # Zeige Benachrichtigung
        # Hinweis: In einer echten Implementierung würde hier die VS Code-API verwendet werden
        # Da dies nur ein MVP ist, wird hier nur eine Ausgabe erzeugt
        Write-Host "VS Code-Benachrichtigung ($Type): $Message"

        return $true
    } catch {
        Write-Error "Fehler beim Anzeigen der VS Code-Benachrichtigung: $_"
        return $false
    }
}

# Exportiere Funktionen
Export-ModuleMember -Function Initialize-VSCodeIntegration, Enable-VSCodeIntegration, Disable-VSCodeIntegration, Register-VSCodeSaveEvent, Unregister-VSCodeSaveEvent, Update-VSCodeStatusBar, Show-VSCodeNotification
