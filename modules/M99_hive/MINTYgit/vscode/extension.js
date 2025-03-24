// MINTYgit VS Code Extension
// Beschreibung: VS Code-Erweiterung für die Integration von MINTYgit

const vscode = require('vscode');
const path = require('path');
const { exec } = require('child_process');

// Globale Variablen
let statusBarItem;
let autoCommitTimer;
let fileWatcher;
let pendingChanges = [];
let lastCommitTime = new Date();

/**
 * Aktiviert die Erweiterung
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
    console.log('MINTYgit-Erweiterung aktiviert');

    // Lade Konfiguration
    const config = vscode.workspace.getConfiguration('mintygit');

    // Erstelle Statusleisten-Element
    statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
    statusBarItem.command = 'mintygit.showHistory';
    context.subscriptions.push(statusBarItem);

    // Registriere Befehle
    context.subscriptions.push(vscode.commands.registerCommand('mintygit.commit', commit));
    context.subscriptions.push(vscode.commands.registerCommand('mintygit.push', push));
    context.subscriptions.push(vscode.commands.registerCommand('mintygit.pull', pull));
    context.subscriptions.push(vscode.commands.registerCommand('mintygit.autoCommit', autoCommit));
    context.subscriptions.push(vscode.commands.registerCommand('mintygit.enableAutoCommit', enableAutoCommit));
    context.subscriptions.push(vscode.commands.registerCommand('mintygit.disableAutoCommit', disableAutoCommit));
    context.subscriptions.push(vscode.commands.registerCommand('mintygit.showHistory', showHistory));
    context.subscriptions.push(vscode.commands.registerCommand('mintygit.createBranch', createBranch));
    context.subscriptions.push(vscode.commands.registerCommand('mintygit.switchBranch', switchBranch));
    context.subscriptions.push(vscode.commands.registerCommand('mintygit.mergeBranch', mergeBranch));

    // Initialisiere Statusleiste
    updateStatusBar();

    // Starte Auto-Commit-Timer, falls aktiviert
    if (config.autoCommit) {
        startAutoCommitTimer();
    }

    // Registriere Datei-Watcher, falls commitOnSave aktiviert ist
    if (config.commitOnSave) {
        registerFileWatcher();
    }

    // Registriere Konfigurationsänderungen
    context.subscriptions.push(vscode.workspace.onDidChangeConfiguration(e => {
        if (e.affectsConfiguration('mintygit')) {
            const newConfig = vscode.workspace.getConfiguration('mintygit');

            // Aktualisiere Auto-Commit-Timer
            if (e.affectsConfiguration('mintygit.autoCommit') || e.affectsConfiguration('mintygit.autoCommitInterval')) {
                if (autoCommitTimer) {
                    clearInterval(autoCommitTimer);
                    autoCommitTimer = null;
                }

                if (newConfig.autoCommit) {
                    startAutoCommitTimer();
                }
            }

            // Aktualisiere Datei-Watcher
            if (e.affectsConfiguration('mintygit.commitOnSave')) {
                if (fileWatcher) {
                    fileWatcher.dispose();
                    fileWatcher = null;
                }

                if (newConfig.commitOnSave) {
                    registerFileWatcher();
                }
            }
        }
    }));
}

/**
 * Deaktiviert die Erweiterung
 */
function deactivate() {
    console.log('MINTYgit-Erweiterung deaktiviert');

    // Stoppe Auto-Commit-Timer
    if (autoCommitTimer) {
        clearInterval(autoCommitTimer);
        autoCommitTimer = null;
    }

    // Stoppe Datei-Watcher
    if (fileWatcher) {
        fileWatcher.dispose();
        fileWatcher = null;
    }

    // Entferne Statusleisten-Element
    if (statusBarItem) {
        statusBarItem.dispose();
    }
}

/**
 * Führt einen PowerShell-Befehl aus
 * @param {string} command
 * @returns {Promise<string>}
 */
