# MINTY Logging Agent - Metrics Collector Component

<#
.SYNOPSIS
    Berechnet Token-Metriken für einen gegebenen Inhalt.
.DESCRIPTION
    Berechnet Token-Metriken für einen gegebenen Inhalt, einschließlich Tokenanzahl, Tokendifferenz und Tokeneffizienz.
.PARAMETER Content
    Der Inhalt, für den die Token-Metriken berechnet werden sollen.
.PARAMETER PreviousContent
    Der vorherige Inhalt, für den die Token-Metriken berechnet werden sollen (optional).
.PARAMETER TokensPerCharacter
    Die durchschnittliche Anzahl von Zeichen pro Token (Standard: 4).
.PARAMETER CostPerToken
    Die Kosten pro Token (Standard: 0.00001).
.EXAMPLE
    $tokenMetrics = Get-TokenMetrics -Content "Some content" -PreviousContent "Previous content"
.OUTPUTS
    Ein Hashtable mit Token-Metriken.
#>
function Get-TokenMetrics {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [string]$PreviousContent = "",

        [Parameter(Mandatory = $false)]
        [double]$TokensPerCharacter = 4.0,

        [Parameter(Mandatory = $false)]
        [double]$CostPerToken = 0.00001
    )

    # Token count estimation
    $tokenCount = [Math]::Ceiling($Content.Length / $TokensPerCharacter)
    $previousTokenCount = [Math]::Ceiling($PreviousContent.Length / $TokensPerCharacter)

    $tokenDiff = $tokenCount - $previousTokenCount
    $tokenEfficiency = if ($previousTokenCount -gt 0) {
        1 - ($tokenDiff / $previousTokenCount)
    } else {
        0
    }

    # Estimate cost
    $cost = $tokenCount * $CostPerToken

    $result = @{
        tokens               = $tokenCount
        token_diff           = $tokenDiff
        token_efficiency     = $tokenEfficiency
        cost                 = $cost
        characters           = $Content.Length
        previous_tokens      = $previousTokenCount
        previous_characters  = $PreviousContent.Length
        tokens_per_character = if ($Content.Length -gt 0) { $tokenCount / $Content.Length } else { 0 }
    }

    Write-Verbose "Token metrics calculated: $tokenCount tokens, efficiency: $([Math]::Round($tokenEfficiency * 100, 2))%"

    return $result
}

<#
.SYNOPSIS
    Schätzt die Qualität eines Outputs.
.DESCRIPTION
    Schätzt die Qualität eines Outputs basierend auf verschiedenen Kriterien.
.PARAMETER Output
    Der Output, dessen Qualität geschätzt werden soll.
.PARAMETER Criteria
    Die Kriterien und ihre Gewichtungen für die Qualitätsschätzung.
.PARAMETER ReferenceOutput
    Ein Referenz-Output für Vergleichszwecke (optional).
.EXAMPLE
    $qualityMetrics = Estimate-OutputQuality -Output "Some output"
.OUTPUTS
    Ein Hashtable mit Qualitätsmetriken.
#>
function Estimate-OutputQuality {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Output,

        [Parameter(Mandatory = $false)]
        [hashtable]$Criteria = @{
            completeness = 0.4
            correctness  = 0.3
            clarity      = 0.2
            conciseness  = 0.1
        },

        [Parameter(Mandatory = $false)]
        [string]$ReferenceOutput = ""
    )

    # Simple length-based completeness estimation
    $completeness = [Math]::Min(1, $Output.Length / 1000)

    # Correctness estimation
    # In a real implementation, this would use more sophisticated methods
    # For now, we use a placeholder value or compare with reference if provided
    $correctness = if ($ReferenceOutput -ne "") {
        # Simple similarity measure
        $similarity = Measure-StringSimilarity -String1 $Output -String2 $ReferenceOutput
        [Math]::Min(1, $similarity)
    } else {
        0.9  # Assume high correctness as placeholder
    }

    # Clarity estimation based on readability metrics
    # Simple implementation using average sentence length and word length
    $clarity = Measure-TextClarity -Text $Output

    # Conciseness estimation
    $conciseness = if ($Output.Length -gt 0) {
        [Math]::Min(1, 2000 / $Output.Length)  # Shorter is more concise
    } else {
        0
    }

    # Calculate weighted quality score
    $qualityScore =
    $Criteria.completeness * $completeness +
    $Criteria.correctness * $correctness +
    $Criteria.clarity * $clarity +
    $Criteria.conciseness * $conciseness

    $result = @{
        quality          = $qualityScore
        components       = @{
            completeness = $completeness
            correctness  = $correctness
            clarity      = $clarity
            conciseness  = $conciseness
        }
        criteria_weights = $Criteria
    }

    Write-Verbose "Output quality estimated: $([Math]::Round($qualityScore * 100, 2))%"

    return $result
}

