# Installer-Modul für MINTutil
# Behandelt Software-Installation, Deinstallation und Updates über Winget

# Globale Variablen
$script:InstallerBasePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:AppsDataPath = Join-Path -Path $PSScriptRoot -ChildPath "../../data/Installer/apps.json"
$script:OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "../../config/Installer/output.json"
$script:AppRegistry = "HKCU:\Software\MINTutil\Apps"
$script:SelectedApps = @()
$script:InstallerUI = $null

# ============= Initialisierungsfunktionen =============

function Initialize-Installer {
    param(
        [Parameter(Mandatory=$true)]$Window
    )
    try {
        $script:InstallerUI = $Window
        
        # Sicherstellen, dass Registry-Schlüssel für App-Einstellungen existiert
        if (-not (Test-Path -Path $script:AppRegistry)) {
            New-Item -Path $script:AppRegistry -Force | Out-Null
        }
        
        # Apps-Daten laden
        $apps = Load-AppsData
        
        # App-Liste erstellen
        Create-AppList -Apps $apps
        
        # Event-Handler für Buttons einrichten
        Register-EventHandlers
        
        Write-Host "Installer-Modul initialisiert"
        return $true
    } catch {
        Write-Error "Fehler bei der Initialisierung des Installer-Moduls: $_"
        return $false
    }
}

function Load-AppsData {
    try {
        if (-not (Test-Path -Path $script:AppsDataPath)) {
            throw "Apps-Datendatei nicht gefunden: $script:AppsDataPath"
        }
        
        $appsData = Get-Content -Path $script:AppsDataPath -Raw | ConvertFrom-Json
        Write-Host "Apps-Daten geladen: $($appsData.Count) Apps gefunden"
        return $appsData
    } catch {
        Write-Error "Fehler beim Laden der Apps-Daten: $_"
        throw $_
    }
}

function Register-EventHandlers {
    try {
        # Button-Event-Handler registrieren
        $btnShowSelected = $script:InstallerUI.FindName("BtnShowSelected")
        $btnClear = $script:InstallerUI.FindName("BtnClear")
        $btnInstallSelected = $script:InstallerUI.FindName("BtnInstallSelected")
        $btnUpgradeAll = $script:InstallerUI.FindName("BtnUpgradeAll")
        $btnUninstallSelected = $script:InstallerUI.FindName("BtnUninstallSelected")
        
        $btnShowSelected.Add_Click({ Show-SelectedApps })
        $btnClear.Add_Click({ Clear-AppSelection })
        $btnInstallSelected.Add_Click({ Install-SelectedApps })
        $btnUpgradeAll.Add_Click({ Upgrade-AllApps })
        $btnUninstallSelected.Add_Click({ Uninstall-SelectedApps })
        
        Write-Host "Event-Handler für Installer-Modul registriert"
    } catch {
        Write-Error "Fehler beim Registrieren der Event-Handler: $_"
        throw $_
    }
}

# ============= UI-Funktionen =============

