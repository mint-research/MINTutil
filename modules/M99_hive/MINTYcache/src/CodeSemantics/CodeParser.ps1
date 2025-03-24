# MINTYcache - Code Parser
# Parses and caches code semantics information

<#
.SYNOPSIS
    Parses and caches code semantics information.
.DESCRIPTION
    Provides functionality to parse code files, extract semantic information,
    and cache it for efficient access.
.NOTES
    Version: 1.0.0
    Author: MINTYhive
#>

class CodeParser {
    [hashtable] $Config
    [hashtable] $LanguageParsers = @{}

    CodeParser([hashtable]$config) {
        $this.Config = $config
        $this.InitializeParsers()
    }

    [void] InitializeParsers() {
        # Initialize language-specific parsers
        foreach ($language in $this.Config.languages) {
            switch ($language) {
                "ps1" { $this.LanguageParsers[$language] = [PowerShellParser]::new() }
                "cs" { $this.LanguageParsers[$language] = [CSharpParser]::new() }
                "js" { $this.LanguageParsers[$language] = [JavaScriptParser]::new() }
                "py" { $this.LanguageParsers[$language] = [PythonParser]::new() }
                "java" { $this.LanguageParsers[$language] = [JavaParser]::new() }
                default { $this.LanguageParsers[$language] = [GenericParser]::new() }
            }
        }
    }

    [hashtable] ParseFile([string]$filePath) {
        if (-not (Test-Path $filePath)) {
            throw "File does not exist: $filePath"
        }

        $extension = [System.IO.Path]::GetExtension($filePath).TrimStart('.')

        if (-not $this.LanguageParsers.ContainsKey($extension)) {
            # Use generic parser for unknown extensions
            return [GenericParser]::new().Parse($filePath)
        }

        return $this.LanguageParsers[$extension].Parse($filePath)
    }
}

# Base parser class
class BaseParser {
    [hashtable] Parse([string]$filePath) {
        throw "Parse method must be implemented by derived classes"
    }

    [hashtable] CreateBaseStructure([string]$filePath) {
        return @{
            filePath  = $filePath
            fileName  = [System.IO.Path]::GetFileName($filePath)
            extension = [System.IO.Path]::GetExtension($filePath).TrimStart('.')
            timestamp = Get-Date
            symbols   = @()
            imports   = @()
            classes   = @()
            functions = @()
            variables = @()
            metadata  = @{
                lineCount  = 0
                complexity = 0
            }
        }
    }
}

# Generic parser for unknown languages
class GenericParser : BaseParser {
    [hashtable] Parse([string]$filePath) {
        $structure = $this.CreateBaseStructure($filePath)

        try {
            $content = Get-Content -Path $filePath -Raw
            $lines = $content -split "`n"
            $structure.metadata.lineCount = $lines.Count

            # Basic symbol extraction using regex
            $structure.symbols = $this.ExtractSymbols($content)
        } catch {
            $errorMessage = $_.Exception.Message
            Write-Warning "Error parsing file $filePath`: $errorMessage"
        }

        return $structure
    }

    [array] ExtractSymbols([string]$content) {
        $symbols = @()

        # Simple regex to find potential symbols
        $symbolMatches = [regex]::Matches($content, '(?<!\w)([a-zA-Z_]\w*)\s*(\=|\(|\{)')

        foreach ($match in $symbolMatches) {
            $symbols += @{
                name     = $match.Groups[1].Value
                type     = "unknown"
                location = $match.Index
            }
        }

        return $symbols
    }
}

