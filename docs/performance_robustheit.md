# Optimierungsstrategien für MINTutil: Performance und Robustheit

Dieses Dokument beschreibt erweiterte Strategien zur Optimierung von Performance und Robustheit in der modularen MINTutil-Architektur.

## Performance-Optimierungen

### 1. Verbessertes Lazy Loading

Die aktuelle Architektur implementiert bereits Lazy Loading durch die `Load-ModuleUI`-Funktion. Dies kann weiter optimiert werden:

```powershell
function Load-ModuleUI {
    param([string]$ModuleName)
    
    try {
        # Prüfen, ob UI bereits geladen wurde
        if ($script:Modules[$ModuleName].UIElements.Count -gt 0) {
            return $true
        }
        
        # Zusätzlich: Priorisierte Ressourcen vorladen
        $preloadResources = $script:Modules[$ModuleName].Meta.preloadResources
        if ($null -ne $preloadResources) {
            foreach ($resource in $preloadResources) {
                # Ressource vorladen (z.B. häufig benötigte Daten)
                Preload-Resource -ModuleName $ModuleName -ResourcePath $resource
            }
        }
        
        # Rest wie bisher...
    } catch {
        # Fehlerbehandlung
    }
}
```

### 2. Datenzwischenspeicherung (Caching)

Erweiterte Caching-Strategien für alle Module:

```powershell
function Get-CachedData {
    param(
        [string]$CacheKey,
        [int]$MaxAgeSeconds = 3600,
        [scriptblock]$DataProvider
    )
    
    $cacheFile = Join-Path -Path $script:CachePath -ChildPath "$CacheKey.cache"
    $useCache = $false
    
    # Prüfen, ob Cache existiert und aktuell ist
    if (Test-Path -Path $cacheFile) {
        $cacheInfo = Get-Item -Path $cacheFile
        $cacheAge = (Get-Date) - $cacheInfo.LastWriteTime
        
        if ($cacheAge.TotalSeconds -lt $MaxAgeSeconds) {
            $useCache = $true
            $data = Get-Content -Path $cacheFile -Raw | ConvertFrom-Json
            return $data
        }
    }
    
    # Keine Cache-Nutzung möglich, Daten neu generieren
    $data = & $DataProvider
    
    # In Cache speichern
    if (-not (Test-Path -Path (Split-Path -Parent $cacheFile))) {
        New-Item -Path (Split-Path -Parent $cacheFile) -ItemType Directory -Force | Out-Null
    }
    
    $data | ConvertTo-Json -Depth 10 -Compress | Set-Content -Path $cacheFile -Force
    return $data
}
```

### 3. Speicheroptimierung

PowerShell-Skripts können Speicherlecks verursachen. Implementieren Sie Strategien zur besseren Speicherverwaltung:

```powershell
function Optimize-Memory {
    # Nicht mehr benötigte große Objekte explizit freigeben
    $largeObjects.ForEach({ $_ = $null })
    
    # Garbage Collection erzwingen
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
    
    # Speichernutzung protokollieren
    $process = Get-Process -Id $PID
    Write-Log -Message "Speichernutzung: $($process.WorkingSet64 / 1MB) MB"
}
```

### 4. Parallelisierung

Für rechenintensive Aufgaben sollten PowerShell-Jobs oder Runspaces genutzt werden:

```powershell
function Invoke-ParallelTask {
    param(
        [Parameter(Mandatory=$true)][array]$Tasks,
        [int]$ThrottleLimit = 5
    )
    
    # Option 1: Jobs
    $jobs = @()
    foreach ($task in $Tasks) {
        $jobs += Start-Job -ScriptBlock $task.ScriptBlock -ArgumentList $task.Arguments
        
        # Throttling
        while (($jobs | Where-Object { $_.State -eq 'Running' }).Count -ge $ThrottleLimit) {
            Start-Sleep -Milliseconds 100
        }
    }
    
    # Auf Abschluss warten und Ergebnisse sammeln
    $results = @()
    foreach ($job in $jobs) {
        $results += Receive-Job -Job $job -Wait
        Remove-Job -Job $job
    }
    
    return $results
    
    # Option 2: Mit ThreadJobs (erfordert das ThreadJob-Modul)
    # $jobs = foreach ($task in $Tasks) {
    #     Start-ThreadJob -ScriptBlock $task.ScriptBlock -ArgumentList $task.Arguments -ThrottleLimit $ThrottleLimit
    # }
}
```