<#
.SYNOPSIS
    Misst die Ähnlichkeit zwischen zwei Strings.
.DESCRIPTION
    Misst die Ähnlichkeit zwischen zwei Strings mithilfe der Levenshtein-Distanz.
.PARAMETER String1
    Der erste String.
.PARAMETER String2
    Der zweite String.
.EXAMPLE
    $similarity = Measure-StringSimilarity -String1 "Hello" -String2 "Hallo"
.OUTPUTS
    Ein Wert zwischen 0 und 1, der die Ähnlichkeit angibt.
#>
function Measure-StringSimilarity {
    param (
        [Parameter(Mandatory = $true)]
        [string]$String1,

        [Parameter(Mandatory = $true)]
        [string]$String2
    )

    # For very long strings, we'll use a sampling approach
    if ($String1.Length -gt 1000 -or $String2.Length -gt 1000) {
        # Sample the first 500 characters, middle 500 characters, and last 500 characters
        $samples1 = @()

        # First 500 characters
        $samples1 += $String1.Substring(0, [Math]::Min(500, $String1.Length))

        # Middle 500 characters
        if ($String1.Length -gt 1000) {
            $middleStart = [Math]::Max(0, $String1.Length / 2 - 250)
            $middleLength = [Math]::Min(500, $String1.Length - $middleStart)
            $samples1 += $String1.Substring($middleStart, $middleLength)
        } else {
            $samples1 += ""
        }

        # Last 500 characters
        if ($String1.Length -gt 500) {
            $endStart = [Math]::Max(0, $String1.Length - 500)
            $endLength = [Math]::Min(500, $String1.Length - $endStart)
            $samples1 += $String1.Substring($endStart, $endLength)
        } else {
            $samples1 += ""
        }

        # Do the same for String2
        $samples2 = @()

        # First 500 characters
        $samples2 += $String2.Substring(0, [Math]::Min(500, $String2.Length))

        # Middle 500 characters
        if ($String2.Length -gt 1000) {
            $middleStart = [Math]::Max(0, $String2.Length / 2 - 250)
            $middleLength = [Math]::Min(500, $String2.Length - $middleStart)
            $samples2 += $String2.Substring($middleStart, $middleLength)
        } else {
            $samples2 += ""
        }

        # Last 500 characters
        if ($String2.Length -gt 500) {
            $endStart = [Math]::Max(0, $String2.Length - 500)
            $endLength = [Math]::Min(500, $String2.Length - $endStart)
            $samples2 += $String2.Substring($endStart, $endLength)
        } else {
            $samples2 += ""
        }

        # Calculate similarity for each sample
        $similarities = @()
        for ($i = 0; $i -lt $samples1.Count; $i++) {
            if ($samples1[$i] -ne "" -and $samples2[$i] -ne "") {
                $similarities += Measure-LevenshteinSimilarity -String1 $samples1[$i] -String2 $samples2[$i]
            }
        }

        # Return average similarity
        return ($similarities | Measure-Object -Average).Average
    } else {
        # For shorter strings, use the full Levenshtein distance
        return Measure-LevenshteinSimilarity -String1 $String1 -String2 $String2
    }
}

<#
.SYNOPSIS
    Berechnet die Levenshtein-Ähnlichkeit zwischen zwei Strings.
.DESCRIPTION
    Berechnet die Levenshtein-Ähnlichkeit zwischen zwei Strings, normalisiert auf einen Wert zwischen 0 und 1.