function executePowerShell(command) {
    return new Promise((resolve, reject) => {
        const workspacePath = vscode.workspace.workspaceFolders[0].uri.fsPath;
        const mintyGitPath = path.join(workspacePath, 'modules', 'M99_hive', 'MINTYgit', 'src', 'MINTYgit.ps1');

        const fullCommand = `powershell.exe -ExecutionPolicy Bypass -Command "& { . '${mintyGitPath}'; ${command} }"`;

        exec(fullCommand, { cwd: workspacePath }, (error, stdout, stderr) => {
            if (error) {
                reject(error);
                return;
            }

            if (stderr) {
                reject(new Error(stderr));
                return;
            }

            resolve(stdout);
        });
    });
}

/**
 * Aktualisiert die Statusleiste
 */
async function updateStatusBar() {
    try {
        const config = vscode.workspace.getConfiguration('mintygit');

        if (!config.statusBarIntegration) {
            statusBarItem.hide();
            return;
        }

        const workspacePath = vscode.workspace.workspaceFolders[0].uri.fsPath;

        // Führe PowerShell-Befehl aus, um den aktuellen Branch zu ermitteln
        const branch = await executePowerShell(`git rev-parse --abbrev-ref HEAD`);

        // Führe PowerShell-Befehl aus, um den Status zu ermitteln
        const status = await executePowerShell(`git status --porcelain`);
        const changedFiles = status.split('\n').filter(line => line.trim() !== '').length;

        // Aktualisiere Statusleiste
        statusBarItem.text = `$(git-branch) ${branch.trim()} (${changedFiles})`;
        statusBarItem.tooltip = `MINTYgit: ${branch.trim()} (${changedFiles} geänderte Dateien)`;
        statusBarItem.show();
    } catch (error) {
        console.error('Fehler beim Aktualisieren der Statusleiste:', error);
        statusBarItem.text = '$(git-branch) MINTYgit';
        statusBarItem.tooltip = 'MINTYgit';
        statusBarItem.show();
    }
}

/**
 * Startet den Auto-Commit-Timer
 */
function startAutoCommitTimer() {
    const config = vscode.workspace.getConfiguration('mintygit');

    // Parse Intervall
    const intervalString = config.autoCommitInterval;
    const intervalValue = parseInt(intervalString.replace(/[^0-9]/g, ''));
    const intervalUnit = intervalString.replace(/[0-9]/g, '');

    // Konvertiere in Millisekunden
    let intervalMs;
    switch (intervalUnit) {
        case 's':
            intervalMs = intervalValue * 1000;
            break;
        case 'm':
            intervalMs = intervalValue * 60 * 1000;
            break;
        case 'h':
            intervalMs = intervalValue * 60 * 60 * 1000;
            break;
        default:
            intervalMs = 15 * 60 * 1000; // 15 Minuten als Standard
    }

    // Starte Timer
    autoCommitTimer = setInterval(() => {
        autoCommit();
    }, intervalMs);

    console.log(`Auto-Commit-Timer gestartet mit Intervall: ${intervalString}`);
}

/**
 * Registriert den Datei-Watcher
 */
function registerFileWatcher() {
    const config = vscode.workspace.getConfiguration('mintygit');

    if (!config.commitOnSave) {
        return;
    }

    // Registriere Datei-Watcher
    fileWatcher = vscode.workspace.onDidSaveTextDocument(document => {
        // Ignoriere Dateien außerhalb des Workspace
        if (!vscode.workspace.getWorkspaceFolder(document.uri)) {
            return;
        }

        // Registriere Änderung
        registerFileChange(document.uri.fsPath, 'Modified');

        // Parse Verzögerung
        const delayString = config.autoCommitDelay;
        const delayValue = parseInt(delayString.replace(/[^0-9]/g, ''));
        const delayUnit = delayString.replace(/[0-9]/g, '');

        // Konvertiere in Millisekunden
        let delayMs;
        switch (delayUnit) {
            case 's':
                delayMs = delayValue * 1000;
                break;
            case 'm':
                delayMs = delayValue * 60 * 1000;
                break;
            default:
                delayMs = 30 * 1000; // 30 Sekunden als Standard
        }

        // Starte verzögerten Commit
        setTimeout(() => {
            if (pendingChanges.length >= config.minChangesForCommit) {
                autoCommit();
            }
        }, delayMs);
    });

    console.log('Datei-Watcher registriert');
}

