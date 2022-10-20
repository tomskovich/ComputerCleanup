<#
    .SYNOPSIS
    Removes common temporary files and folders older than $Days days old from user profiles.
    Folders:
        - USER\AppData\Local\Microsoft\Windows\WER'
        - USER\AppData\Local\Microsoft\Windows\INetCache'
        - USER\AppData\Local\Microsoft\Internet Explorer\Recovery'
        - USER\AppData\Local\Microsoft\Terminal Server Client\Cache'
        - USER\AppData\Local\CrashDumps'
        - USER\AppData\Local\Temp
    OPTIONAL: Remove specific filetypes from users' downloads folder.

    .NOTES
    Author:   Tom de Leeuw
    Website:  https://ucsystems.nl / https://tech-tom.com
#>
function Optimize-UserProfiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [int] $Days,

        [switch] $TempFiles,

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [switch] $Downloads,

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [switch] $ArchiveFiles,

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [array] $ArchiveTypes = @('zip', 'rar', '7z', 'iso'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [string] $ArchiveSize = '500MB',

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [switch] $GenericFiles,

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [array] $GenericTypes = @('msi', 'exe'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Downloads')]
        [string] $GenericSize = '15MB'
    )

    begin {
        # Get disk space for comparison afterwards
        $Before = Get-DiskSpace

        # Get all user folders, exclude administrators and default users
        $Users = Get-UserFolders

        # Parameters for Get-ChildItem and Remove-Item
        $CommonParams = @{
            Recurse       = $true
            Force         = $true
            Verbose       = $true
            ErrorAction   = 'SilentlyContinue'
            WarningAction = 'SilentlyContinue'
        }
    }

    process {
        ForEach ($Username In $Users) {
            # General temp files/folders
            if ($TempFiles -eq $true) {
                # Folders to clean up
                $TempFolders = @(
                    '\AppData\Local\Microsoft\Windows\WER',
                    '\AppData\Local\Microsoft\Windows\INetCache',
                    '\AppData\Local\Microsoft\Internet Explorer\Recovery',
                    '\AppData\Local\Microsoft\Terminal Server Client\Cache',
                    '\AppData\Local\CrashDumps',
                    '\AppData\Local\Temp'
                )
                ForEach ($Folder In $TempFolders) {
                    If (Test-Path -Path "$env:SYSTEMDRIVE\Users\$Username\$Folder") {
                        try {
                            Get-ChildItem -Path "$env:SYSTEMDRIVE\Users\$Username\$Folder" @CommonParams |
                                Where-Object { ($_.CreationTime -and $_.LastAccessTime -lt $(Get-Date).AddDays(-$Days)) } |
                                    Remove-Item @CommonParams
                        }
                        catch {
                            Write-Error $_
                        }
                    }
                }
            }

            # Downloads folder
            if ($Downloads -eq $true) {
                If (Test-Path -Path "$env:SYSTEMDRIVE\Users\$Username\Downloads") {
                    # Compressed files larger than $ArchiveSize
                    if ($ArchiveFiles -eq $true) {
                        ForEach ($Ext In $ArchiveTypes) {
                            try {
                                Get-ChildItem -Path "$env:SYSTEMDRIVE\Users\$Username\Downloads\*.$Ext" @CommonParams |
                                    Where-Object { ($_.CreationTime -and $_.LastAccessTime -lt $(Get-Date).AddDays(-$Days) -and $_.Length -gt $ArchiveSize) } |
                                        Remove-Item @CommonParams
                            }
                            catch {
                                Write-Error $_
                            }
                        }
                    }
                    # Generic files larger than $GenericSize
                    if ($GenericFiles -eq $true) {
                        ForEach ($Ext In $GenericTypes) {
                            try {
                                Get-ChildItem -Path "$env:SYSTEMDRIVE\Users\$Username\Downloads\*.$($Ext)" @CommonParams |
                                    Where-Object { ($_.CreationTime -and $_.LastAccessTime -lt $(Get-Date).AddDays(-$Days) -and $_.Length -gt $GenericSize) } |
                                        Remove-Item @CommonParams
                            }
                            catch {
                                Write-Error $_
                            }
                        }
                    }
                }
            }
        }
    }

    end {
        # Get disk space again and calculate difference
        $After        = Get-DiskSpace
        $TotalCleaned = "$(($After.FreeSpace - $Before.FreeSpace).ToString('00.00')) GB"

        # Report
        if ($null -ne $script:CleanupReport) {
            $script:CleanupReport.UserProfiles = $TotalCleaned
        }
        else {
            Write-Output "Total space cleaned: $TotalCleaned"
        }
    }
}