function Create-AppList {
    param(
        [Parameter(Mandatory=$true)]$Apps
    )
    try {
        $appList = $script:InstallerUI.FindName("AppList")
        $appList.Children.Clear()
        
        foreach ($app in $Apps) {
            # App-Zeile erstellen
            $appPanel = New-Object System.Windows.Controls.StackPanel
            $appPanel.Orientation = "Vertical"
            $appPanel.Margin = "0,0,0,5"
            
            # Obere Zeile mit Checkbox, Name und Icons
            $topRowPanel = New-Object System.Windows.Controls.Grid
            
            # Grid-Definitionen
            $col1 = New-Object System.Windows.Controls.ColumnDefinition
            $col1.Width = New-Object System.Windows.GridLength 30
            $col2 = New-Object System.Windows.Controls.ColumnDefinition
            $col2.Width = New-Object System.Windows.GridLength 1, "Star"
            $col3 = New-Object System.Windows.Controls.ColumnDefinition
            $col3.Width = New-Object System.Windows.GridLength 90
            
            $topRowPanel.ColumnDefinitions.Add($col1)
            $topRowPanel.ColumnDefinitions.Add($col2)
            $topRowPanel.ColumnDefinitions.Add($col3)
            
            # Checkbox
            $checkbox = New-Object System.Windows.Controls.CheckBox
            $checkbox.VerticalAlignment = "Center"
            $checkbox.Margin = "5,0,0,0"
            $checkbox.Tag = $app.Id  # ID als Tag speichern
            $checkbox.Add_Checked({ Update-AppSelection -Add $true -AppId $_.Source.Tag })
            $checkbox.Add_Unchecked({ Update-AppSelection -Add $false -AppId $_.Source.Tag })
            [System.Windows.Controls.Grid]::SetColumn($checkbox, 0)
            $topRowPanel.Children.Add($checkbox)
            
            # App-Name
            $appName = New-Object System.Windows.Controls.TextBlock
            $appName.Text = $app.Name
            $appName.VerticalAlignment = "Center"
            $appName.FontWeight = "SemiBold"
            $appName.Margin = "5,0,0,0"
            [System.Windows.Controls.Grid]::SetColumn($appName, 1)
            $topRowPanel.Children.Add($appName)
            
            # Icons-Panel rechts
            $iconsPanel = New-Object System.Windows.Controls.StackPanel
            $iconsPanel.Orientation = "Horizontal"
            $iconsPanel.HorizontalAlignment = "Right"
            [System.Windows.Controls.Grid]::SetColumn($iconsPanel, 2)
            
            # Uninstall-Icon
            $uninstallIcon = New-Object System.Windows.Controls.Button
            $uninstallIcon.Content = "🗑️"
            $uninstallIcon.ToolTip = "Deinstallieren"
            $uninstallIcon.Tag = $app.Id
            $uninstallIcon.Width = 25
            $uninstallIcon.Height = 25
            $uninstallIcon.Margin = "2,0,2,0"
            $uninstallIcon.Add_Click({ 
                $appId = $_.Source.Tag
                Uninstall-App -AppId $appId 
            })
            $iconsPanel.Children.Add($uninstallIcon)
            
            # Configure-Icon
            $configIcon = New-Object System.Windows.Controls.Button
            $configIcon.Content = "⚙️"
            $configIcon.ToolTip = "Konfigurieren"
            $configIcon.Tag = $app.Id
            $configIcon.Width = 25
            $configIcon.Height = 25
            $configIcon.Margin = "2,0,2,0"
            $configIcon.Add_Click({ 
                $appId = $_.Source.Tag
                Show-AppConfig -AppId $appId 
            })
            $iconsPanel.Children.Add($configIcon)
            
            # Info-Icon
            $infoIcon = New-Object System.Windows.Controls.Button
            $infoIcon.Content = "ℹ️"
            $infoIcon.ToolTip = "Info"
            $infoIcon.Tag = $app.Id
            $infoIcon.Width = 25
            $infoIcon.Height = 25
            $infoIcon.Margin = "2,0,2,0"
            $infoIcon.Add_Click({ 
                $appId = $_.Source.Tag
                Show-AppInfo -AppId $appId 
            })
            $iconsPanel.Children.Add($infoIcon)
            
            $topRowPanel.Children.Add($iconsPanel)
            $appPanel.Children.Add($topRowPanel)
            
            # Trennlinie unter jeder App
            $separator = New-Object System.Windows.Controls.Separator
            $separator.Margin = "0,5,0,0"
            $appPanel.Children.Add($separator)
            
            $appList.Children.Add($appPanel)
        }
        
        Write-Host "App-Liste erstellt mit $($Apps.Count) Apps"
    } catch {
        Write-Error "Fehler beim Erstellen der App-Liste: $_"
        throw $_
    }
}

function Update-AppSelection {
    param(
        [bool]$Add,
        [string]$AppId
    )
    
    if ($Add) {
        if (-not $script:SelectedApps.Contains($AppId)) {
            $script:SelectedApps += $AppId
        }
    } else {
        $script:SelectedApps = $script:SelectedApps | Where-Object { $_ -ne $AppId }
    }
    
    # Auswahlzähler aktualisieren
    $selectedCount = $script:InstallerUI.FindName("SelectedCount")
    $selectedCount.Text = "Ausgewählt: $($script:SelectedApps.Count)"
    
    Write-Host "App-Auswahl aktualisiert: $($script:SelectedApps.Count) Apps ausgewählt"
}

