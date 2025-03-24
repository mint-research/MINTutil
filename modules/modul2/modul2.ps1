# modul2-Modul für MINTutil
# "Under Construction"-Modul als Platzhalter für zukünftige Funktionalität

# Globale Variablen
$script:Modul2BasePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:StatusPath = Join-Path -Path $PSScriptRoot -ChildPath "../../data/modul2/status.json"
$script:NotificationsPath = Join-Path -Path $PSScriptRoot -ChildPath "../../data/modul2/notifications.json"
$script:Modul2UI = $null

# ============= Initialisierungsfunktionen =============

function Initialize-modul2 {
    param(
        [Parameter(Mandatory=$true)]$Window
    )
    try {
        $script:Modul2UI = $Window
        
        # Sicherstellen, dass Verzeichnisse existieren
        $statusDir = Split-Path -Parent $script:StatusPath
        if (-not (Test-Path -Path $statusDir)) {
            New-Item -Path $statusDir -ItemType Directory -Force | Out-Null
        }
        
        # Statusdatei erstellen, falls nicht vorhanden
        if (-not (Test-Path -Path $script:StatusPath)) {
            $status = @{
                State = "UnderConstruction"
                ExpectedCompletionDate = "2025-06-30"
                FeatureProgress = @{
                    Configuration = 10
                    DataVisualization = 5
                    ExternalServices = 0
                    Reports = 15
                }
                LastUpdated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            }
            $status | ConvertTo-Json | Set-Content -Path $script:StatusPath -Force
        }
        
        # Initialisiere Benachrichtigungen
        if (-not (Test-Path -Path $script:NotificationsPath)) {
            $notifications = @()
            $notifications | ConvertTo-Json | Set-Content -Path $script:NotificationsPath -Force
        }
        
        # Event-Handler für Buttons einrichten
        Register-EventHandlers
        
        Write-Host "modul2-Modul initialisiert (Under Construction)"
        return $true
    } catch {
        Write-Error "Fehler bei der Initialisierung des modul2-Moduls: $_"
        return $false
    }
}

function Register-EventHandlers {
    try {
        # Benachrichtigungsbutton
        $btnNotify = $script:Modul2UI.FindName("BtnNotify")
        
        if ($null -ne $btnNotify) {
            $btnNotify.Add_Click({ Register-Notification })
        }
        
        Write-Host "Event-Handler für modul2-Modul registriert"
    } catch {
        Write-Error "Fehler beim Registrieren der Event-Handler: $_"
        throw $_
    }
}

# ============= Funktionalität =============

function Register-Notification {
    try {
        # InputBox für E-Mail anzeigen
        $title = "Benachrichtigung registrieren"
        $message = "Bitte geben Sie Ihre E-Mail-Adresse ein, um bei Fertigstellung des Moduls benachrichtigt zu werden:"
        
        $emailInput = Show-InputDialog -Title $title -Message $message -DefaultValue ""
        
        if ($null -eq $emailInput -or $emailInput -eq "") {
            return
        }
        
        # Validierung
        if (-not ($emailInput -match "^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")) {
            [System.Windows.MessageBox]::Show(
                "Bitte geben Sie eine gültige E-Mail-Adresse ein.", 
                "Ungültige E-Mail", 
                [System.Windows.MessageBoxButton]::OK, 
                [System.Windows.MessageBoxImage]::Error)
            return
        }
        
        # Zu Benachrichtigungsliste hinzufügen
        $notifications = @()
        if (Test-Path -Path $script:NotificationsPath) {
            $notifications = Get-Content -Path $script:NotificationsPath -Raw | ConvertFrom-Json
        }
        
        # Prüfen, ob E-Mail bereits registriert ist
        $exists = $false
        foreach ($notification in $notifications) {
            if ($notification.Email -eq $emailInput) {
                $exists = $true
                break
            }
        }
        
        if (-not $exists) {
            $newNotification = @{
                Email = $emailInput
                RegisteredDate = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            }
            
            $notifications += $newNotification
            $notifications | ConvertTo-Json | Set-Content -Path $script:NotificationsPath -Force
            
            [System.Windows.MessageBox]::Show(
                "Ihre E-Mail-Adresse wurde erfolgreich registriert. Sie erhalten eine Benachrichtigung, sobald das Modul verfügbar ist.", 
                "Registrierung erfolgreich", 
                [System.Windows.MessageBoxButton]::OK, 
                [System.Windows.MessageBoxImage]::Information)
        } else {
            [System.Windows.MessageBox]::Show(
                "Diese E-Mail-Adresse ist bereits registriert.", 
                "Bereits registriert", 
                [System.Windows.MessageBoxButton]::OK, 
                [System.Windows.MessageBoxImage]::Information)
        }
    } catch {
        Write-Error "Fehler bei der Registrierung der Benachrichtigung: $_"
        [System.Windows.MessageBox]::Show(
            "Bei der Registrierung ist ein Fehler aufgetreten: $_", 
            "Fehler", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Error)
    }
}

function Show-InputDialog {
    param(
        [string]$Title = "Eingabe",
        [string]$Message = "Bitte geben Sie einen Wert ein:",
        [string]$DefaultValue = ""
    )
    
    # Dialogfenster erstellen
    $inputDialog = New-Object System.Windows.Window
    $inputDialog.Title = $Title
    $inputDialog.Width = 400
    $inputDialog.Height = 180
    $inputDialog.WindowStartupLocation = "CenterScreen"
    $inputDialog.ResizeMode = "NoResize"
    
    # Layout erstellen
    $mainPanel = New-Object System.Windows.Controls.StackPanel
    $mainPanel.Margin = "10"
    
    # Nachrichtentext
    $messageText = New-Object System.Windows.Controls.TextBlock
    $messageText.Text = $Message
    $messageText.TextWrapping = "Wrap"
    $messageText.Margin = "0,0,0,10"
    $mainPanel.Children.Add($messageText)
    
    # Eingabefeld
    $inputBox = New-Object System.Windows.Controls.TextBox
    $inputBox.Text = $DefaultValue
    $inputBox.Margin = "0,0,0,20"
    $inputBox.Height = 24
    $mainPanel.Children.Add($inputBox)
    
    # Button-Panel
    $buttonPanel = New-Object System.Windows.Controls.StackPanel
    $buttonPanel.Orientation = "Horizontal"
    $buttonPanel.HorizontalAlignment = "Right"
    
    # OK-Button
    $okButton = New-Object System.Windows.Controls.Button
    $okButton.Content = "OK"
    $okButton.Width = 80
    $okButton.Margin = "0,0,10,0"
    $okButton.IsDefault = $true
    $okButton.Add_Click({
        $inputDialog.DialogResult = $true
        $inputDialog.Close()
    })
    $buttonPanel.Children.Add($okButton)
    
    # Abbrechen-Button
    $cancelButton = New-Object System.Windows.Controls.Button
    $cancelButton.Content = "Abbrechen"
    $cancelButton.Width = 80
    $cancelButton.IsCancel = $true
    $cancelButton.Add_Click({
        $inputDialog.DialogResult = $false
        $inputDialog.Close()
    })
    $buttonPanel.Children.Add($cancelButton)
    
    $mainPanel.Children.Add($buttonPanel)
    $inputDialog.Content = $mainPanel
    
    # Dialog anzeigen und Ergebnis zurückgeben
    $result = $inputDialog.ShowDialog()
    
    if ($result.HasValue -and $result.Value) {
        return $inputBox.Text
    } else {
        return $null
    }
}

# Exportiere die Initialisierungsfunktion für main.ps1
Export-ModuleMember -Function Initialize-modul2