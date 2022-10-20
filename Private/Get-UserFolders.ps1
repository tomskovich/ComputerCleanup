<#
    .SYNOPSIS
    Gets all user folders, excluding Administrators and Default/Public users

    .NOTES
    Author:   Tom de Leeuw
    Website:  https://ucsystems.nl / https://tech-tom.com
#>
function Get-UserFolders {
    $Users = Get-ChildItem -Directory -Path "$env:SYSTEMDRIVE\Users" | Where-Object { 
        $_.Name -NotLike '*administrator*' -and 
        $_.Name -NotLike '*admin*' -and 
        $_.Name -NotLike 'Public' -and 
        $_.Name -NotLike 'Default'
    } | Select-Object -ExpandProperty Name

    return $Users
}