function Show-SelectedApps {
    if ($script:SelectedApps.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Keine Apps ausgewählt.", "Information",
                                        [System.Windows.MessageBoxButton]::OK,
                                        [System.Windows.MessageBoxImage]::Information)
        return
    }
    
    $appsData = Load-AppsData
    $selectedAppsNames = $appsData | 
                        Where-Object { $script:SelectedApps -contains $_.Id } | 
                        ForEach-Object { $_.Name }
    
    $message = "Ausgewählte Apps:`n`n" + ($selectedAppsNames -join "`n")
    
    [System.Windows.MessageBox]::Show($message, "Ausgewählte Apps",
                                    [System.Windows.MessageBoxButton]::OK,
                                    [System.Windows.MessageBoxImage]::Information)
}

function Clear-AppSelection {
    $script:SelectedApps = @()
    
    # Alle Checkboxen zurücksetzen
    $appList = $script:InstallerUI.FindName("AppList")
    foreach ($appPanel in $appList.Children) {
        $topRowPanel = $appPanel.Children[0]
        foreach ($control in $topRowPanel.Children) {
            if ($control -is [System.Windows.Controls.CheckBox]) {
                $control.IsChecked = $false
            }
        }
    }
    
    # Auswahlzähler aktualisieren
    $selectedCount = $script:InstallerUI.FindName("SelectedCount")
    $selectedCount.Text = "Ausgewählt: 0"
    
    Write-Host "App-Auswahl zurückgesetzt"
}

