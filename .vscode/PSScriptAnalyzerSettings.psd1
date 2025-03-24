@{
    # Verwende die folgenden Regeln bei der Analyse von PowerShell-Skripten
    IncludeRules   = @(
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingWriteHost',
        'PSUseApprovedVerbs',
        'PSAvoidUsingInvokeExpression',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUsePSCredentialType',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSAvoidGlobalVars',
        'PSUseSingularNouns',
        'PSAvoidUsingPositionalParameters',
        'PSUseProcessBlockForPipelineCommand',
        'PSUseConsistentIndentation',
        'PSUseConsistentWhitespace',
        'PSAlignAssignmentStatement',
        'PSUseCorrectCasing'
    )

    # Regeln, die ausgeschlossen werden sollen
    ExcludeRules   = @(
        'PSAvoidUsingWriteHost'  # Erlaubt für Benutzerinteraktion in diesem Projekt
    )

    # Regeln, die nur als Warnung angezeigt werden sollen
    WarningAsError = @(
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingConvertToSecureStringWithPlainText'
    )

    # Regeln-spezifische Einstellungen
    Rules          = @{
        PSUseConsistentIndentation = @{
            Enable          = $true
            Kind            = 'space'
            IndentationSize = 4
        }
        PSUseConsistentWhitespace  = @{
            Enable         = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator  = $true
            CheckSeparator = $true
        }
        PSAlignAssignmentStatement = @{
            Enable         = $true
            CheckHashtable = $true
        }
        PSUseCorrectCasing         = @{
            Enable = $true
        }
    }
}