.PARAMETER String1
    Der erste String.
.PARAMETER String2
    Der zweite String.
.EXAMPLE
    $similarity = Measure-LevenshteinSimilarity -String1 "Hello" -String2 "Hallo"
.OUTPUTS
    Ein Wert zwischen 0 und 1, der die Ähnlichkeit angibt.
#>
function Measure-LevenshteinSimilarity {
    param (
        [Parameter(Mandatory = $true)]
        [string]$String1,

        [Parameter(Mandatory = $true)]
        [string]$String2
    )

    # Levenshtein distance calculation
    $n = $String1.Length
    $m = $String2.Length

    # If one string is empty, the distance is the length of the other
    if ($n -eq 0) {
        if ($m -eq 0) {
            return 1
        } else {
            return 0
        }
    }
    if ($m -eq 0) { return 0 }

    # Create distance matrix as a hashtable for simplicity
    $d = @{}

    # Initialize first row and column
    for ($i = 0; $i -le $n; $i++) { $d["$i,0"] = $i }
    for ($j = 0; $j -le $m; $j++) { $d["0,$j"] = $j }

    # Calculate distance
    for ($i = 1; $i -le $n; $i++) {
        for ($j = 1; $j -le $m; $j++) {
            $cost = if ($String1[$i - 1] -eq $String2[$j - 1]) { 0 } else { 1 }

            $deletion = $d["$($i-1),$j"] + 1
            $insertion = $d["$i,$($j-1)"] + 1
            $substitution = $d["$($i-1),$($j-1)"] + $cost

            $d["$i,$j"] = [Math]::Min([Math]::Min($deletion, $insertion), $substitution)
        }
    }

    # Calculate similarity (1 - normalized distance)
    $maxLength = [Math]::Max($n, $m)
    $similarity = 1 - ($d["$n,$m"] / $maxLength)

    return $similarity
}

<#
.SYNOPSIS
    Misst die Klarheit eines Textes.
.DESCRIPTION
    Misst die Klarheit eines Textes basierend auf Lesbarkeitsmetriken.
.PARAMETER Text
    Der zu analysierende Text.
.EXAMPLE
    $clarity = Measure-TextClarity -Text "This is a sample text."
.OUTPUTS
    Ein Wert zwischen 0 und 1, der die Klarheit angibt.
#>
function Measure-TextClarity {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    # If text is empty, return 0
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return 0
    }

    # Split text into sentences
    $sentences = $Text -split '(?<=[.!?])\s+'
    $sentenceCount = $sentences.Count

    # Split text into words
    $words = $Text -split '\s+'
    $wordCount = $words.Count

    # Calculate average sentence length
    $avgSentenceLength = if ($sentenceCount -gt 0) { $wordCount / $sentenceCount } else { $wordCount }

    # Calculate average word length
    $totalCharacters = ($words | Measure-Object -Property Length -Sum).Sum
    $avgWordLength = if ($wordCount -gt 0) { $totalCharacters / $wordCount } else { 0 }

    # Calculate clarity score
    # Optimal sentence length is around 15-20 words
    $sentenceLengthScore = if ($avgSentenceLength -gt 0) {
        [Math]::Exp( - [Math]::Pow(($avgSentenceLength - 17.5) / 10, 2))
    } else {
        0
    }

    # Optimal word length is around 4-5 characters
    $wordLengthScore = if ($avgWordLength -gt 0) {
        [Math]::Exp( - [Math]::Pow(($avgWordLength - 4.5) / 3, 2))
    } else {
        0
    }

    # Combine scores (equal weighting)
    $clarityScore = ($sentenceLengthScore + $wordLengthScore) / 2

    return $clarityScore
}

<#
.SYNOPSIS
    Berechnet Metriken für einen Code-Output.
.DESCRIPTION
    Berechnet spezifische Metriken für einen Code-Output, wie Komplexität und Struktur.
.PARAMETER Code
    Der zu analysierende Code.
.PARAMETER Language
    Die Programmiersprache des Codes.
.EXAMPLE
    $codeMetrics = Get-CodeMetrics -Code "function example() { return true; }" -Language "JavaScript"
