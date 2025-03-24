# Beispiel für die Verwendung von MINTYarchivar

# Importieren des Moduls
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$srcPath = Join-Path $modulePath "src"
$modulePath = Join-Path $srcPath "MINTYarchivar.ps1"

# Importieren des Moduls
. $modulePath

# Initialisieren des Archivierungs-Agents
Write-Host "Initialisiere Archivierungs-Agent..."
Initialize-Archivar

# Archivieren von Daten
Write-Host "`nArchiviere Daten..."
Add-ToArchive -Path "path/to/data" -ArchiveName "MyArchive" -Version "1.0" -Compress $true -Encrypt $true -Password "SecurePassword"

# Auflisten von archivierten Daten
Write-Host "`nListe archivierte Daten auf..."
Get-ArchiveList -ArchiveName "MyArchive" -IncludeVersions $true -IncludeDetails $true

# Wiederherstellen von Daten
Write-Host "`nStelle Daten wieder her..."
Restore-FromArchive -ArchiveName "MyArchive" -Version "1.0" -OutputPath "path/to/output" -Password "SecurePassword"

# Löschen von archivierten Daten
Write-Host "`nLösche archivierte Daten..."
Remove-FromArchive -ArchiveName "MyArchive" -Version "1.0" -Force $false

Write-Host "`nBeispiel abgeschlossen."
