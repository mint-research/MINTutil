# Static Code Review für MINTutil

Dieses Dokument definiert die Kriterien und den Prozess für ein Static Code Review des MINTutil-Projekts. Es dient als Grundlage für das automatisierte Review-Script.

## 1. Überblick

Das Static Code Review-System für MINTutil ist ein iteratives und rekursives System, das den Code auf verschiedenen Ebenen analysiert und konkrete Verbesserungsvorschläge liefert, einschließlich automatischer Korrekturen für häufige Probleme.

## 2. Ziele des Static Code Reviews

- Identifizierung von Codequalitätsproblemen
- Sicherstellung der Einhaltung von Best Practices
- Verbesserung der Sicherheit des Codes
- Optimierung der Performance
- Förderung der Modularität und Wiederverwendbarkeit
- Bereitstellung konkreter Verbesserungsvorschläge und automatischer Korrekturen

## 3. Review-Ebenen

### 3.1 Architektur-Review

**Kriterien:**
- Einhaltung der definierten Verzeichnisstruktur
- Klare Trennung von Modulen und deren Verantwortlichkeiten
- Analyse der Abhängigkeiten zwischen Modulen

**Automatische Korrekturen:**
- Vorschläge zur Reorganisation von Dateien in die korrekte Verzeichnisstruktur
- Identifizierung und Auflösung von zirkulären Abhängigkeiten

### 3.2 Modul-Review

**Kriterien:**
- Konsistente und gut definierte Schnittstellen
- Eigenständigkeit der Module
- Wiederverwendbarkeit von Modulen

**Automatische Korrekturen:**
- Standardisierung von Modulschnittstellen
- Extraktion gemeinsamer Funktionalitäten in wiederverwendbare Module

### 3.3 Funktions-Review

**Kriterien:**
- Klare Verantwortlichkeiten (Single Responsibility Principle)
- Konsistente und robuste Fehlerbehandlung
- Ausreichende und klare Dokumentation

**Automatische Korrekturen:**
- Hinzufügen von fehlenden Try-Catch-Blöcken
- Ergänzung von fehlender Dokumentation (Kommentarblöcke)
- Aufteilung von zu komplexen Funktionen

### 3.4 Code-Review

**Kriterien:**
- Namenskonventionen und Lesbarkeit
- Sicherheitsaspekte (Eingabevalidierung, sichere Funktionsaufrufe)
- Performance-Optimierungen
- Einhaltung von PowerShell-Best-Practices

**Automatische Korrekturen:**
- Umbenennung von Variablen und Funktionen gemäß Konventionen
- Hinzufügen von Eingabevalidierung
- Optimierung von ineffizientem Code
- Korrektur von häufigen Anti-Patterns

## 4. Prozess für das Static Code Review

### 4.1 Vorbereitung

1. Festlegung der zu überprüfenden Codeabschnitte
2. Auswahl der relevanten Kriterien
3. Einrichtung der Umgebung für das Review

### 4.2 Durchführung

1. Automatisierte Analyse mit dem entwickelten Script
2. Manuelle Überprüfung kritischer Bereiche
3. Dokumentation der Ergebnisse

### 4.3 Auswertung

1. Bewertung der Ergebnisse nach Schweregrad
2. Priorisierung der Probleme
3. Erstellung eines Berichts mit konkreten Verbesserungsvorschlägen und automatischen Korrekturen

### 4.4 Verbesserung

1. Umsetzung der Empfehlungen
2. Erneute Überprüfung nach Änderungen
3. Kontinuierliche Verbesserung des Codes

## 5. Häufige Probleme und automatische Korrekturen

### 5.1 Namenskonventionen

**Problem:** Inkonsistente Benennung von Variablen und Funktionen

**Automatische Korrektur:**
- Variablen: PascalCase für globale Variablen, camelCase für lokale Variablen
- Funktionen: Verb-Substantiv-Format (z.B. Get-Item, Set-Value)

### 5.2 Fehlerbehandlung