function Show-AppConfig {
    param(
        [Parameter(Mandatory=$true)][string]$AppId
    )
    
    try {
        # App-Daten laden
        $appsData = Load-AppsData
        $app = $appsData | Where-Object { $_.Id -eq $AppId }
        
        if ($null -eq $app) {
            throw "App mit ID '$AppId' nicht gefunden"
        }
        
        # Wenn keine Felder definiert sind, Meldung anzeigen
        if ($null -eq $app.Fields -or $app.Fields.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Keine konfigurierbaren Felder für $($app.Name) verfügbar.", 
                                           "Konfiguration", 
                                           [System.Windows.MessageBoxButton]::OK, 
                                           [System.Windows.MessageBoxImage]::Information)
            return
        }
        
        # Konfigurationsfenster erstellen
        $configWindow = New-Object System.Windows.Window
        $configWindow.Title = "Konfiguration: $($app.Name)"
        $configWindow.Width = 450
        $configWindow.Height = 300
        $configWindow.WindowStartupLocation = "CenterScreen"
        $configWindow.ResizeMode = "NoResize"
        
        $mainPanel = New-Object System.Windows.Controls.StackPanel
        $mainPanel.Margin = "10"
        
        # Überschrift
        $titleBlock = New-Object System.Windows.Controls.TextBlock
        $titleBlock.Text = "Konfiguration für $($app.Name)"
        $titleBlock.FontWeight = "Bold"
        $titleBlock.FontSize = 16
        $titleBlock.Margin = "0,0,0,10"
        $mainPanel.Children.Add($titleBlock)
        
        # Beschreibung
        $descBlock = New-Object System.Windows.Controls.TextBlock
        $descBlock.Text = "Passen Sie die Parameter für diese Anwendung an:"
        $descBlock.Margin = "0,0,0,15"
        $descBlock.TextWrapping = "Wrap"
        $mainPanel.Children.Add($descBlock)
        
        # Felder-Grid erstellen
        $fieldsGrid = New-Object System.Windows.Controls.Grid
        $fieldsGrid.Margin = "0,0,0,15"
        
        # Grid-Definitionen
        $col1 = New-Object System.Windows.Controls.ColumnDefinition
        $col1.Width = New-Object System.Windows.GridLength 120
        $col2 = New-Object System.Windows.Controls.ColumnDefinition
        $col2.Width = New-Object System.Windows.GridLength 1, "Star"
        $col3 = New-Object System.Windows.Controls.ColumnDefinition
        $col3.Width = New-Object System.Windows.GridLength 60
        
        $fieldsGrid.ColumnDefinitions.Add($col1)
        $fieldsGrid.ColumnDefinitions.Add($col2)
        $fieldsGrid.ColumnDefinitions.Add($col3)
        
        # Reihen für jedes Feld hinzufügen
        for ($i = 0; $i -lt $app.Fields.Count; $i++) {
            $rowDef = New-Object System.Windows.Controls.RowDefinition
            $rowDef.Height = New-Object System.Windows.GridLength 35
            $fieldsGrid.RowDefinitions.Add($rowDef)
        }
        
        # Felder hinzufügen
        for ($i = 0; $i -lt $app.Fields.Count; $i++) {
            $field = $app.Fields[$i]
            
            # Registry-Wert laden oder Standardwert verwenden
            $regPath = "$script:AppRegistry\$($app.Id)"
            $fieldValue = $null
            
            if (Test-Path -Path $regPath) {
                $fieldValue = Get-ItemProperty -Path $regPath -Name $field.Name -ErrorAction SilentlyContinue
            }
            
            if ($null -eq $fieldValue -or $null -eq $fieldValue.($field.Name)) {
                $fieldValue = $field.Default
            } else {
                $fieldValue = $fieldValue.($field.Name)
            }
            
            # Label
            $label = New-Object System.Windows.Controls.Label
            $label.Content = $field.Label
            $label.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetRow($label, $i)
            [System.Windows.Controls.Grid]::SetColumn($label, 0)
            $fieldsGrid.Children.Add($label)
            
            # Eingabefeld
            $inputControl = $null
            
            if ($field.Type -eq "text") {
                $inputControl = New-Object System.Windows.Controls.TextBox
                $inputControl.Text = $fieldValue
                $inputControl.VerticalContentAlignment = "Center"
            } elseif ($field.Type -eq "checkbox") {
                $inputControl = New-Object System.Windows.Controls.CheckBox
                $inputControl.IsChecked = [System.Convert]::ToBoolean($fieldValue)
                $inputControl.VerticalAlignment = "Center"
            } elseif ($field.Type -eq "dropdown") {
                $inputControl = New-Object System.Windows.Controls.ComboBox
                foreach ($option in $field.Options) {
                    $null = $inputControl.Items.Add($option)
                }
                $inputControl.SelectedItem = $fieldValue
                $inputControl.VerticalContentAlignment = "Center"
            }
            
            if ($null -ne $inputControl) {
                $inputControl.Name = "Field_$($field.Name)"
                $inputControl.Tag = $field
                $inputControl.Margin = "5,2"
                [System.Windows.Controls.Grid]::SetRow($inputControl, $i)
                [System.Windows.Controls.Grid]::SetColumn($inputControl, 1)
                $fieldsGrid.Children.Add($inputControl)
                
                # Reset-Button
                $resetButton = New-Object System.Windows.Controls.Button
                $resetButton.Content = "Reset"
                $resetButton.Tag = $inputControl
                $resetButton.Margin = "5,2"
                $resetButton.Add_Click({
                    $control = $_.Source.Tag
                    $fieldDef = $control.Tag
                    
                    if ($control -is [System.Windows.Controls.TextBox]) {
                        $control.Text = $fieldDef.Default
                    } elseif ($control -is [System.Windows.Controls.CheckBox]) {
                        $control.IsChecked = [System.Convert]::ToBoolean($fieldDef.Default)
                    } elseif ($control -is [System.Windows.Controls.ComboBox]) {
                        $control.SelectedItem = $fieldDef.Default
                    }
                })
                [System.Windows.Controls.Grid]::SetRow($resetButton, $i)
                [System.Windows.Controls.Grid]::SetColumn($resetButton, 2)
                $fieldsGrid.Children.Add($resetButton)
            }
        }
        
        $mainPanel.Children.Add($fieldsGrid)
        
        # Buttons-Panel
        $buttonsPanel = New-Object System.Windows.Controls.StackPanel
        $buttonsPanel.Orientation = "Horizontal"
        $buttonsPanel.HorizontalAlignment = "Right"
        
        $saveButton = New-Object System.Windows.Controls.Button
        $saveButton.Content = "Speichern"
        $saveButton.Padding = "10,5"
        $saveButton.Margin = "0,0,10,0"
        $saveButton.Add_Click({
            # Werte sammeln und speichern
            $fieldsToSave = @{}
            
            foreach ($control in $fieldsGrid.Children) {
                if (($control -is [System.Windows.Controls.TextBox] -or 
                    $control -is [System.Windows.Controls.CheckBox] -or 
                    $control -is [System.Windows.Controls.ComboBox]) -and 
                    $control.Name -like "Field_*") {
                    
                    $fieldName = $control.Name -replace "Field_", ""
                    $fieldValue = $null
                    
                    if ($control -is [System.Windows.Controls.TextBox]) {
                        $fieldValue = $control.Text
                    } elseif ($control -is [System.Windows.Controls.CheckBox]) {
                        $fieldValue = $control.IsChecked
                    } elseif ($control -is [System.Windows.Controls.ComboBox]) {
                        $fieldValue = $control.SelectedItem
                    }
                    
                    $fieldsToSave[$fieldName] = $fieldValue
                }
            }
            
            # In Registry speichern
            $regPath = "$script:AppRegistry\$($app.Id)"
            if (-not (Test-Path -Path $regPath)) {
                New-Item -Path $regPath -Force | Out-Null
            }
            
            foreach ($fieldName in $fieldsToSave.Keys) {
                $fieldValue = $fieldsToSave[$fieldName]
                New-ItemProperty -Path $regPath -Name $fieldName -Value $fieldValue -PropertyType String -Force | Out-Null
            }
            
            [System.Windows.MessageBox]::Show("Konfiguration gespeichert.", "Erfolg", 
                                         [System.Windows.MessageBoxButton]::OK, 
                                         [System.Windows.MessageBoxImage]::Information)
            $configWindow.Close()
        })
        $buttonsPanel.Children.Add($saveButton)
        
        $cancelButton = New-Object System.Windows.Controls.Button
        $cancelButton.Content = "Abbrechen"
        $cancelButton.Padding = "10,5"
        $cancelButton.Add_Click({ $configWindow.Close() })
        $buttonsPanel.Children.Add($cancelButton)
        
        $mainPanel.Children.Add($buttonsPanel)
        
        $configWindow.Content = $mainPanel
        $configWindow.ShowDialog() | Out-Null
        
    } catch {
        Write-Error "Fehler beim Anzeigen der App-Konfiguration: $_"
        [System.Windows.MessageBox]::Show("Fehler beim Anzeigen der Konfiguration: $_", 
                                     "Fehler", 
                                     [System.Windows.MessageBoxButton]::OK, 
                                     [System.Windows.MessageBoxImage]::Error)
    }
}