### 5. Datei-I/O-Optimierung

Reduzieren Sie Festplattenzugriffe durch gebündelte Operationen:

```powershell
# Vermeiden Sie häufige kleine Schreibvorgänge
# Schlecht:
foreach ($item in $items) {
    Add-Content -Path $logFile -Value $item.ToString()
}

# Besser:
$content = $items | ForEach-Object { $_.ToString() } | Out-String
Add-Content -Path $logFile -Value $content

# Noch besser (für größere Datenmengen):
$streamWriter = [System.IO.StreamWriter]::new($logFile, $true)
foreach ($item in $items) {
    $streamWriter.WriteLine($item.ToString())
}
$streamWriter.Close()
```

## Robustheitsstrategien

### 1. Erweiterte Fehlerbehandlung

Implementieren Sie ein durchgängiges Fehlerbehandlungssystem:

```powershell
function Invoke-RobustOperation {
    param(
        [Parameter(Mandatory=$true)][scriptblock]$Operation,
        [int]$MaxRetries = 3,
        [int]$RetryDelayMs = 1000
    )
    
    $retryCount = 0
    $success = $false
    $lastError = $null
    
    while (-not $success -and $retryCount -lt $MaxRetries) {
        try {
            $result = & $Operation
            $success = $true
            return $result
        } catch {
            $lastError = $_
            $retryCount++
            
            Write-Warning "Operation fehlgeschlagen (Versuch $retryCount/$MaxRetries): $_"
            if ($retryCount -lt $MaxRetries) {
                Start-Sleep -Milliseconds ($RetryDelayMs * $retryCount)  # Exponentielles Backoff
            }
        }
    }
    
    if (-not $success) {
        Write-Error "Operation nach $MaxRetries Versuchen fehlgeschlagen: $lastError"
        throw $lastError
    }
}
```

### 2. Transaktionssicherheit für Dateioperationen

Schützen Sie kritische Dateioperationen:

```powershell
function Update-ConfigSafely {
    param(
        [string]$ConfigPath,
        [scriptblock]$UpdateFunction
    )
    
    # Temp-Datei für atomare Operation
    $tempFile = "$ConfigPath.tmp"
    $backupFile = "$ConfigPath.bak"
    
    try {
        # Sicherungskopie erstellen
        if (Test-Path -Path $ConfigPath) {
            Copy-Item -Path $ConfigPath -Destination $backupFile -Force
        }
        
        # Konfiguration laden
        $config = if (Test-Path -Path $ConfigPath) {
            Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        } else {
            [PSCustomObject]@{}
        }
        
        # Aktualisierungsfunktion ausführen
        $updatedConfig = & $UpdateFunction $config
        
        # In temporäre Datei schreiben
        $updatedConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $tempFile -Force
        
        # Atomare Ersetzung
        Move-Item -Path $tempFile -Destination $ConfigPath -Force
        
        return $true
    } catch {
        # Bei Fehler: Wiederherstellung
        Write-Error "Fehler beim Aktualisieren der Konfiguration: $_"
        
        if (Test-Path -Path $backupFile) {
            Write-Warning "Stelle Backup wieder her..."
            Move-Item -Path $backupFile -Destination $ConfigPath -Force
        }
        
        return $false
    } finally {
        # Aufräumen
        if (Test-Path -Path $tempFile) { Remove-Item -Path $tempFile -Force }
        if (Test-Path -Path $backupFile) { Remove-Item -Path $backupFile -Force }
    }
}
```

### 3. Erweiterte Datenvalidierung

Implementieren Sie Schema-Validierung für komplexe Daten:

```powershell
function Test-JsonSchema {
    param(
        [Parameter(Mandatory=$true)]$Data,
        [Parameter(Mandatory=$true)][hashtable]$Schema
    )
    
    function Test-SchemaProperty {
        param($Value, $PropertySchema)
        
        # Typ überprüfen
        $typeValid = switch ($PropertySchema.type) {
            'string'  { $Value -is [string] }
            'number'  { $Value -is [int] -or $Value -is [double] }
            'boolean' { $Value -is [bool] }
            'array'   { $Value -is [array] }
            'object'  { $Value -is [PSCustomObject] -or $Value -is [hashtable] }
            default   { $true }
        }
        
        if (-not $typeValid) { return $false }
        
        # Zusätzliche Validierungen
        if ($PropertySchema.required -and $null -eq $Value) { return $false }
        if ($PropertySchema.minLength -and $Value.Length -lt $PropertySchema.minLength) { return $false }
        if ($PropertySchema.maxLength -and $Value.Length -gt $PropertySchema.maxLength) { return $false }
        if ($PropertySchema.pattern -and $Value -notmatch $PropertySchema.pattern) { return $false }
        
        return $true
    }
    
    $valid = $true
    $errors = @()
    
    # Pflichtfelder überprüfen
    foreach ($requiredProp in $Schema.required) {
        if (-not $Data.PSObject.Properties.Name.Contains($requiredProp)) {
            $valid = $false
            $errors += "Pflichtfeld '$requiredProp' fehlt"
        }
    }
    
    # Eigenschaften überprüfen
    foreach ($prop in $Schema.properties.Keys) {
        if ($Data.PSObject.Properties.Name.Contains($prop)) {
            $propSchema = $Schema.properties[$prop]
            $propValue = $Data.$prop
            
            if (-not (Test-SchemaProperty -Value $propValue -PropertySchema $propSchema)) {
                $valid = $false
                $errors += "Eigenschaft '$prop' ist ungültig"
            }
            
            # Rekursiv für verschachtelte Objekte
            if ($propSchema.type -eq 'object' -and $propSchema.properties) {
                $nestedResult = Test-JsonSchema -Data $propValue -Schema $propSchema
                if (-not $nestedResult.Valid) {
                    $valid = $false
                    $errors += $nestedResult.Errors | ForEach-Object { "In '$prop': $_" }
                }
            }
        }
    }
    
    return @{
        Valid = $valid
        Errors = $errors
    }
}
```

### 4. Health-Checks

Implementieren Sie regelmäßige Health-Checks für Module:

```powershell
function Invoke-ModuleHealthCheck {
    param([string]$ModuleName)
    
    $healthStatus = @{
        Name = $ModuleName
        Status = "Healthy"
        Checks = @()
        Timestamp = Get-Date
    }
    
    # Verschiedene Prüfungen durchführen
    
    # 1. Prüfen, ob alle erforderlichen Dateien vorhanden sind
    $requiredFiles = @(
        "meta/$ModuleName/meta.json",
        "meta/$ModuleName/modulinfo.json",
        "modules/$ModuleName/$($ModuleName.ToLower()).ps1"
    )
    
    foreach ($file in $requiredFiles) {
        $checkResult = @{
            Name = "Required file: $file"
            Status = if (Test-Path -Path $file) { "Pass" } else { "Fail" }
            Details = if (Test-Path -Path $file) { "File exists" } else { "File missing" }
        }
        
        $healthStatus.Checks += $checkResult
        
        if ($checkResult.Status -eq "Fail") {
            $healthStatus.Status = "Unhealthy"
        }
    }
    
    # 2. Datenintegritätsprüfung
    $dataFiles = Get-ChildItem -Path "data/$ModuleName" -Filter "*.json" -ErrorAction SilentlyContinue
    foreach ($file in $dataFiles) {
        $checkResult = @{
            Name = "Data integrity: $($file.Name)"
            Status = "Unknown"
            Details = ""
        }
        
        try {
            $null = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $checkResult.Status = "Pass"
            $checkResult.Details = "Valid JSON"
        } catch {
            $checkResult.Status = "Fail"
            $checkResult.Details = "Invalid JSON: $_"
            $healthStatus.Status = "Unhealthy"
        }
        
        $healthStatus.Checks += $checkResult
    }
    
    # 3. Modulspezifische Prüfungen durchführen
    # [...]
    
    return $healthStatus
}
```