/**
 * Registriert eine Dateiänderung
 * @param {string} filePath
 * @param {string} changeType
 */
function registerFileChange(filePath, changeType) {
    pendingChanges.push({
        file: filePath,
        type: changeType,
        timestamp: new Date()
    });

    console.log(`Dateiänderung registriert: ${changeType} - ${filePath}`);
}

/**
 * Erstellt einen Commit
 */
async function commit() {
    try {
        const config = vscode.workspace.getConfiguration('mintygit');

        // Zeige Input-Box für Commit-Typ
        const commitType = await vscode.window.showQuickPick(config.get('commitTypes', ['feat', 'fix', 'docs', 'style', 'refactor', 'test', 'chore']), {
            placeHolder: 'Wähle den Typ des Commits'
        });

        if (!commitType) {
            return;
        }

        // Hole Vorschlag für Commit-Nachricht
        let commitMessageSuggestion = '';
        if (config.suggestCommitMessages) {
            try {
                commitMessageSuggestion = await executePowerShell('Get-CommitMessageSuggestion -Path $PWD');
                commitMessageSuggestion = commitMessageSuggestion.replace(/^\[.*?\]\s*/, ''); // Entferne Typ-Präfix
            } catch (error) {
                console.error('Fehler beim Generieren der Commit-Nachricht:', error);
            }
        }

        // Zeige Input-Box für Commit-Nachricht
        const commitMessage = await vscode.window.showInputBox({
            placeHolder: 'Gib eine Commit-Nachricht ein',
            value: commitMessageSuggestion,
            prompt: 'Die Commit-Nachricht wird mit dem Typ kombiniert: [' + commitType + '] Deine Nachricht'
        });

        if (!commitMessage) {
            return;
        }

        // Führe PowerShell-Befehl aus
        const workspacePath = vscode.workspace.workspaceFolders[0].uri.fsPath;
        await executePowerShell(`New-GitCommit -Path '${workspacePath}' -Message '${commitMessage}' -Type '${commitType}'`);

        // Zeige Benachrichtigung
        if (config.showNotifications) {
            vscode.window.showInformationMessage(`Commit erstellt: [${commitType}] ${commitMessage}`);
        }

        // Aktualisiere Statusleiste
        updateStatusBar();

        // Aktualisiere Zeitstempel
        lastCommitTime = new Date();

        // Leere Liste der ausstehenden Änderungen
        pendingChanges = [];
    } catch (error) {
        vscode.window.showErrorMessage(`Fehler beim Erstellen des Commits: ${error.message}`);
    }
}

/**
 * Führt einen Push durch
 */
async function push() {
    try {
        const config = vscode.workspace.getConfiguration('mintygit');

        // Führe PowerShell-Befehl aus
        const workspacePath = vscode.workspace.workspaceFolders[0].uri.fsPath;
        await executePowerShell(`Invoke-GitPush -Path '${workspacePath}'`);

        // Zeige Benachrichtigung
        if (config.showNotifications) {
            vscode.window.showInformationMessage('Push erfolgreich');
        }

        // Aktualisiere Statusleiste
        updateStatusBar();
    } catch (error) {
        vscode.window.showErrorMessage(`Fehler beim Push: ${error.message}`);
    }
}

/**
 * Führt einen Pull durch
 */