**Problem:** Fehlende oder inkonsistente Fehlerbehandlung

**Automatische Korrektur:**
```powershell
# Vor der Korrektur
function Do-Something {
    # Code ohne Fehlerbehandlung
}

# Nach der Korrektur
function Do-Something {
    try {
        # Code mit Fehlerbehandlung
    } catch {
        Write-Error "Fehler bei Do-Something: $_"
        return $false
    }
}
```

### 5.3 Dokumentation

**Problem:** Fehlende oder unzureichende Dokumentation

**Automatische Korrektur:**
```powershell
# Vor der Korrektur
function Get-SystemInfo {
    # Code ohne Dokumentation
}

# Nach der Korrektur
<#
.SYNOPSIS
    Sammelt Systeminformationen.
.DESCRIPTION
    Diese Funktion sammelt verschiedene Systeminformationen wie CPU, RAM und Festplattennutzung.
.PARAMETER ComputerName
    Der Name des Computers, von dem Informationen gesammelt werden sollen.
.EXAMPLE
    Get-SystemInfo -ComputerName "Server01"
#>
function Get-SystemInfo {
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )
    # Code mit Dokumentation
}
```

### 5.4 Sicherheit

**Problem:** Fehlende Eingabevalidierung

**Automatische Korrektur:**
```powershell
# Vor der Korrektur
function Set-UserPermission {
    param($User, $Permission)
    # Code ohne Validierung
}

# Nach der Korrektur
function Set-UserPermission {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$User,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Read", "Write", "Execute")]
        [string]$Permission
    )
    # Code mit Validierung
}
```

### 5.5 Performance

**Problem:** Ineffiziente Schleifen oder Datenstrukturen

**Automatische Korrektur:**
```powershell
# Vor der Korrektur
$result = @()
foreach ($item in $items) {
    $result += $item # Ineffizient, da Array jedes Mal neu erstellt wird
}

# Nach der Korrektur
$result = [System.Collections.ArrayList]::new()
foreach ($item in $items) {
    $null = $result.Add($item) # Effizienter mit ArrayList
}
```

## 6. Implementierung des Review-Scripts

Das Review-Script wird in PowerShell implementiert und folgt diesem Ablauf:

1. Rekursives Durchsuchen der Projektstruktur
2. Analyse verschiedener Dateitypen (PS1, JSON, XAML)
3. Anwendung der definierten Kriterien auf jeder Ebene
4. Generierung eines detaillierten Berichts mit Problemen, Schweregrad und automatischen Korrekturvorschlägen
5. Option zur automatischen Anwendung von Korrekturen

## 7. Berichtsformat

Der Bericht wird in einem strukturierten Format erstellt:

```
# Static Code Review Bericht für MINTutil

## Zusammenfassung
- Geprüfte Dateien: 25
- Gefundene Probleme: 42
- Kritisch: 5
- Wichtig: 15
- Mittel: 12
- Niedrig: 10
- Automatisch korrigierbar: 30

## Detaillierte Ergebnisse

### Kritische Probleme

1. [KRITISCH] Unsichere Befehlsausführung in modules/M01_install/install.ps1:145
   - Problem: Verwendung von Invoke-Expression mit nicht validierter Benutzereingabe
   - Empfehlung: Verwenden Sie validierte Parameter statt Invoke-Expression
   - Automatische Korrektur verfügbar: Ja
   
   ```powershell
   # Aktueller Code
   Invoke-Expression $userInput
   
   # Korrigierter Code
   $allowedCommands = @("Get-Process", "Get-Service")
   if ($allowedCommands -contains $userInput) {
       & $userInput
   } else {
       Write-Error "Unerlaubter Befehl: $userInput"
   }
   ```

### Wichtige Probleme
...
```

## 8. Kontinuierliche Integration

Das Static Code Review kann in einen CI/CD-Prozess integriert werden, um automatisch bei jedem Commit oder Pull Request ausgeführt zu werden.