### 5. Automatische Wiederherstellung

Implementieren Sie Selbstheilungsmechanismen:

```powershell
function Repair-ModuleState {
    param([string]$ModuleName)
    
    $repairStatus = @{
        Module = $ModuleName
        RepairsAttempted = @()
        RepairsSuccessful = @()
        OverallSuccess = $true
    }
    
    # 1. Fehlende Verzeichnisse erstellen
    $requiredDirs = @(
        "modules/$ModuleName",
        "config/$ModuleName",
        "data/$ModuleName",
        "meta/$ModuleName",
        "docs/$ModuleName"
    )
    
    foreach ($dir in $requiredDirs) {
        if (-not (Test-Path -Path $dir)) {
            $repairStatus.RepairsAttempted += "Create directory: $dir"
            
            try {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
                $repairStatus.RepairsSuccessful += "Create directory: $dir"
            } catch {
                $repairStatus.OverallSuccess = $false
                Write-Error "Failed to create directory $dir : $_"
            }
        }
    }
    
    # 2. Beschädigte Konfigurationsdateien aus Backups wiederherstellen
    $configFiles = Get-ChildItem -Path "config/$ModuleName" -Filter "*.json" -ErrorAction SilentlyContinue
    foreach ($file in $configFiles) {
        try {
            $null = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        } catch {
            $repairStatus.RepairsAttempted += "Repair config: $($file.Name)"
            
            # Nach Backup suchen
            $backupFile = Join-Path -Path "config/$ModuleName/backups" -ChildPath $file.Name
            if (Test-Path -Path $backupFile) {
                try {
                    Copy-Item -Path $backupFile -Destination $file.FullName -Force
                    $repairStatus.RepairsSuccessful += "Restore config from backup: $($file.Name)"
                } catch {
                    $repairStatus.OverallSuccess = $false
                    Write-Error "Failed to restore config from backup: $_"
                }
            } else {
                # Standard-Config erstellen
                try {
                    $defaultConfig = @{ defaultSettings = $true }
                    $defaultConfig | ConvertTo-Json | Set-Content -Path $file.FullName -Force
                    $repairStatus.RepairsSuccessful += "Create default config: $($file.Name)"
                } catch {
                    $repairStatus.OverallSuccess = $false
                    Write-Error "Failed to create default config: $_"
                }
            }
        }
    }
    
    # 3. Weitere modulspezifische Reparaturen
    # [...]
    
    return $repairStatus
}
```

## Architektonische Optimierungen

### 1. Verbesserte Modulstruktur

Die aktuelle Modulstruktur kann mit einigen Anpassungen noch robuster werden:

```
MINTutil/
├── modules/
│   ├── _core/               # Kernfunktionalität und Hilfsmodule
│   │   ├── logging.ps1      # Zentrales Logging
│   │   ├── error.ps1        # Fehlerbehandlung
│   │   ├── cache.ps1        # Caching-Infrastruktur
│   │   ├── eventbus.ps1     # Zentraler Eventbus
│   │   └── validation.ps1   # Datenvalidierung
│   ├── Installer/           # Wie bisher
│   └── SystemInfo/          # Wie bisher
├── config/                  # Wie bisher
├── data/                    # Wie bisher
└── ...
```

### 2. Einheitliches Logging

Implementieren Sie ein zentrales Logging-System:

```powershell
# In _core/logging.ps1
function Write-Log {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "FATAL")][string]$Level = "INFO",
        [string]$ModuleName = "Core"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] [$ModuleName] $Message"
    
    # In Datei schreiben
    $logFile = Join-Path -Path $script:LogPath -ChildPath "mintutil_$(Get-Date -Format 'yyyyMMdd').log"
    
    # Sicherstellen, dass Verzeichnis existiert
    if (-not (Test-Path -Path (Split-Path -Parent $logFile))) {
        New-Item -Path (Split-Path -Parent $logFile) -ItemType Directory -Force | Out-Null
    }
    
    Add-Content -Path $logFile -Value $logMessage
    
    # Auch auf Konsole ausgeben, wenn gewünscht
    switch ($Level) {
        "DEBUG"   { if ($script:LogDebug) { Write-Host $logMessage -ForegroundColor Gray } }
        "INFO"    { Write-Host $logMessage -ForegroundColor White }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "FATAL"   { Write-Host $logMessage -ForegroundColor DarkRed -BackgroundColor White }
    }
}
```

### 3. Zentrale Fehlerverwaltung

In `_core/error.ps1`:

```powershell
function Register-ExceptionHandler {
    $null = $Host.UI.SourceInit_bak = $Host.UI.RawUI.WindowTitle
    
    # Globaler Fehlerhandler
    $global:ErrorActionPreference = "Stop"
    
    # Unerwartete Ausnahmen abfangen
    $null = $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
        param($CommandName, $Exception)
        Write-Log -Level ERROR -Message "Command not found: $CommandName - $Exception" -ModuleName "ExceptionHandler"
        # Optional: Benutzer benachrichtigen oder weitere Aktionen
    }
    
    # PowerShell Streams umleiten
    $null = $PSDefaultParameterValues["Out-Default:OutBuffer"] = 1
    $null = $PSDefaultParameterValues["Write-Error:ErrorAction"] = "Continue"
    
    # Fehler protokollieren
    [System.Management.Automation.PSLocalEventManager]::RegisterForEngineEvent_bak = [System.Management.Automation.PSLocalEventManager]::RegisterEngineEvent
    [System.Management.Automation.PSLocalEventManager]::RegisterEngineEvent = {
        param($EventName, $ScriptBlock)
        if ($EventName -eq "Error") {
            $newScriptBlock = {
                param($Sender, $EventArgs)
                
                # Ursprüngliche Fehlerbehandlung ausführen
                & $ScriptBlock $Sender $EventArgs
                
                # Zusätzlich: Fehler protokollieren
                $exception = $EventArgs.Exception
                $scriptName = if ($EventArgs.InvocationInfo.ScriptName) {
                    Split-Path -Leaf $EventArgs.InvocationInfo.ScriptName
                } else {
                    "Interactive"
                }
                
                $lineNumber = $EventArgs.InvocationInfo.ScriptLineNumber
                
                Write-Log -Level ERROR -Message "Exception in $scriptName:$lineNumber - $($exception.Message)" -ModuleName "ExceptionHandler"
            }
            
            # Neue Fehlerbehandlung registrieren
            [System.Management.Automation.PSLocalEventManager]::RegisterForEngineEvent_bak.Invoke($EventName, $newScriptBlock)
        } else {
            # Andere Events normal behandeln
            [System.Management.Automation.PSLocalEventManager]::RegisterForEngineEvent_bak.Invoke($EventName, $ScriptBlock)
        }
    }
    
    Write-Log -Level INFO -Message "Exception handler registered" -ModuleName "ExceptionHandler"
}
```

### 4. Modulare Testinfrastruktur

Automatisierte Tests für Module implementieren:

```powershell
# In modules/_core/testing.ps1
function Invoke-ModuleTest {
    param(
        [Parameter(Mandatory=$true)][string]$ModuleName,
        [switch]$SkipIntegrationTests
    )
    
    $testResults = @{
        ModuleName = $ModuleName
        UnitTests = @{
            Total = 0
            Passed = 0
            Failed = 0
            Skipped = 0
        }
        IntegrationTests = @{
            Total = 0
            Passed = 0
            Failed = 0
            Skipped = 0
        }
        FailedTests = @()
    }
    
    # Pfade zu Testdateien
    $unitTestPath = Join-Path -Path $script:BasePath -ChildPath "tests/$ModuleName/unit"
    $integrationTestPath = Join-Path -Path $script:BasePath -ChildPath "tests/$ModuleName/integration"
    
    # Unit Tests ausführen
    if (Test-Path -Path $unitTestPath) {
        $testFiles = Get-ChildItem -Path $unitTestPath -Filter "*.Tests.ps1" -Recurse
        
        foreach ($testFile in $testFiles) {
            Write-Log -Level INFO -Message "Running unit test: $($testFile.Name)" -ModuleName "Testing"
            
            $testFile | ForEach-Object {
                $testResults.UnitTests.Total++
                
                try {
                    & $_.FullName
                    $testResults.UnitTests.Passed++
                } catch {
                    $testResults.UnitTests.Failed++
                    $testResults.FailedTests += @{
                        File = $_.Name
                        Type = "Unit"
                        Error = $_.Exception.Message
                    }
                    
                    Write-Log -Level ERROR -Message "Unit test failed: $($_.Name) - $($_.Exception.Message)" -ModuleName "Testing"
                }
            }
        }
    }
    
    # Integrationstests ausführen
    if ((-not $SkipIntegrationTests) -and (Test-Path -Path $integrationTestPath)) {
        $testFiles = Get-ChildItem -Path $integrationTestPath -Filter "*.Tests.ps1" -Recurse
        
        foreach ($testFile in $testFiles) {
            Write-Log -Level INFO -Message "Running integration test: $($testFile.Name)" -ModuleName "Testing"
            
            $testFile | ForEach-Object {
                $testResults.IntegrationTests.Total++
                
                try {
                    & $_.FullName
                    $testResults.IntegrationTests.Passed++
                } catch {
                    $testResults.IntegrationTests.Failed++
                    $testResults.FailedTests += @{
                        File = $_.Name
                        Type = "Integration"
                        Error = $_.Exception.Message
                    }
                    
                    Write-Log -Level ERROR -Message "Integration test failed: $($_.Name) - $($_.Exception.Message)" -ModuleName "Testing"
                }
            }
        }
    } else {
        $testResults.IntegrationTests.Skipped = $true
    }
    
    return $testResults
}
```

## Performance-Monitoring

Implementieren Sie ein Performance-Monitoring-System:

```powershell
function Start-PerformanceMonitoring {
    $script:PerformanceMetrics = @{
        ModuleLoadTimes = @{}
        OperationTimes = @{}
        MemoryUsage = @()
    }
    
    # Regelmäßige Speichernutzung erfassen
    $script:MemoryMonitoringJob = Start-Job -ScriptBlock {
        param($PID, $LogInterval)
        
        $metrics = @()
        
        while ($true) {
            try {
                $process = Get-Process -Id $PID -ErrorAction Stop
                $metrics += @{
                    Timestamp = Get-Date
                    WorkingSet = $process.WorkingSet64
                    PrivateMemory = $process.PrivateMemorySize64
                    VirtualMemory = $process.VirtualMemorySize64
                }
                
                # Nur die letzten 100 Messungen behalten
                if ($metrics.Count -gt 100) {
                    $metrics = $metrics | Select-Object -Last 100
                }
                
                # Status ausgeben
                $workingSetMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
                $privateMemoryMB = [math]::Round($process.PrivateMemorySize64 / 1MB, 2)
                
                # Ergebnisse als Ausgabe des Jobs zurückgeben
                [PSCustomObject]@{
                    Timestamp = Get-Date
                    WorkingSetMB = $workingSetMB
                    PrivateMemoryMB = $privateMemoryMB
                }
                
                Start-Sleep -Seconds $LogInterval
            } catch {
                # Prozess existiert möglicherweise nicht mehr
                break
            }
        }
    } -ArgumentList $PID, 60  # Alle 60 Sekunden messen
}

function Measure-Operation {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][scriptblock]$ScriptBlock
    )
    
    $startTime = Get-Date
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Operation ausführen
        $result = & $ScriptBlock
        
        # Ausführungszeit messen
        $stopwatch.Stop()
        $executionTime = $stopwatch.ElapsedMilliseconds
        
        # Zu Metriken hinzufügen
        if (-not $script:PerformanceMetrics.OperationTimes.ContainsKey($Name)) {
            $script:PerformanceMetrics.OperationTimes[$Name] = @()
        }
        
        $script:PerformanceMetrics.OperationTimes[$Name] += @{
            Timestamp = $startTime
            DurationMs = $executionTime
            Success = $true
        }
        
        # Wenn die Ausführungszeit kritisch lang ist, protokollieren
        if ($executionTime -gt 1000) {  # Länger als 1 Sekunde
            Write-Log -Level WARNING -Message "Long operation detected: $Name took $executionTime ms" -ModuleName "Performance"
        }
        
        return $result
    } catch {
        # Bei Fehler, Fehlerzeit und -details erfassen
        $stopwatch.Stop()
        $executionTime = $stopwatch.ElapsedMilliseconds
        
        if (-not $script:PerformanceMetrics.OperationTimes.ContainsKey($Name)) {
            $script:PerformanceMetrics.OperationTimes[$Name] = @()
        }
        
        $script:PerformanceMetrics.OperationTimes[$Name] += @{
            Timestamp = $startTime
            DurationMs = $executionTime
            Success = $false
            Error = $_.ToString()
        }
        
        Write-Log -Level ERROR -Message "Operation '$Name' failed after $executionTime ms: $_" -ModuleName "Performance"
        throw $_
    }
}

function Get-PerformanceReport {
    # Speichermetriken sammeln
    $memoryMetrics = Receive-Job -Job $script:MemoryMonitoringJob -Keep
    
    # Aktuelle Metriken erfassen
    $currentProcess = Get-Process -Id $PID
    $currentMemoryMB = [math]::Round($currentProcess.WorkingSet64 / 1MB, 2)
    
    $slowestOperations = @()
    foreach ($opName in $script:PerformanceMetrics.OperationTimes.Keys) {
        $operations = $script:PerformanceMetrics.OperationTimes[$opName]
        $avgDuration = ($operations | Measure-Object -Property DurationMs -Average).Average
        $maxDuration = ($operations | Measure-Object -Property DurationMs -Maximum).Maximum
        $failRate = ($operations | Where-Object { -not $_.Success } | Measure-Object).Count / $operations.Count
        
        $slowestOperations += [PSCustomObject]@{
            Name = $opName
            AverageDurationMs = $avgDuration
            MaxDurationMs = $maxDuration
            FailRate = $failRate
            Count = $operations.Count
        }
    }
    
    # Nach durchschnittlicher Ausführungszeit sortieren
    $slowestOperations = $slowestOperations | Sort-Object -Property AverageDurationMs -Descending
    
    $report = [PSCustomObject]@{
        Timestamp = Get-Date
        CurrentMemoryMB = $currentMemoryMB
        MemoryTrend = $memoryMetrics
        SlowestOperations = $slowestOperations | Select-Object -First 10
        ModuleLoadTimes = $script:PerformanceMetrics.ModuleLoadTimes
    }
    
    return $report
}
```

## Zusammenfassung der Optimierungsempfehlungen

1. **Performance-Optimierungen**
   - Lazy Loading erweitern
   - Caching-Strategie implementieren
   - Speichernutzung optimieren
   - Parallelisierung für rechenintensive Operationen
   - Datei-I/O minimieren

2. **Robustheitsstrategien**
   - Erweiterte Fehlerbehandlung mit Wiederholungslogik
   - Transaktionssicherheit für kritische Operationen
   - Schema-Validierung für Daten
   - Automatische Health-Checks
   - Selbstheilungsmechanismen

3. **Architektonische Verbesserungen**
   - Kernmodul für gemeinsame Funktionalität
   - Zentrales Logging-System
   - Globale Ausnahmebehandlung
   - Modulare Testinfrastruktur
   - Performance-Monitoring

Diese Strategien können schrittweise in die bestehende Architektur integriert werden, um die Performance und Robustheit von MINTutil weiter zu verbessern.