async function pull() {
    try {
        const config = vscode.workspace.getConfiguration('mintygit');

        // Führe PowerShell-Befehl aus
        const workspacePath = vscode.workspace.workspaceFolders[0].uri.fsPath;
        await executePowerShell(`Invoke-GitPull -Path '${workspacePath}'`);

        // Zeige Benachrichtigung
        if (config.showNotifications) {
            vscode.window.showInformationMessage('Pull erfolgreich');
        }

        // Aktualisiere Statusleiste
        updateStatusBar();
    } catch (error) {
        vscode.window.showErrorMessage(`Fehler beim Pull: ${error.message}`);
    }
}

/**
 * Führt einen automatischen Commit durch
 */
async function autoCommit() {
    try {
        const config = vscode.workspace.getConfiguration('mintygit');

        if (!config.autoCommit) {
            return;
        }

        // Führe PowerShell-Befehl aus
        const workspacePath = vscode.workspace.workspaceFolders[0].uri.fsPath;
        await executePowerShell(`Invoke-AutoCommit -Path '${workspacePath}'`);

        // Zeige Benachrichtigung
        if (config.showNotifications) {
            vscode.window.showInformationMessage('Automatischer Commit erstellt');
        }

        // Aktualisiere Statusleiste
        updateStatusBar();

        // Aktualisiere Zeitstempel
        lastCommitTime = new Date();

        // Leere Liste der ausstehenden Änderungen
        pendingChanges = [];
    } catch (error) {
        console.error('Fehler beim automatischen Commit:', error);
        // Keine Benachrichtigung bei Fehlern im automatischen Commit
    }
}

/**
 * Aktiviert automatische Commits
 */
async function enableAutoCommit() {
    try {
        // Aktualisiere Konfiguration
        await vscode.workspace.getConfiguration().update('mintygit.autoCommit', true, vscode.ConfigurationTarget.Workspace);

        // Starte Auto-Commit-Timer
        startAutoCommitTimer();

        // Zeige Benachrichtigung
        vscode.window.showInformationMessage('Automatische Commits aktiviert');
    } catch (error) {
        vscode.window.showErrorMessage(`Fehler beim Aktivieren automatischer Commits: ${error.message}`);
    }
}

/**
 * Deaktiviert automatische Commits
 */
async function disableAutoCommit() {
    try {
        // Aktualisiere Konfiguration
        await vscode.workspace.getConfiguration().update('mintygit.autoCommit', false, vscode.ConfigurationTarget.Workspace);

        // Stoppe Auto-Commit-Timer
        if (autoCommitTimer) {
            clearInterval(autoCommitTimer);
            autoCommitTimer = null;
        }

        // Zeige Benachrichtigung
        vscode.window.showInformationMessage('Automatische Commits deaktiviert');
    } catch (error) {
        vscode.window.showErrorMessage(`Fehler beim Deaktivieren automatischer Commits: ${error.message}`);
    }
}

/**
 * Zeigt die Entwicklungshistorie an
 */
async function showHistory() {
    try {
        // Führe PowerShell-Befehl aus
        const workspacePath = vscode.workspace.workspaceFolders[0].uri.fsPath;
        const history = await executePowerShell(`Get-History -Depth 10 -IncludeCommitMessages $true -IncludeFileChanges $true -IncludeAuthors $true`);

        // Erstelle temporäre Datei
        const tempFile = path.join(workspacePath, '.mintygit-history.md');
        const fs = require('fs');
        fs.writeFileSync(tempFile, `# Git-Historie\n\n${history}`);

        // Öffne Datei
        const document = await vscode.workspace.openTextDocument(tempFile);
        await vscode.window.showTextDocument(document);
    } catch (error) {
        vscode.window.showErrorMessage(`Fehler beim Anzeigen der Historie: ${error.message}`);
    }
}

/**
 * Erstellt einen neuen Branch
 */