# PowerShell parser
class PowerShellParser : BaseParser {
    [hashtable] Parse([string]$filePath) {
        $structure = $this.CreateBaseStructure($filePath)

        try {
            $content = Get-Content -Path $filePath -Raw
            $lines = $content -split "`n"
            $structure.metadata.lineCount = $lines.Count

            # Extract functions
            $functionMatches = [regex]::Matches($content, 'function\s+([a-zA-Z_]\w*)')
            foreach ($match in $functionMatches) {
                $structure.functions += @{
                    name     = $match.Groups[1].Value
                    type     = "function"
                    location = $match.Index
                }
                $structure.symbols += @{
                    name     = $match.Groups[1].Value
                    type     = "function"
                    location = $match.Index
                }
            }

            # Extract classes
            $classMatches = [regex]::Matches($content, 'class\s+([a-zA-Z_]\w*)')
            foreach ($match in $classMatches) {
                $structure.classes += @{
                    name     = $match.Groups[1].Value
                    type     = "class"
                    location = $match.Index
                }
                $structure.symbols += @{
                    name     = $match.Groups[1].Value
                    type     = "class"
                    location = $match.Index
                }
            }

            # Extract variables
            $variableMatches = [regex]::Matches($content, '\$([a-zA-Z_]\w*)\s*\=')
            foreach ($match in $variableMatches) {
                $structure.variables += @{
                    name     = $match.Groups[1].Value
                    type     = "variable"
                    location = $match.Index
                }
                $structure.symbols += @{
                    name     = $match.Groups[1].Value
                    type     = "variable"
                    location = $match.Index
                }
            }

            # Extract imports
            $importMatches = [regex]::Matches($content, '(?:Import-Module|using module)\s+([^\s;]+)')
            foreach ($match in $importMatches) {
                $structure.imports += @{
                    name     = $match.Groups[1].Value
                    type     = "import"
                    location = $match.Index
                }
            }

            # Calculate complexity (simple metric based on control structures)
            $complexityMatches = [regex]::Matches($content, '(?:if|for|foreach|while|switch|try|catch)')
            $structure.metadata.complexity = $complexityMatches.Count
        } catch {
            $errorMessage = $_.Exception.Message
            Write-Warning "Error parsing PowerShell file $filePath`: $errorMessage"
        }

        return $structure
    }
}

# Placeholder for other language parsers
class CSharpParser : BaseParser {
    [hashtable] Parse([string]$filePath) {
        $structure = $this.CreateBaseStructure($filePath)
        # Implementation for C# parsing would go here
        return $structure
    }
}

class JavaScriptParser : BaseParser {
    [hashtable] Parse([string]$filePath) {
        $structure = $this.CreateBaseStructure($filePath)
        # Implementation for JavaScript parsing would go here
        return $structure
    }
}

class PythonParser : BaseParser {
    [hashtable] Parse([string]$filePath) {
        $structure = $this.CreateBaseStructure($filePath)
        # Implementation for Python parsing would go here
        return $structure
    }
}

class JavaParser : BaseParser {
    [hashtable] Parse([string]$filePath) {
        $structure = $this.CreateBaseStructure($filePath)
        # Implementation for Java parsing would go here
        return $structure
    }
}

class CodeSemanticsCache {
    [hashtable] $Config
    [hashtable] $Cache = @{}
    [object] $Parser

    CodeSemanticsCache([hashtable]$config) {
        $this.Config = $config
        $this.Parser = [CodeParser]::new($config)
    }

    [hashtable] GetSemantics([string]$path, [bool]$refresh = $false) {
        $normalizedPath = $this.NormalizePath($path)

        if ($refresh -or -not $this.Cache.ContainsKey($normalizedPath) -or $this.IsCacheExpired($normalizedPath)) {
            $this.Refresh($normalizedPath)
        }

        return $this.Cache[$normalizedPath]
    }

    [void] Refresh([string]$path) {
        $normalizedPath = $this.NormalizePath($path)

        if (Test-Path $normalizedPath -PathType Container) {
            # Directory - parse all supported files
            $this.RefreshDirectory($normalizedPath)
        } else {
            # Single file
            $this.RefreshFile($normalizedPath)
        }
    }

