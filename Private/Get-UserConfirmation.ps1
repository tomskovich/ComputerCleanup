<#
    .SYNOPSIS
    Asks the user for confirmation before continuing. 

    .NOTES
    Author:   Tom de Leeuw
    Website:  https://ucsystems.nl / https://tech-tom.com
#>
function Get-UserConfirmation {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string] $WarningMessage,

        [ValidateNotNullOrEmpty()]
        [Alias('ConfirmationMessage')]
        [string] $PromptMessage = "Are you sure you want to continue? [Y/N]",

        [ValidateNotNullOrEmpty()]
        [string] $ExitMessage = "Script aborted by user input."
    )
    
    process {
        Write-Warning $WarningMessage
        $Confirmation = Read-Host -Prompt $PromptMessage
        while (($Confirmation) -notmatch "[yY]") {
            switch -regex ($Confirmation) {
                "[yY]" {
                    continue
                }
                "[nN]" {
                    throw $ExitMessage
                }
                default {
                    throw $ExitMessage
                }
            }
        }
    }
}