async function createBranch() {
    try {
        // Zeige Input-Box für Branch-Namen
        const branchName = await vscode.window.showInputBox({
            placeHolder: 'Gib den Namen des neuen Branches ein',
            prompt: 'Der Name wird automatisch an die Namenskonvention angepasst'
        });

        if (!branchName) {
            return;
        }

        // Zeige Input-Box für Beschreibung
        const description = await vscode.window.showInputBox({
            placeHolder: 'Gib eine Beschreibung für den Branch ein (optional)',
            prompt: 'Die Beschreibung wird im ersten Commit verwendet'
        });

        // Zeige Input-Box für Issue-Referenz
        const issueReference = await vscode.window.showInputBox({
            placeHolder: 'Gib eine Issue-Referenz ein (optional)',
            prompt: 'Die Issue-Referenz wird im ersten Commit verwendet'
        });

        // Führe PowerShell-Befehl aus
        await executePowerShell(`New-Branch -Name '${branchName}' -Description '${description || ""}' -IssueReference '${issueReference || ""}'`);

        // Zeige Benachrichtigung
        vscode.window.showInformationMessage(`Branch erstellt: ${branchName}`);

        // Aktualisiere Statusleiste
        updateStatusBar();
    } catch (error) {
        vscode.window.showErrorMessage(`Fehler beim Erstellen des Branches: ${error.message}`);
    }
}

/**
 * Wechselt zu einem Branch
 */
async function switchBranch() {
    try {
        // Hole Liste der Branches
        const branches = await executePowerShell(`git branch --format="%(refname:short)"`);
        const branchList = branches.split('\n').filter(branch => branch.trim() !== '');

        // Zeige QuickPick für Branch-Auswahl
        const selectedBranch = await vscode.window.showQuickPick(branchList, {
            placeHolder: 'Wähle den Branch, zu dem gewechselt werden soll'
        });

        if (!selectedBranch) {
            return;
        }

        // Führe PowerShell-Befehl aus
        await executePowerShell(`Switch-Branch -Name '${selectedBranch}'`);

        // Zeige Benachrichtigung
        vscode.window.showInformationMessage(`Zu Branch gewechselt: ${selectedBranch}`);

        // Aktualisiere Statusleiste
        updateStatusBar();
    } catch (error) {
        vscode.window.showErrorMessage(`Fehler beim Wechseln des Branches: ${error.message}`);
    }
}

/**
 * Führt Branches zusammen
 */
async function mergeBranch() {
    try {
        // Hole Liste der Branches
        const branches = await executePowerShell(`git branch --format="%(refname:short)"`);
        const branchList = branches.split('\n').filter(branch => branch.trim() !== '');

        // Hole aktuellen Branch
        const currentBranch = (await executePowerShell(`git rev-parse --abbrev-ref HEAD`)).trim();

        // Filtere aktuellen Branch aus der Liste
        const otherBranches = branchList.filter(branch => branch !== currentBranch);

        // Zeige QuickPick für Quell-Branch
        const sourceBranch = await vscode.window.showQuickPick(otherBranches, {
            placeHolder: 'Wähle den Quell-Branch'
        });

        if (!sourceBranch) {
            return;
        }

        // Zeige QuickPick für Ziel-Branch
        const targetBranch = await vscode.window.showQuickPick(branchList, {
            placeHolder: 'Wähle den Ziel-Branch',
            value: currentBranch
        });

        if (!targetBranch) {
            return;
        }

        // Zeige Input-Box für Merge-Nachricht
        const mergeMessage = await vscode.window.showInputBox({
            placeHolder: 'Gib eine Merge-Nachricht ein',
            value: `Merge ${sourceBranch} into ${targetBranch}`
        });

        if (!mergeMessage) {
            return;
        }

        // Führe PowerShell-Befehl aus
        await executePowerShell(`Merge-Branch -Source '${sourceBranch}' -Target '${targetBranch}' -Message '${mergeMessage}'`);

        // Zeige Benachrichtigung
        vscode.window.showInformationMessage(`Branches zusammengeführt: ${sourceBranch} -> ${targetBranch}`);

        // Aktualisiere Statusleiste
        updateStatusBar();
    } catch (error) {
        vscode.window.showErrorMessage(`Fehler beim Zusammenführen der Branches: ${error.message}`);
    }
}

module.exports = {
    activate,
    deactivate
};
