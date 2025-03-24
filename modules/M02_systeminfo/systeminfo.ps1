# M02_systeminfo-Modul für MINTutil
# Sammelt und zeigt Systeminformationen wie Hardware, Software, Leistung und Netzwerkdaten

# Globale Variablen
$script:SystemInfoBasePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:CacheDataPath = Join-Path -Path $PSScriptRoot -ChildPath "../../data/M02_systeminfo/cache.json"
$script:HistoryDataPath = Join-Path -Path $PSScriptRoot -ChildPath "../../data/M02_systeminfo/history.json"
$script:ReportsPath = Join-Path -Path $PSScriptRoot -ChildPath "../../data/M02_systeminfo/reports"
$script:DisplayConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "../../config/M02_systeminfo/display.json"
$script:SystemInfoUI = $null

# ============= Initialisierungsfunktionen =============

<#
.SYNOPSIS
    Kurzbeschreibung der Funktion Initialize-M02_systeminfo.
.DESCRIPTION
    Detaillierte Beschreibung der Funktion Initialize-M02_systeminfo.
.PARAMETER Parameter1
    Beschreibung des ersten Parameters.
.EXAMPLE
    Initialize-M02_systeminfo -Parameter1 Wert
#>
function Initialize-M02_systeminfo {
    param(
        [Parameter(Mandatory=$true)]$Window
    )
    try {
        $script:SystemInfoUI = $Window
        
        # Sicherstellen, dass Verzeichnisse existieren
        if (-not (Test-Path -Path (Split-Path -Parent $script:CacheDataPath))) {
            New-Item -Path (Split-Path -Parent $script:CacheDataPath) -ItemType Directory -Force | Out-Null
        }
        
        if (-not (Test-Path -Path $script:ReportsPath)) {
            New-Item -Path $script:ReportsPath -ItemType Directory -Force | Out-Null
        }
        
        # Event-Handler für Buttons einrichten
        Register-EventHandlers
        
        # Initiale Daten laden
        Load-SystemData
        
        Write-Host "M02_systeminfo-Modul initialisiert"
        return $true
    } catch {
        Write-Error "Fehler bei der Initialisierung des M02_systeminfo-Moduls: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Kurzbeschreibung der Funktion Register-EventHandlers.
.DESCRIPTION
    Detaillierte Beschreibung der Funktion Register-EventHandlers.
.PARAMETER Parameter1
    Beschreibung des ersten Parameters.
.EXAMPLE
    Register-EventHandlers -Parameter1 Wert
#>
function Register-EventHandlers {
    try {
        # Button-Event-Handler registrieren
        $btnRefresh = $script:SystemInfoUI.FindName("BtnRefresh")
        $btnExport = $script:SystemInfoUI.FindName("BtnExport")
        $btnHistory = $script:SystemInfoUI.FindName("BtnHistory")
        
        $btnRefresh.Add_Click({ Refresh-SystemData })
        $btnExport.Add_Click({ Export-SystemReport })
        $btnHistory.Add_Click({ Show-SystemHistory })
        
        Write-Host "Event-Handler für M02_systeminfo-Modul registriert"
    } catch {
        Write-Error "Fehler beim Registrieren der Event-Handler: $_"
        throw $_
    }
}

# ============= Datenfunktionen =============

<#
.SYNOPSIS
    Kurzbeschreibung der Funktion Load-SystemData.
.DESCRIPTION
    Detaillierte Beschreibung der Funktion Load-SystemData.
.PARAMETER Parameter1
    Beschreibung des ersten Parameters.
.EXAMPLE
    Load-SystemData -Parameter1 Wert
#>
function Load-SystemData {
    try {
        # Prüfen, ob Cache existiert und aktuell ist
        $useCache = $false
        if (Test-Path -Path $script:CacheDataPath) {
            $cacheInfo = Get-Item -Path $script:CacheDataPath
            $cacheAge = (Get-Date) - $cacheInfo.LastWriteTime
            
            # Cache verwenden, wenn er weniger als 1 Stunde alt ist
            if ($cacheAge.TotalHours -lt 1) {
                $useCache = $true
                $systemData = Get-Content -Path $script:CacheDataPath -Raw | ConvertFrom-Json
                Write-Host "System-Daten aus Cache geladen (Alter: $($cacheAge.TotalMinutes.ToString('0.0')) Minuten)"
            }
        }
        
        # Wenn kein Cache verwendet wird, neue Daten sammeln
        if (-not $useCache) {
            $systemData = Collect-SystemData
            
            # Daten im Cache speichern
            $systemData | ConvertTo-Json -Depth 4 | Set-Content -Path $script:CacheDataPath -Force
            Write-Host "Neue System-Daten gesammelt und in Cache gespeichert"
        }
        
        # UI aktualisieren
        Update-SystemInfoUI -SystemData $systemData
        
        return $systemData
    } catch {
        Write-Error "Fehler beim Laden der System-Daten: $_"
        throw $_
    }
}

<#
.SYNOPSIS
    Kurzbeschreibung der Funktion Refresh-SystemData.
.DESCRIPTION
    Detaillierte Beschreibung der Funktion Refresh-SystemData.
.PARAMETER Parameter1
    Beschreibung des ersten Parameters.
.EXAMPLE
    Refresh-SystemData -Parameter1 Wert
#>
function Refresh-SystemData {
    try {
        # Daten neu sammeln
        $systemData = Collect-SystemData
        
        # Daten im Cache speichern
        $systemData | ConvertTo-Json -Depth 4 | Set-Content -Path $script:CacheDataPath -Force
        
        # In Verlaufshistorie speichern
        Add-ToSystemHistory -SystemData $systemData
        
        # UI aktualisieren
        Update-SystemInfoUI -SystemData $systemData
        
        # Letzte Aktualisierungszeit
        $lastUpdateTime = $script:SystemInfoUI.FindName("LastUpdateTime")
        $lastUpdateTime.Text = (Get-Date).ToString("dd.MM.yyyy HH:mm:ss")
        
        Write-Host "System-Daten aktualisiert"
    } catch {
        Write-Error "Fehler beim Aktualisieren der System-Daten: $_"
        [System.Windows.MessageBox]::Show(
            "Fehler beim Aktualisieren der System-Daten: $_", 
            "Fehler", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Error)
    }
}

<#
.SYNOPSIS
    Kurzbeschreibung der Funktion Collect-SystemData.
.DESCRIPTION
    Detaillierte Beschreibung der Funktion Collect-SystemData.
.PARAMETER Parameter1
    Beschreibung des ersten Parameters.
.EXAMPLE
    Collect-SystemData -Parameter1 Wert
#>
function Collect-SystemData {
    try {
        # Ergebnisobjekt initialisieren
        $systemData = @{
            CollectionTime = Get-Date
            OperatingSystem = @{}
            Hardware = @{}
            Network = @{}
            Performance = @{}
            Software = @{}
        }
        
        # OS-Informationen sammeln
        $osInfo = Get-CimInstance Win32_OperatingSystem
        $systemData.OperatingSystem = @{
            Name = $osInfo.Caption
            Version = $osInfo.Version
            Build = $osInfo.BuildNumber
            Architecture = $osInfo.OSArchitecture
            InstallDate = $osInfo.InstallDate
            LastBootTime = $osInfo.LastBootUpTime
        }
        
        # Hardware-Informationen sammeln
        # CPU
        $cpuInfo = Get-CimInstance Win32_Processor
        $systemData.Hardware.CPU = @{
            Name = $cpuInfo.Name
            Cores = $cpuInfo.NumberOfCores
            Threads = $cpuInfo.NumberOfLogicalProcessors
            Speed = "$($cpuInfo.MaxClockSpeed) MHz"
        }
        
        # RAM
        $ramInfo = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
        $totalRAM = [math]::Round($ramInfo.Sum / 1GB, 2)
        $systemData.Hardware.RAM = @{
            TotalGB = $totalRAM
            Slots = (Get-CimInstance Win32_PhysicalMemory).Count
        }
        
        # Festplatten
        $diskDrives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
        $systemData.Hardware.Disks = @()
        foreach ($disk in $diskDrives) {
            $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            $totalSizeGB = [math]::Round($disk.Size / 1GB, 2)
            $usedSpaceGB = $totalSizeGB - $freeSpaceGB
            $percentUsed = [math]::Round(($usedSpaceGB / $totalSizeGB) * 100, 1)
            
            $systemData.Hardware.Disks += @{
                Drive = $disk.DeviceID
                Label = $disk.VolumeName
                TotalGB = $totalSizeGB
                FreeGB = $freeSpaceGB
                UsedGB = $usedSpaceGB
                PercentUsed = $percentUsed
            }
        }
        
        # Grafikkarte
        $gpuInfo = Get-CimInstance Win32_VideoController
        $systemData.Hardware.GPU = @{
            Name = $gpuInfo.Name
            DriverVersion = $gpuInfo.DriverVersion
            RAM = if ($gpuInfo.AdapterRAM) { [math]::Round($gpuInfo.AdapterRAM / 1MB, 0) } else { "Unbekannt" }
        }
        
        # Netzwerkinformationen sammeln
        $networkAdapters = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true -and $_.NetEnabled -eq $true }
        $systemData.Network.Adapters = @()
        foreach ($adapter in $networkAdapters) {
            $config = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $adapter.Index }
            $systemData.Network.Adapters += @{
                Name = $adapter.Name
                ConnectionId = $adapter.NetConnectionID
                MacAddress = $adapter.MACAddress
                IpAddresses = $config.IPAddress
                Gateway = $config.DefaultIPGateway
                DnsServers = $config.DNSServerSearchOrder
            }
        }
        
        # Hostname
        $systemData.Network.HostName = $env:COMPUTERNAME
        
        # Leistungsinformationen sammeln
        $performanceInfo = @{
            CpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
            MemoryUsage = @{
                TotalGB = $totalRAM
                UsedGB = $totalRAM - ([math]::Round((Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue / 1024, 2))
                PercentUsed = 100 - ([math]::Round((Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue / 1024 / $totalRAM * 100, 1))
            }
        }
        $systemData.Performance = $performanceInfo
        
        # Software-Informationen (Installierte Apps)
        $installedApps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
                         Where-Object { $_.DisplayName -ne $null } |
                         Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
        
        # Windows Store Apps hinzufügen, wenn PowerShell 5.1+ verwendet wird
        if ($PSVersionTable.PSVersion.Major -ge 5) {
            $storeApps = Get-AppxPackage | Select-Object Name, Version, Publisher
            foreach ($app in $storeApps) {
                $installedApps += [PSCustomObject]@{
                    DisplayName = $app.Name
                    DisplayVersion = $app.Version
                    Publisher = $app.Publisher
                    InstallDate = $null
                    Source = "WindowsStore"
                }
            }
        }
        
        $systemData.Software.InstalledApps = $installedApps | Sort-Object DisplayName
        $systemData.Software.AppCount = $installedApps.Count
        
        return $systemData
    } catch {
        Write-Error "Fehler beim Sammeln der System-Daten: $_"
        throw $_
    }
}

<#
.SYNOPSIS
    Kurzbeschreibung der Funktion Add-ToSystemHistory.
.DESCRIPTION
    Detaillierte Beschreibung der Funktion Add-ToSystemHistory.
.PARAMETER Parameter1
    Beschreibung des ersten Parameters.
.EXAMPLE
    Add-ToSystemHistory -Parameter1 Wert
#>
function Add-ToSystemHistory {
    param(
        [Parameter(Mandatory=$true)]$SystemData
    )
    
    try {
        $history = @()
        
        # Bestehende Historie laden, falls vorhanden
        if (Test-Path -Path $script:HistoryDataPath) {
            $history = Get-Content -Path $script:HistoryDataPath -Raw | ConvertFrom-Json
        }
        
        # Vereinfachten Eintrag für Historie erstellen
        $historyEntry = @{
            Timestamp = Get-Date
            OperatingSystem = $SystemData.OperatingSystem.Name
            CpuUsage = $SystemData.Performance.CpuUsage
            MemoryUsagePercent = $SystemData.Performance.MemoryUsage.PercentUsed
            DiskSpace = @{}
        }
        
        # Festplattennutzung
        foreach ($disk in $SystemData.Hardware.Disks) {
            $historyEntry.DiskSpace[$disk.Drive] = $disk.PercentUsed
        }
        
        # Zum Verlauf hinzufügen (maximal 30 Einträge)
        $history = @($historyEntry) + $history
        if ($history.Count -gt 30) {
            $history = $history[0..29]
        }
        
        # Verlauf speichern
        $history | ConvertTo-Json -Depth 4 | Set-Content -Path $script:HistoryDataPath -Force
        
        Write-Host "System-Daten zur Historie hinzugefügt (aktuell $($history.Count) Einträge)"
    } catch {
        Write-Error "Fehler beim Hinzufügen zur System-Historie: $_"
    }
}

<#
.SYNOPSIS
    Kurzbeschreibung der Funktion Show-SystemHistory.
.DESCRIPTION
    Detaillierte Beschreibung der Funktion Show-SystemHistory.
.PARAMETER Parameter1
    Beschreibung des ersten Parameters.
.EXAMPLE
    Show-SystemHistory -Parameter1 Wert
#>
function Show-SystemHistory {
    try {
        # Verlaufsdaten laden
        if (-not (Test-Path -Path $script:HistoryDataPath)) {
            [System.Windows.MessageBox]::Show(
                "Es sind noch keine Verlaufsdaten vorhanden.", 
                "Information", 
                [System.Windows.MessageBoxButton]::OK, 
                [System.Windows.MessageBoxImage]::Information)
            return
        }
        
        $history = Get-Content -Path $script:HistoryDataPath -Raw | ConvertFrom-Json
        
        # Verlaufsfenster erstellen
        $historyWindow = New-Object System.Windows.Window
        $historyWindow.Title = "Systemverlauf"
        $historyWindow.Width = 600
        $historyWindow.Height = 400
        $historyWindow.WindowStartupLocation = "CenterScreen"
        
        $mainPanel = New-Object System.Windows.Controls.StackPanel
        $mainPanel.Margin = "10"
        
        # Überschrift
        $titleBlock = New-Object System.Windows.Controls.TextBlock
        $titleBlock.Text = "Systemverlauf"
        $titleBlock.FontWeight = "Bold"
        $titleBlock.FontSize = 16
        $titleBlock.Margin = "0,0,0,10"
        $mainPanel.Children.Add($titleBlock)
        
        # DataGrid für Verlaufseinträge
        $dataGrid = New-Object System.Windows.Controls.DataGrid
        $dataGrid.AutoGenerateColumns = $false
        $dataGrid.IsReadOnly = $true
        $dataGrid.Margin = "0,10,0,10"
        $dataGrid.Height = 300
        
        # Spalten definieren
        $timestampColumn = New-Object System.Windows.Controls.DataGridTextColumn
        $timestampColumn.Header = "Zeitstempel"
        $timestampColumn.Binding = New-Object System.Windows.Data.Binding("Timestamp")
        $timestampColumn.Width = 150
        $dataGrid.Columns.Add($timestampColumn)
        
        $cpuColumn = New-Object System.Windows.Controls.DataGridTextColumn
        $cpuColumn.Header = "CPU-Auslastung (%)"
        $cpuColumn.Binding = New-Object System.Windows.Data.Binding("CpuUsage")
        $cpuColumn.Width = 120
        $dataGrid.Columns.Add($cpuColumn)
        
        $ramColumn = New-Object System.Windows.Controls.DataGridTextColumn
        $ramColumn.Header = "RAM-Auslastung (%)"
        $ramColumn.Binding = New-Object System.Windows.Data.Binding("MemoryUsagePercent")
        $ramColumn.Width = 120
        $dataGrid.Columns.Add($ramColumn)
        
        # Daten hinzufügen
        foreach ($entry in $history) {
            $dataGrid.Items.Add($entry)
        }
        
        $mainPanel.Children.Add($dataGrid)
        
        # OK-Button
        $okButton = New-Object System.Windows.Controls.Button
        $okButton.Content = "Schließen"
        $okButton.Padding = "20,5"
        $okButton.Margin = "0,10,0,0"
        $okButton.HorizontalAlignment = "Right"
        $okButton.Add_Click({ $historyWindow.Close() })
        $mainPanel.Children.Add($okButton)
        
        $historyWindow.Content = $mainPanel
        $historyWindow.ShowDialog() | Out-Null
        
    } catch {
        Write-Error "Fehler beim Anzeigen des Systemverlaufs: $_"
        [System.Windows.MessageBox]::Show(
            "Fehler beim Anzeigen des Systemverlaufs: $_", 
            "Fehler", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Error)
    }
}

<#
.SYNOPSIS
    Kurzbeschreibung der Funktion Export-SystemReport.
.DESCRIPTION
    Detaillierte Beschreibung der Funktion Export-SystemReport.
.PARAMETER Parameter1
    Beschreibung des ersten Parameters.
.EXAMPLE
    Export-SystemReport -Parameter1 Wert
#>
function Export-SystemReport {
    try {
        # Aktuelle Daten sammeln
        $systemData = Collect-SystemData
        
        # Formatierte Berichtszeit für Dateinamen
        $reportTime = Get-Date -Format "yyyyMMdd_HHmmss"
        $reportFile = Join-Path -Path $script:ReportsPath -ChildPath "system_report_$reportTime.json"
        
        # Bericht speichern
        $systemData | ConvertTo-Json -Depth 4 | Set-Content -Path $reportFile -Force
        
        # Kopie als "latest" speichern
        $latestReportFile = Join-Path -Path $script:ReportsPath -ChildPath "latest_report.json"
        $systemData | ConvertTo-Json -Depth 4 | Set-Content -Path $latestReportFile -Force
        
        # Erfolgsmeldung
        [System.Windows.MessageBox]::Show(
            "Systembericht wurde gespeichert unter:`n$reportFile", 
            "Bericht exportiert", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Information)
        
        Write-Host "Systembericht exportiert nach: $reportFile"
    } catch {
        Write-Error "Fehler beim Exportieren des Systemberichts: $_"
        [System.Windows.MessageBox]::Show(
            "Fehler beim Exportieren des Systemberichts: $_", 
            "Fehler", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Error)
    }
}

# ============= UI-Funktionen =============

<#
.SYNOPSIS
    Kurzbeschreibung der Funktion Update-SystemInfoUI.
.DESCRIPTION
    Detaillierte Beschreibung der Funktion Update-SystemInfoUI.
.PARAMETER Parameter1
    Beschreibung des ersten Parameters.
.EXAMPLE
    Update-SystemInfoUI -Parameter1 Wert
#>
function Update-SystemInfoUI {
    param(
        [Parameter(Mandatory=$true)]$SystemData
    )
    
    try {
        # OS-Informationen aktualisieren
        $osName = $script:SystemInfoUI.FindName("OsName")
        $osVersion = $script:SystemInfoUI.FindName("OsVersion")
        $osBuild = $script:SystemInfoUI.FindName("OsBuild")
        $osArchitecture = $script:SystemInfoUI.FindName("OsArchitecture")
        
        $osName.Text = $SystemData.OperatingSystem.Name
        $osVersion.Text = $SystemData.OperatingSystem.Version
        $osBuild.Text = $SystemData.OperatingSystem.Build
        $osArchitecture.Text = $SystemData.OperatingSystem.Architecture
        
        # Hardware-Informationen aktualisieren
        $cpuInfo = $script:SystemInfoUI.FindName("CpuInfo")
        $ramInfo = $script:SystemInfoUI.FindName("RamInfo")
        $diskInfo = $script:SystemInfoUI.FindName("DiskInfo")
        $gpuInfo = $script:SystemInfoUI.FindName("GpuInfo")
        
        $cpuInfo.Text = "$($SystemData.Hardware.CPU.Name) ($($SystemData.Hardware.CPU.Cores) Kerne, $($SystemData.Hardware.CPU.Threads) Threads)"
        $ramInfo.Text = "$($SystemData.Hardware.RAM.TotalGB) GB"
        
        # Festplatten-Zusammenfassung
        $diskSummary = ""
        foreach ($disk in $SystemData.Hardware.Disks) {
            $diskSummary += "$($disk.Drive) $($disk.Label) ($($disk.FreeGB) GB frei von $($disk.TotalGB) GB), "
        }
        $diskSummary = $diskSummary.TrimEnd(", ")
        $diskInfo.Text = $diskSummary
        
        $gpuInfo.Text = $SystemData.Hardware.GPU.Name
        
        # Netzwerk-Informationen aktualisieren
        $hostName = $script:SystemInfoUI.FindName("HostName")
        $ipAddress = $script:SystemInfoUI.FindName("IpAddress")
        $networkAdapter = $script:SystemInfoUI.FindName("NetworkAdapter")
        
        $hostName.Text = $SystemData.Network.HostName
        
        # IP-Adresse und Adapter-Informationen
        if ($SystemData.Network.Adapters.Count -gt 0) {
            $primaryAdapter = $SystemData.Network.Adapters[0]
            $ipAddress.Text = ($primaryAdapter.IpAddresses -join ", ")
            $networkAdapter.Text = "$($primaryAdapter.Name) ($($primaryAdapter.ConnectionId))"
        } else {
            $ipAddress.Text = "Nicht verfügbar"
            $networkAdapter.Text = "Keine aktiven Adapter gefunden"
        }
        
        # Letzte Aktualisierungszeit
        $lastUpdateTime = $script:SystemInfoUI.FindName("LastUpdateTime")
        $lastUpdateTime.Text = $SystemData.CollectionTime.ToString("dd.MM.yyyy HH:mm:ss")
        
        Write-Host "UI mit System-Daten aktualisiert"
    } catch {
        Write-Error "Fehler beim Aktualisieren der System-Info-UI: $_"
    }
}

# Exportiere die Initialisierungsfunktion für main.ps1
Export-ModuleMember -Function Initialize-M02_systeminfo








