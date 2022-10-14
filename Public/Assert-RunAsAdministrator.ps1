<#
    .SYNOPSIS
    Verifies if current user/context has Administrator privileges.

    .NOTES
    Author:   Tom de Leeuw
    Website:  https://ucsystems.nl / https://tech-tom.com
#>
function Assert-RunAsAdministrator {
    # Get current user context
    $CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())

    # Check user is running the script is member of Administrator Group
    if ($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        Write-Host 'Script is running with Administrator privileges!' -ForegroundColor Green
    }
    else {
        throw "Script/function is NOT running with Administrator priviliges. Please re-run as Administrator."
    }
}