    [void] RefreshDirectory([string]$directoryPath) {
        $semantics = @{
            path      = $directoryPath
            timestamp = Get-Date
            files     = @{}
            symbols   = @{}
            imports   = @{}
            metadata  = @{
                totalFiles    = 0
                totalSymbols  = 0
                totalImports  = 0
                languageStats = @{}
            }
        }

        $supportedExtensions = $this.Config.languages

        # Find all supported files
        $files = Get-ChildItem -Path $directoryPath -Recurse -File |
        Where-Object { $supportedExtensions -contains $_.Extension.TrimStart('.') }

        foreach ($file in $files) {
            try {
                $fileSemantics = $this.Parser.ParseFile($file.FullName)
                $relativePath = $file.FullName.Substring($directoryPath.Length).TrimStart('\', '/')

                $semantics.files[$relativePath] = $fileSemantics

                # Update symbol index
                foreach ($symbol in $fileSemantics.symbols) {
                    if (-not $semantics.symbols.ContainsKey($symbol.name)) {
                        $semantics.symbols[$symbol.name] = @()
                    }

                    $semantics.symbols[$symbol.name] += @{
                        file     = $relativePath
                        type     = $symbol.type
                        location = $symbol.location
                    }
                }

                # Update import index
                foreach ($import in $fileSemantics.imports) {
                    if (-not $semantics.imports.ContainsKey($import.name)) {
                        $semantics.imports[$import.name] = @()
                    }

                    $semantics.imports[$import.name] += @{
                        file     = $relativePath
                        location = $import.location
                    }
                }

                # Update metadata
                $semantics.metadata.totalFiles++
                $semantics.metadata.totalSymbols += $fileSemantics.symbols.Count
                $semantics.metadata.totalImports += $fileSemantics.imports.Count

                $extension = $file.Extension.TrimStart('.')
                if (-not $semantics.metadata.languageStats.ContainsKey($extension)) {
                    $semantics.metadata.languageStats[$extension] = 0
                }
                $semantics.metadata.languageStats[$extension]++
            } catch {
                $errorMessage = $_.Exception.Message
                Write-Warning "Error processing file $($file.FullName)`: $errorMessage"
            }
        }

        $semantics.cacheTimestamp = Get-Date
        $this.Cache[$directoryPath] = $semantics

        # Save to disk for persistence
        $this.SaveToFile($directoryPath, $semantics)
    }

    [void] RefreshFile([string]$filePath) {
        try {
            $fileSemantics = $this.Parser.ParseFile($filePath)
            $fileSemantics.cacheTimestamp = Get-Date
            $this.Cache[$filePath] = $fileSemantics

            # Save to disk for persistence
            $this.SaveToFile($filePath, $fileSemantics)
        } catch {
            $errorMessage = $_.Exception.Message
            Write-Warning "Error refreshing semantics for file $filePath`: $errorMessage"
        }
    }

    [bool] IsCacheExpired([string]$path) {
        if (-not $this.Cache.ContainsKey($path)) {
            return $true
        }

        $cacheAge = (Get-Date) - $this.Cache[$path].cacheTimestamp
        return $cacheAge.TotalSeconds -gt $this.Config.cacheExpiration
    }

    [string] NormalizePath([string]$path) {
        return $path.TrimEnd('\', '/').Replace('/', '\')
    }

    [void] SaveToFile([string]$path, [hashtable]$semantics) {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $cacheDir = Join-Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) "data\code_semantics"

        if (-not (Test-Path $cacheDir)) {
            New-Item -Path $cacheDir -ItemType Directory -Force | Out-Null
        }

        $pathHash = [System.BitConverter]::ToString(
            [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                [System.Text.Encoding]::UTF8.GetBytes($path)
            )
        ).Replace("-", "")

        $cacheFile = Join-Path $cacheDir "$pathHash.json"

        $semantics | ConvertTo-Json -Depth 10 | Set-Content -Path $cacheFile
    }

    [hashtable] LoadFromFile([string]$path) {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $cacheDir = Join-Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) "data\code_semantics"

        $pathHash = [System.BitConverter]::ToString(
            [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                [System.Text.Encoding]::UTF8.GetBytes($path)
            )
        ).Replace("-", "")

        $cacheFile = Join-Path $cacheDir "$pathHash.json"

        if (Test-Path $cacheFile) {
            return Get-Content -Path $cacheFile -Raw | ConvertFrom-Json -AsHashtable
        }

        return $null
    }

    [array] FindSymbols([string]$projectPath, [string]$symbolName, [string]$symbolType = $null) {
        $semantics = $this.GetSemantics($projectPath)
        $results = @()

        if (-not $semantics.symbols.ContainsKey($symbolName)) {
            return $results
        }

        foreach ($symbol in $semantics.symbols[$symbolName]) {
            if ($symbolType -and $symbol.type -ne $symbolType) {
                continue
            }

            $results += $symbol
        }

        return $results
    }

    [hashtable] GetSummary([string]$projectPath) {
        $semantics = $this.GetSemantics($projectPath)

        return @{
            path         = $semantics.path
            timestamp    = $semantics.timestamp
            totalFiles   = $semantics.metadata.totalFiles
            totalSymbols = $semantics.metadata.totalSymbols
            totalImports = $semantics.metadata.totalImports
            languages    = $semantics.metadata.languageStats
        }
    }

    [void] Clear() {
        $this.Cache.Clear()
    }

    [hashtable] GetStats() {
        return @{
            cacheCount   = $this.Cache.Count
            totalFiles   = ($this.Cache.Values | ForEach-Object { $_.metadata.totalFiles } | Measure-Object -Sum).Sum
            totalSymbols = ($this.Cache.Values | ForEach-Object { $_.metadata.totalSymbols } | Measure-Object -Sum).Sum
            totalImports = ($this.Cache.Values | ForEach-Object { $_.metadata.totalImports } | Measure-Object -Sum).Sum
        }
    }
}

# Export the classes
Export-ModuleMember -Variable CodeParser, BaseParser, GenericParser, PowerShellParser, CSharpParser, JavaScriptParser, PythonParser, JavaParser, CodeSemanticsCache