function Show-AppInfo {
    param(
        [Parameter(Mandatory=$true)][string]$AppId
    )
    
    try {
        # App-Daten laden
        $appsData = Load-AppsData
        $app = $appsData | Where-Object { $_.Id -eq $AppId }
        
        if ($null -eq $app) {
            throw "App mit ID '$AppId' nicht gefunden"
        }
        
        # Info-Text erstellen
        $infoText = "$($app.Name)`n`n"
        $infoText += "ID: $($app.Id)`n`n"
        
        if ($null -ne $app.Info) {
            $infoText += "$($app.Info.Text)`n`n"
            
            if (-not [string]::IsNullOrEmpty($app.Info.Url)) {
                $infoText += "Website: $($app.Info.Url)"
            }
        }
        
        # Info-Fenster erstellen
        $infoWindow = New-Object System.Windows.Window
        $infoWindow.Title = "Information: $($app.Name)"
        $infoWindow.Width = 400
        $infoWindow.Height = 250
        $infoWindow.WindowStartupLocation = "CenterScreen"
        $infoWindow.ResizeMode = "NoResize"
        
        $mainPanel = New-Object System.Windows.Controls.StackPanel
        $mainPanel.Margin = "10"
        
        # Überschrift
        $titleBlock = New-Object System.Windows.Controls.TextBlock
        $titleBlock.Text = "$($app.Name)"
        $titleBlock.FontWeight = "Bold"
        $titleBlock.FontSize = 16
        $titleBlock.Margin = "0,0,0,10"
        $mainPanel.Children.Add($titleBlock)
        
        # Info-Text
        $infoBlock = New-Object System.Windows.Controls.TextBlock
        $infoBlock.Text = $infoText
        $infoBlock.TextWrapping = "Wrap"
        $mainPanel.Children.Add($infoBlock)
        
        # URL als Hyperlink, falls vorhanden
        if ($null -ne $app.Info -and -not [string]::IsNullOrEmpty($app.Info.Url)) {
            $urlPanel = New-Object System.Windows.Controls.StackPanel
            $urlPanel.Orientation = "Horizontal"
            $urlPanel.Margin = "0,15,0,0"
            
            $urlLabel = New-Object System.Windows.Controls.TextBlock
            $urlLabel.Text = "Website: "
            $urlPanel.Children.Add($urlLabel)
            
            $hyperlink = New-Object System.Windows.Documents.Hyperlink
            $run = New-Object System.Windows.Documents.Run
            $run.Text = $app.Info.Url
            $hyperlink.Inlines.Add($run)
            $hyperlink.NavigateUri = New-Object System.Uri($app.Info.Url)
            $hyperlink.RequestNavigate += {
                param($sender, $e)
                Start-Process $e.Uri.AbsoluteUri
                $e.Handled = $true
            }
            
            $hyperlinkContainer = New-Object System.Windows.Controls.TextBlock
            $hyperlinkContainer.Inlines.Add($hyperlink)
            $urlPanel.Children.Add($hyperlinkContainer)
            
            $mainPanel.Children.Add($urlPanel)
        }
        
        # OK-Button
        $okButton = New-Object System.Windows.Controls.Button
        $okButton.Content = "OK"
        $okButton.Padding = "20,5"
        $okButton.Margin = "0,15,0,0"
        $okButton.HorizontalAlignment = "Right"
        $okButton.Add_Click({ $infoWindow.Close() })
        $mainPanel.Children.Add($okButton)
        
        $infoWindow.Content = $mainPanel
        $infoWindow.ShowDialog() | Out-Null
        
    } catch {
        Write-Error "Fehler beim Anzeigen der App-Information: $_"
        [System.Windows.MessageBox]::Show("Fehler beim Anzeigen der Information: $_", 
                                     "Fehler", 
                                     [System.Windows.MessageBoxButton]::OK, 
                                     [System.Windows.MessageBoxImage]::Error)
    }
}