.OUTPUTS
    Ein Hashtable mit Code-Metriken.
#>
function Get-CodeMetrics {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Code,

        [Parameter(Mandatory = $false)]
        [ValidateSet("PowerShell", "JavaScript", "Python", "C#", "Java", "Other")]
        [string]$Language = "Other"
    )

    # If code is empty, return empty metrics
    if ([string]::IsNullOrWhiteSpace($Code)) {
        return @{
            complexity    = 0
            lines         = 0
            functions     = 0
            classes       = 0
            comments      = 0
            comment_ratio = 0
        }
    }

    # Split code into lines
    $lines = $Code -split '\r?\n'
    $lineCount = $lines.Count

    # Count non-empty lines
    $nonEmptyLines = ($lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count

    # Count comment lines (language-specific)
    $commentPattern = switch ($Language) {
        "PowerShell" { '^\s*#' }
        "JavaScript" { '^\s*(//|/\*|\*/)' }
        "Python" { '^\s*#' }
        "C#" { '^\s*(//|/\*|\*/)' }
        "Java" { '^\s*(//|/\*|\*/)' }
        default { '^\s*(#|//|/\*|\*/)' }
    }

    $commentLines = ($lines | Where-Object { $_ -match $commentPattern }).Count
    $commentRatio = if ($nonEmptyLines -gt 0) { $commentLines / $nonEmptyLines } else { 0 }

    # Count functions (language-specific)
    $functionPattern = switch ($Language) {
        "PowerShell" { 'function\s+\w+' }
        "JavaScript" { '(function\s+\w+|const\s+\w+\s*=\s*\(.*\)\s*=>|let\s+\w+\s*=\s*\(.*\)\s*=>|var\s+\w+\s*=\s*\(.*\)\s*=>)' }
        "Python" { 'def\s+\w+' }
        "C#" { '(public|private|protected|internal|static)?\s*(void|string|int|bool|var|object|Task).*\s+\w+\s*\(.*\)' }
        "Java" { '(public|private|protected|static)?\s*(void|String|int|boolean|Object).*\s+\w+\s*\(.*\)' }
        default { '(function|def|\w+\s*\(.*\)\s*{)' }
    }

    $functionCount = 0
    foreach ($line in $lines) {
        if ($line -match $functionPattern) {
            $functionCount++
        }
    }

    # Count classes (language-specific)
    $classPattern = switch ($Language) {
        "PowerShell" { 'class\s+\w+' }
        "JavaScript" { 'class\s+\w+' }
        "Python" { 'class\s+\w+' }
        "C#" { '(public|private|protected|internal|static)?\s*class\s+\w+' }
        "Java" { '(public|private|protected|static)?\s*class\s+\w+' }
        default { 'class\s+\w+' }
    }

    $classCount = 0
    foreach ($line in $lines) {
        if ($line -match $classPattern) {
            $classCount++
        }
    }

    # Estimate complexity (very simple approximation)
    # Count control structures
    $controlPattern = switch ($Language) {
        "PowerShell" { '(if|for|foreach|while|switch|try|catch)' }
        "JavaScript" { '(if|for|while|switch|try|catch)' }
        "Python" { '(if|for|while|try|except)' }
        "C#" { '(if|for|foreach|while|switch|try|catch)' }
        "Java" { '(if|for|while|switch|try|catch)' }
        default { '(if|for|while|switch|try|catch)' }
    }

    $controlCount = 0
    foreach ($line in $lines) {
        if ($line -match $controlPattern) {
            $controlCount++
        }
    }

    # Calculate complexity score
    $complexity = $functionCount * 1.5 + $classCount * 2 + $controlCount

    # Normalize complexity to 0-1 range
    $normalizedComplexity = if ($complexity -gt 0) {
        [Math]::Min(1, $complexity / 100)
    } else {
        0
    }

    return @{
        complexity         = $normalizedComplexity
        raw_complexity     = $complexity
        lines              = $lineCount
        non_empty_lines    = $nonEmptyLines
        functions          = $functionCount
        classes            = $classCount
        comments           = $commentLines
        comment_ratio      = $commentRatio
        control_structures = $controlCount
    }
}