function Update-ProgressBar {
    param(
        [Parameter(Mandatory=$true)][int]$Progress,
        [Parameter(Mandatory=$true)][string]$StatusText
    )
    
    $progressBar = $script:InstallerUI.FindName("Progress")
    $progressText = $script:InstallerUI.FindName("ProgressText")
    
    $progressBar.Value = $Progress
    $progressText.Text = $StatusText
    
    # UI aktualisieren
    [System.Windows.Forms.Application]::DoEvents()
}

# ============= Installationsfunktionen =============

function Install-SelectedApps {
    if ($script:SelectedApps.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Keine Apps ausgewählt.", "Information",
                                        [System.Windows.MessageBoxButton]::OK,
                                        [System.Windows.MessageBoxImage]::Information)
        return
    }
    
    try {
        $appsData = Load-AppsData
        $selectedApps = $appsData | Where-Object { $script:SelectedApps -contains $_.Id }
        
        $progressStep = 100 / $selectedApps.Count
        $currentProgress = 0
        
        foreach ($app in $selectedApps) {
            Update-ProgressBar -Progress $currentProgress -StatusText "Installiere $($app.Name)..."
            
            $result = Install-App -AppId $app.Id
            
            $currentProgress += $progressStep
            Update-ProgressBar -Progress $currentProgress -StatusText "Installation von $($app.Name) abgeschlossen."
        }
        
        Update-ProgressBar -Progress 100 -StatusText "Alle Installationen abgeschlossen."
        [System.Windows.MessageBox]::Show("Installation der ausgewählten Apps abgeschlossen.", "Information",
                                        [System.Windows.MessageBoxButton]::OK,
                                        [System.Windows.MessageBoxImage]::Information)
    } catch {
        Write-Error "Fehler bei der Installation der ausgewählten Apps: $_"
        Update-ProgressBar -Progress 0 -StatusText "Fehler bei der Installation."
        [System.Windows.MessageBox]::Show("Fehler bei der Installation: $_", "Fehler",
                                        [System.Windows.MessageBoxButton]::OK,
                                        [System.Windows.MessageBoxImage]::Error)
    }
}

function Upgrade-AllApps {
    try {
        $appsData = Load-AppsData
        $progressStep = 100 / $appsData.Count
        $currentProgress = 0
        
        foreach ($app in $appsData) {
            Update-ProgressBar -Progress $currentProgress -StatusText "Upgrade für $($app.Name)..."
            
            $result = Upgrade-App -AppId $app.Id
            
            $currentProgress += $progressStep
            Update-ProgressBar -Progress $currentProgress -StatusText "Upgrade von $($app.Name) abgeschlossen."
        }
        
        Update-ProgressBar -Progress 100 -StatusText "Alle Upgrades abgeschlossen."
        [System.Windows.MessageBox]::Show("Upgrade aller Apps abgeschlossen.", "Information",
                                        [System.Windows.MessageBoxButton]::OK,
                                        [System.Windows.MessageBoxImage]::Information)
    } catch {
        Write-Error "Fehler beim Upgrade aller Apps: $_"
        Update-ProgressBar -Progress 0 -StatusText "Fehler beim Upgrade."
        [System.Windows.MessageBox]::Show("Fehler beim Upgrade: $_", "Fehler",
                                        [System.Windows.MessageBoxButton]::OK,
                                        [System.Windows.MessageBoxImage]::Error)
    }
}

function Uninstall-SelectedApps {
    if ($script:SelectedApps.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Keine Apps ausgewählt.", "Information",
                                        [System.Windows.MessageBoxButton]::OK,
                                        [System.Windows.MessageBoxImage]::Information)
        return
    }
    
    try {
        $appsData = Load-AppsData
        $selectedApps = $appsData | Where-Object { $script:SelectedApps -contains $_.Id }
        
        $confirmation = [System.Windows.MessageBox]::Show(
            "Sollen folgende Apps deinstalliert werden?`n`n$($selectedApps.Name -join "`n")", 
            "Bestätigung", 
            [System.Windows.MessageBoxButton]::YesNo, 
            [System.Windows.MessageBoxImage]::Question)
            
        if ($confirmation -ne [System.Windows.MessageBoxResult]::Yes) {
            return
        }
        
        $progressStep = 100 / $selectedApps.Count
        $currentProgress = 0
        
        foreach ($app in $selectedApps) {
            Update-ProgressBar -Progress $currentProgress -StatusText "Deinstalliere $($app.Name)..."
            
            $result = Uninstall-App -AppId $app.Id
            
            $currentProgress += $progressStep
            Update-ProgressBar -Progress $currentProgress -StatusText "Deinstallation von $($app.Name) abgeschlossen."
        }
        
        Update-ProgressBar -Progress 100 -StatusText "Alle Deinstallationen abgeschlossen."
        [System.Windows.MessageBox]::Show("Deinstallation der ausgewählten Apps abgeschlossen.", "Information",
                                        [System.Windows.MessageBoxButton]::OK,
                                        [System.Windows.MessageBoxImage]::Information)
    } catch {
        Write-Error "Fehler bei der Deinstallation der ausgewählten Apps: $_"
        Update-ProgressBar -Progress 0 -StatusText "Fehler bei der Deinstallation."
        [System.Windows.MessageBox]::Show("Fehler bei der Deinstallation: $_", "Fehler",
                                        [System.Windows.MessageBoxButton]::OK,
                                        [System.Windows.MessageBoxImage]::Error)
    }
}

function Install-App {
    param(
        [Parameter(Mandatory=$true)][string]$AppId
    )
    
    try {
        # App-Daten laden
        $appsData = Load-AppsData
        $app = $appsData | Where-Object { $_.Id -eq $AppId }
        
        if ($null -eq $app) {
            throw "App mit ID '$AppId' nicht gefunden"
        }
        
        # Parameter für die Installation zusammenstellen
        $params = @{
            Id = $AppId
            Action = "install"
        }
        
        # App-spezifische Parameter hinzufügen
        $regPath = "$script:AppRegistry\$AppId"
        if (Test-Path -Path $regPath) {
            $appSettings = Get-ItemProperty -Path $regPath
            $appProperties = $appSettings.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" }
            
            foreach ($prop in $appProperties) {
                $params[$prop.Name] = $prop.Value
            }
        }
        
        # Winget-Installation ausführen
        Write-Host "→ Installiere $AppId ..." -ForegroundColor Cyan
        
        $process = Start-Process -FilePath "winget" -ArgumentList "install --id=$AppId --silent --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "Winget-Installation fehlgeschlagen mit Exit-Code $($process.ExitCode)"
        }
        
        # Erfolg melden
        Write-Host "Installation von $($app.Name) erfolgreich abgeschlossen." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Fehler bei der Installation von $AppId : $_"
        return $false
    }
}

function Uninstall-App {
    param(
        [Parameter(Mandatory=$true)][string]$AppId
    )
    
    try {
        # App-Daten laden
        $appsData = Load-AppsData
        $app = $appsData | Where-Object { $_.Id -eq $AppId }
        
        if ($null -eq $app) {
            throw "App mit ID '$AppId' nicht gefunden"
        }
        
        # Bestätigung einholen
        $confirmation = [System.Windows.MessageBox]::Show(
            "Möchten Sie $($app.Name) wirklich deinstallieren?", 
            "Bestätigung", 
            [System.Windows.MessageBoxButton]::YesNo, 
            [System.Windows.MessageBoxImage]::Question)
            
        if ($confirmation -ne [System.Windows.MessageBoxResult]::Yes) {
            return $false
        }
        
        # Winget-Deinstallation ausführen
        Write-Host "→ Entferne $AppId ..." -ForegroundColor Yellow
        
        $process = Start-Process -FilePath "winget" -ArgumentList "uninstall --id=$AppId --silent --accept-source-agreements" -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "Winget-Deinstallation fehlgeschlagen mit Exit-Code $($process.ExitCode)"
        }
        
        # Erfolg melden
        Write-Host "Deinstallation von $($app.Name) erfolgreich abgeschlossen." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Fehler bei der Deinstallation von $AppId : $_"
        return $false
    }
}

function Upgrade-App {
    param(
        [Parameter(Mandatory=$true)][string]$AppId
    )
    
    try {
        # App-Daten laden
        $appsData = Load-AppsData
        $app = $appsData | Where-Object { $_.Id -eq $AppId }
        
        if ($null -eq $app) {
            throw "App mit ID '$AppId' nicht gefunden"
        }
        
        # Winget-Upgrade ausführen
        Write-Host "→ Upgrade für $AppId ..." -ForegroundColor Blue
        
        $process = Start-Process -FilePath "winget" -ArgumentList "upgrade --id=$AppId --silent --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "Winget-Upgrade fehlgeschlagen mit Exit-Code $($process.ExitCode)"
        }
        
        # Erfolg melden
        Write-Host "Upgrade von $($app.Name) erfolgreich abgeschlossen." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Fehler beim Upgrade von $AppId : $_"
        return $false
    }
}

# Exportiere die Initialisierungsfunktion für main.ps1
Export-ModuleMember -Function Initialize-Installer